#!/usr/bin/env node

import { cpSync, rmSync, existsSync, mkdirSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

const PROJECT_DIR = process.cwd();
const SKILLS_SRC = join(ROOT, 'global-config', 'skills');
const SKILLS_DST = join(PROJECT_DIR, '.agents', 'skills', 'unity-skills');

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

// ─── Steps ─────────────────────────────────────────────────

function banner() {
  console.log('');
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Unity Skills — Project Setup                          ║');
  console.log('║     npx ag-unity                                         ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
}

function step1_checkSource() {
  if (!existsSync(SKILLS_SRC)) {
    console.error('❌ Error: global-config/skills/ not found');
    process.exit(1);
  }
}


function step3_installSkills() {
  console.log('📚 Installing Unity skills...');

  // Clean replace: remove entire folder to avoid leftover skills from previous versions
  if (existsSync(SKILLS_DST)) {
    rmSync(SKILLS_DST, { recursive: true, force: true });
  }
  mkdirSync(SKILLS_DST, { recursive: true });

  // Copy all skill folders fresh
  const entries = readdirSync(SKILLS_SRC, { withFileTypes: true });
  let installed = 0;
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const src = join(SKILLS_SRC, entry.name);
    if (!existsSync(join(src, 'SKILL.md'))) continue;

    cpSync(src, join(SKILLS_DST, entry.name), { recursive: true, force: true });
    installed++;
  }

  log('✓', `${installed} skills installed to .agents/skills/unity-skills/`);
  console.log('');
}

function step4_verify() {
  console.log('✅ Verification...');
  const skillCount = countSkills(SKILLS_DST);
  log('', `Skills: ${skillCount}`);
  console.log('');
}

function footer() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Setup Complete                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 Summary:');
  log('', `Project:  ${PROJECT_DIR}`);
  log('', `Skills:   .agents/skills/unity-skills/`);
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
  step1_checkSource();
  step3_installSkills();
  step4_verify();
  footer();
}

main();
