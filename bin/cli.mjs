#!/usr/bin/env node

import { cpSync, rmSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

const PROJECT_DIR = process.cwd();
const SKILLS_DIR = join(PROJECT_DIR, '.agents', 'skills');
const WORKFLOWS_SRC = join(ROOT, 'global-config', 'workflow');
const WORKFLOWS_DIR = join(PROJECT_DIR, '.agents', 'workflows');
const MANIFEST_PATH = join(SKILLS_DIR, '.ag-manifest.json');

// ─── Skill Groups ──────────────────────────────────────────

const SKILL_GROUPS = [
  {
    name: 'unity-skills',
    src: join(ROOT, 'global-config', 'skills', 'unity-skills'),
    label: 'Unity',
  },
  {
    name: 'qa-skills',
    src: join(ROOT, 'global-config', 'skills', 'qa-skills'),
    label: 'QA',
  },
];

// ─── Helpers ───────────────────────────────────────────────

function log(icon, msg) {
  console.log(`   ${icon} ${msg}`);
}

function readManifest() {
  try {
    if (existsSync(MANIFEST_PATH)) {
      return JSON.parse(readFileSync(MANIFEST_PATH, 'utf-8'));
    }
  } catch {
    // corrupted manifest — treat as empty
  }
  return { version: null, groups: {} };
}

function writeManifest(groups, workflows) {
  const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf-8'));
  const manifest = {
    version: pkg.version,
    installed_at: new Date().toISOString(),
    groups,
    workflows: workflows || [],
  };
  writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n');
}

function getSkillNames(srcDir) {
  const names = [];
  try {
    const entries = readdirSync(srcDir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory() && existsSync(join(srcDir, entry.name, 'SKILL.md'))) {
        names.push(entry.name);
      }
    }
  } catch {
    // ignore
  }
  return names;
}

function cleanupOldSkills(groupName, newSkillNames) {
  const manifest = readManifest();
  const oldSkills = manifest.groups[groupName] || [];

  // Remove skills that were previously installed but are no longer in the source
  for (const skillName of oldSkills) {
    const skillDir = join(SKILLS_DIR, skillName);
    if (existsSync(skillDir) && !newSkillNames.includes(skillName)) {
      rmSync(skillDir, { recursive: true, force: true });
    }
  }

  // Also remove skills that will be re-installed (clean replace)
  for (const skillName of newSkillNames) {
    const skillDir = join(SKILLS_DIR, skillName);
    if (existsSync(skillDir)) {
      rmSync(skillDir, { recursive: true, force: true });
    }
  }
}

function installSkillGroup(group) {
  const skillNames = getSkillNames(group.src);

  // Clean up old skills from this group before installing
  cleanupOldSkills(group.name, skillNames);

  // Copy each skill directly into .agents/skills/<skill-name>/
  let installed = 0;
  for (const skillName of skillNames) {
    const src = join(group.src, skillName);
    const dst = join(SKILLS_DIR, skillName);
    cpSync(src, dst, { recursive: true, force: true });
    installed++;
  }

  return { installed, skillNames };
}

function countSkillsFlat() {
  let count = 0;
  try {
    const entries = readdirSync(SKILLS_DIR, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory() && existsSync(join(SKILLS_DIR, entry.name, 'SKILL.md'))) {
        count++;
      }
    }
  } catch {
    // ignore
  }
  return count;
}

// ─── Workflow Helpers ──────────────────────────────────────

function installWorkflows() {
  if (!existsSync(WORKFLOWS_SRC)) {
    return [];
  }

  mkdirSync(WORKFLOWS_DIR, { recursive: true });

  const files = readdirSync(WORKFLOWS_SRC).filter(f => f.endsWith('.md'));
  for (const file of files) {
    cpSync(join(WORKFLOWS_SRC, file), join(WORKFLOWS_DIR, file), { force: true });
  }

  if (files.length > 0) {
    console.log(`📋 Installing workflows...`);
    log('✓', `${files.length} workflows installed to .agents/workflows/`);
  }

  return files;
}

// ─── Steps ─────────────────────────────────────────────────

function banner() {
  console.log('');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     AG Skills — Project Setup                             ║');
  console.log('║     npx ag-unity                                         ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
}

function step1_checkSources() {
  for (const group of SKILL_GROUPS) {
    if (!existsSync(group.src)) {
      console.error(`❌ Error: ${group.name} source not found at ${group.src}`);
      process.exit(1);
    }
  }
}

function step2_installSkills() {
  mkdirSync(SKILLS_DIR, { recursive: true });

  const manifestGroups = {};
  let totalInstalled = 0;

  for (const group of SKILL_GROUPS) {
    console.log(`📚 Installing ${group.label} skills...`);
    const { installed, skillNames } = installSkillGroup(group);
    manifestGroups[group.name] = skillNames;
    log('✓', `${installed} skills installed to .agents/skills/`);
    totalInstalled += installed;
  }

  // Install workflows
  const workflowNames = installWorkflows();

  // Write manifest for idempotent cleanup on next run
  writeManifest(manifestGroups, workflowNames);
  log('✓', 'Manifest written to .agents/skills/.ag-manifest.json');

  // Clean up legacy group folders if they exist (migration from v2 structure)
  for (const group of SKILL_GROUPS) {
    const legacyDir = join(SKILLS_DIR, group.name);
    if (existsSync(legacyDir)) {
      rmSync(legacyDir, { recursive: true, force: true });
      log('✓', `Removed legacy folder: ${group.name}/`);
    }
  }

  console.log('');
  return totalInstalled;
}

function step3_verify() {
  console.log('✅ Verification...');
  const total = countSkillsFlat();
  log('', `Total: ${total} skills in .agents/skills/`);

  const manifest = readManifest();
  for (const group of SKILL_GROUPS) {
    const groupSkills = manifest.groups[group.name] || [];
    log('', `${group.label}: ${groupSkills.length} skills`);
  }

  const workflows = manifest.workflows || [];
  log('', `Workflows: ${workflows.length} in .agents/workflows/`);
  console.log('');
}

function footer() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Setup Complete                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 Summary:');
  log('', `Project:    ${PROJECT_DIR}`);
  log('', `Skills:     .agents/skills/`);
  log('', `Workflows:  .agents/workflows/`);
  console.log('');
  console.log('🚀 Next steps:');
  console.log('   1. Open Antigravity in this project');
  console.log('   2. Skills auto-trigger via YAML frontmatter descriptions');
  console.log('');
  console.log('✅ Done!');
}

// ─── Main ──────────────────────────────────────────────────

function main() {
  banner();
  step1_checkSources();
  step2_installSkills();
  step3_verify();
  footer();
}

main();
