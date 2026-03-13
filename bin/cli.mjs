#!/usr/bin/env node

import { cpSync, rmSync, existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

const PROJECT_DIR = process.cwd();
const SKILLS_SRC = join(ROOT, 'global-config', 'skills');
const SKILLS_DST = join(PROJECT_DIR, '.agents', 'skills', 'unity-skills');
const GEMINI_MD = join(PROJECT_DIR, 'GEMINI.md');

const BLOCK_START = '<!-- BEGIN antigravity-unity-skills -->';
const BLOCK_END = '<!-- END antigravity-unity-skills -->';

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

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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

function step2_backup() {
  if (existsSync(SKILLS_DST) && readdirSync(SKILLS_DST).length > 0) {
    const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const backupDir = `${SKILLS_DST}-backup-${ts}`;
    console.log('📦 Step 1: Backing up existing skills...');
    cpSync(SKILLS_DST, backupDir, { recursive: true, force: true });
    log('✓', `Backup: ${backupDir}`);
    console.log('');
  }
}

function step3_installSkills() {
  console.log('📚 Step 2: Installing Unity skills...');
  mkdirSync(SKILLS_DST, { recursive: true });

  // Copy each skill folder directly (flat structure)
  const entries = readdirSync(SKILLS_SRC, { withFileTypes: true });
  let installed = 0;
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const src = join(SKILLS_SRC, entry.name);
    if (!existsSync(join(src, 'SKILL.md'))) continue;

    const dest = join(SKILLS_DST, entry.name);
    if (existsSync(dest)) rmSync(dest, { recursive: true, force: true });
    cpSync(src, dest, { recursive: true, force: true });
    installed++;
  }

  log('✓', `${installed} skills installed to .agents/skills/`);
  console.log('');
}

function step4_updateGeminiMd() {
  console.log('📝 Step 3: Updating project GEMINI.md...');

  const blockContent = `${BLOCK_START}\n${BLOCK_END}`;

  if (existsSync(GEMINI_MD)) {
    let content = readFileSync(GEMINI_MD, 'utf8');

    if (content.includes(BLOCK_START)) {
      const regex = new RegExp(
        escapeRegExp(BLOCK_START) + '[\\s\\S]*?' + escapeRegExp(BLOCK_END),
        'g'
      );
      content = content.replace(regex, blockContent);
      writeFileSync(GEMINI_MD, content, 'utf8');
      log('✓', 'Updated existing block in: GEMINI.md');
    } else {
      content = content.trimEnd() + '\n\n' + blockContent + '\n';
      writeFileSync(GEMINI_MD, content, 'utf8');
      log('✓', 'Appended block to: GEMINI.md');
    }
  } else {
    writeFileSync(GEMINI_MD, blockContent + '\n', 'utf8');
    log('✓', 'Created: GEMINI.md');
  }
  console.log('');
}

function step5_verify() {
  console.log('✅ Verification...');
  const skillCount = countSkills(SKILLS_DST);
  log('', `Skills: ${skillCount}`);
  log('', `GEMINI.md: ✓`);
  console.log('');
}

function footer() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Setup Complete                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 Summary:');
  log('', `Project:  ${PROJECT_DIR}`);
  log('', `Skills:   .agents/skills/`);
  log('', `Config:   GEMINI.md updated`);
  console.log('');
  console.log('🚀 Next steps:');
  console.log('   1. Open Antigravity in this project');
  console.log('   2. Unity skills auto-load via YAML frontmatter');
  console.log('');
  console.log('✅ Done!');
}

// ─── Main ──────────────────────────────────────────────────

function main() {
  banner();
  step1_checkSource();
  step2_backup();
  step3_installSkills();
  step4_updateGeminiMd();
  step5_verify();
  footer();
}

main();
