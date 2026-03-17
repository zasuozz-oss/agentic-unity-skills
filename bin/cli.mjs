#!/usr/bin/env node

import { cpSync, rmSync, existsSync, mkdirSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

const PROJECT_DIR = process.cwd();

// ─── Skill Groups ──────────────────────────────────────────

const SKILL_GROUPS = [
  {
    name: 'unity-skills',
    src: join(ROOT, 'global-config', 'skills', 'unity-skills'),
    dst: join(PROJECT_DIR, '.agents', 'skills', 'unity-skills'),
    label: 'Unity',
  },
  {
    name: 'qa-skills',
    src: join(ROOT, 'global-config', 'skills', 'qa-skills'),
    dst: join(PROJECT_DIR, '.agents', 'skills', 'qa-skills'),
    label: 'QA',
  },
];

// ─── Helpers ───────────────────────────────────────────────

function log(icon, msg) {
  console.log(`   ${icon} ${msg}`);
}

function countSkills(dir) {
  let count = 0;
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory() && existsSync(join(dir, entry.name, 'SKILL.md'))) {
        count++;
      }
    }
  } catch {
    // ignore
  }
  return count;
}

function installSkillGroup(group) {
  // Clean replace: remove entire folder to avoid leftover skills from previous versions
  if (existsSync(group.dst)) {
    rmSync(group.dst, { recursive: true, force: true });
  }
  mkdirSync(group.dst, { recursive: true });

  // Copy all skill folders fresh
  const entries = readdirSync(group.src, { withFileTypes: true });
  let installed = 0;
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const src = join(group.src, entry.name);
    if (!existsSync(join(src, 'SKILL.md'))) continue;

    cpSync(src, join(group.dst, entry.name), { recursive: true, force: true });
    installed++;
  }

  return installed;
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
  let totalInstalled = 0;

  for (const group of SKILL_GROUPS) {
    console.log(`📚 Installing ${group.label} skills...`);
    const count = installSkillGroup(group);
    log('✓', `${count} skills installed to .agents/skills/${group.name}/`);
    totalInstalled += count;
  }

  console.log('');
  return totalInstalled;
}

function step3_verify() {
  console.log('✅ Verification...');
  for (const group of SKILL_GROUPS) {
    const count = countSkills(group.dst);
    log('', `${group.label}: ${count} skills`);
  }
  console.log('');
}

function footer() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Setup Complete                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 Summary:');
  log('', `Project:  ${PROJECT_DIR}`);
  for (const group of SKILL_GROUPS) {
    log('', `${group.label}:     .agents/skills/${group.name}/`);
  }
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
