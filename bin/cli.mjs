#!/usr/bin/env node

import { cpSync, rmSync, existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');

const PROJECT_DIR = process.cwd();
const SKILLS_SRC = join(ROOT, 'global-config', 'skills');
const SKILLS_DST = join(PROJECT_DIR, '.agents', 'skills-unity');
const GEMINI_MD = join(PROJECT_DIR, 'GEMINI.md');

const BLOCK_START = '<!-- BEGIN antigravity-unity-skills -->';
const BLOCK_END = '<!-- END antigravity-unity-skills -->';

// ─── Helpers ───────────────────────────────────────────────

function log(icon, msg) {
  console.log(`   ${icon} ${msg}`);
}

function copyDir(src, dest) {
  cpSync(src, dest, { recursive: true, force: true });
}

function countSkills(dir) {
  let count = 0;
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory()) {
        const subDir = join(dir, entry.name);
        const subEntries = readdirSync(subDir, { withFileTypes: true });
        for (const sub of subEntries) {
          if (sub.isDirectory() && existsSync(join(subDir, sub.name, 'SKILL.md'))) {
            count++;
          } else if (sub.name === 'SKILL.md') {
            // Skill directly in category dir
            count++;
            break;
          }
        }
      }
    }
  } catch {
    // ignore
  }
  return count;
}

function countDirs(dir) {
  try {
    return readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).length;
  } catch {
    return 0;
  }
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
    copyDir(SKILLS_DST, backupDir);
    log('✓', `Backup: ${backupDir}`);
    console.log('');
  }
}

function step3_installSkills() {
  console.log('📚 Step 2: Installing Unity skills...');
  mkdirSync(join(PROJECT_DIR, '.agents'), { recursive: true });
  if (existsSync(SKILLS_DST)) rmSync(SKILLS_DST, { recursive: true, force: true });
  copyDir(SKILLS_SRC, SKILLS_DST);
  const count = countSkills(SKILLS_DST);
  log('✓', `${count} skills installed to .agents/skills-unity/`);
  console.log('');
}

function step4_updateGeminiMd() {
  console.log('📝 Step 3: Updating project GEMINI.md...');

  // Block markers only — skills auto-discovered via YAML frontmatter
  const blockContent = `${BLOCK_START}\n${BLOCK_END}`;

  if (existsSync(GEMINI_MD)) {
    let content = readFileSync(GEMINI_MD, 'utf8');

    if (content.includes(BLOCK_START)) {
      // Replace existing block
      const regex = new RegExp(
        escapeRegExp(BLOCK_START) + '[\\s\\S]*?' + escapeRegExp(BLOCK_END),
        'g'
      );
      content = content.replace(regex, blockContent);
      writeFileSync(GEMINI_MD, content, 'utf8');
      log('✓', 'Updated existing block in: GEMINI.md');
    } else {
      // Append block
      content = content.trimEnd() + '\n\n' + blockContent + '\n';
      writeFileSync(GEMINI_MD, content, 'utf8');
      log('✓', 'Appended block to: GEMINI.md');
    }
  } else {
    // Create new file
    writeFileSync(GEMINI_MD, blockContent + '\n', 'utf8');
    log('✓', 'Created: GEMINI.md');
  }
  console.log('');
}

function step5_verify() {
  console.log('✅ Verification...');
  const skillCount = countSkills(SKILLS_DST);
  const categoryCount = countDirs(SKILLS_DST);
  log('', `Skills:     ${skillCount}`);
  log('', `Categories: ${categoryCount}`);
  log('', `GEMINI.md:  ✓`);
  console.log('');
}

function footer() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     Setup Complete                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 Summary:');
  log('', `Project:  ${PROJECT_DIR}`);
  log('', `Skills:   .agents/skills-unity/`);
  log('', `Config:   GEMINI.md updated`);
  console.log('');
  console.log('🚀 Next steps:');
  console.log('   1. Open Antigravity in this project');
  console.log('   2. Unity skills auto-load via YAML frontmatter');
  console.log('');
  console.log('✅ Done!');
}

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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
