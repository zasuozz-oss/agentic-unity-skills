#!/usr/bin/env node

import fs from 'node:fs/promises';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..', '..');
const PROJECT_DIR = process.cwd();
const GLOBAL_CONFIG_DIR = path.join(ROOT, 'global-config');
const INSTRUCTION_SOURCE = path.join(GLOBAL_CONFIG_DIR, 'instruction', 'unity_rule.md');
const MANIFEST_NAME = '.ag-unity-manifest.json';
const LEGACY_MANIFEST_NAME = '.ag-manifest.json';
const UNITY_BLOCK_BEGIN = '<!-- AG-UNITY:BEGIN -->';
const UNITY_BLOCK_END = '<!-- AG-UNITY:END -->';
const PROJECT_INSTRUCTION_FILES = ['AGENTS.md', 'CLAUDE.md'];

const pkg = JSON.parse(readFileSync(path.join(ROOT, 'package.json'), 'utf-8'));

const PROJECT_TARGETS = [
  {
    name: 'Antigravity / Codex',
    skillsDir: path.join(PROJECT_DIR, '.agents', 'skills'),
  },
  {
    name: 'Claude Code',
    skillsDir: path.join(PROJECT_DIR, '.claude', 'skills'),
  },
];

function printHelp() {
  console.log(`ag-unity ${pkg.version}

Usage:
  ag-unity init       Install Unity project skills into the current project
  ag-unity list       List packaged skills
  ag-unity help       Show this help
  ag-unity version    Show version

Run from the Unity project root. The init command does not accept a path.`);
}

function fail(message) {
  console.error(`Error: ${message}`);
  console.error('');
  printHelp();
  process.exitCode = 1;
}

async function readJson(filePath) {
  try {
    return JSON.parse(await fs.readFile(filePath, 'utf-8'));
  } catch {
    return null;
  }
}

async function readManifest(skillsDir) {
  const manifest =
    (await readJson(path.join(skillsDir, MANIFEST_NAME))) ||
    (await readJson(path.join(skillsDir, LEGACY_MANIFEST_NAME)));

  if (manifest && typeof manifest === 'object') {
    return {
      groups: manifest.groups && typeof manifest.groups === 'object' ? manifest.groups : {},
      skills: Array.isArray(manifest.skills) ? manifest.skills : [],
    };
  }

  return { groups: {}, skills: [] };
}

async function writeManifest(skillsDir, groups, targetName) {
  const skillNames = Object.values(groups)
    .flat()
    .sort();
  const manifest = {
    package: pkg.name,
    version: pkg.version,
    installed_at: new Date().toISOString(),
    project_dir: PROJECT_DIR,
    target: targetName,
    skills: skillNames,
    groups,
  };

  await fs.writeFile(
    path.join(skillsDir, MANIFEST_NAME),
    `${JSON.stringify(manifest, null, 2)}\n`,
    'utf-8',
  );
}

function groupNameForSkill(relativeSkillDir) {
  const parts = relativeSkillDir.split('/').filter(Boolean);

  if (parts[0] === 'skills' && parts.length >= 3) {
    return parts[1];
  }

  if (parts[0] === 'skills' && parts.length >= 2) {
    return 'skills';
  }

  return parts.length > 1 ? parts[0] : 'global-config';
}

async function discoverSkillSources() {
  if (!existsSync(GLOBAL_CONFIG_DIR)) {
    throw new Error(`global-config source not found: ${GLOBAL_CONFIG_DIR}`);
  }

  const skills = [];

  async function walk(dir) {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    const hasSkillFile = entries.some((entry) => entry.isFile() && entry.name === 'SKILL.md');

    if (hasSkillFile) {
      const relativePath = path.relative(GLOBAL_CONFIG_DIR, dir).split(path.sep).join('/');
      skills.push({
        name: path.basename(dir),
        src: dir,
        relativePath,
        group: groupNameForSkill(relativePath),
      });
      return;
    }

    const childDirs = entries
      .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
      .map((entry) => entry.name)
      .sort();

    for (const childDir of childDirs) {
      await walk(path.join(dir, childDir));
    }
  }

  await walk(GLOBAL_CONFIG_DIR);

  if (skills.length === 0) {
    throw new Error(`no skills found under ${GLOBAL_CONFIG_DIR}`);
  }

  const seen = new Map();
  for (const skill of skills) {
    const previous = seen.get(skill.name);
    if (previous) {
      throw new Error(
        `duplicate skill name "${skill.name}" in ${previous.relativePath} and ${skill.relativePath}`,
      );
    }
    seen.set(skill.name, skill);
  }

  return skills.sort((a, b) => {
    const byGroup = a.group.localeCompare(b.group);
    return byGroup || a.name.localeCompare(b.name);
  });
}

async function discoverSkillGroups() {
  const skills = await discoverSkillSources();
  const groupMap = new Map();

  for (const skill of skills) {
    if (!groupMap.has(skill.group)) {
      groupMap.set(skill.group, []);
    }
    groupMap.get(skill.group).push(skill);
  }

  return Array.from(groupMap, ([name, groupSkills]) => ({
    name,
    skills: groupSkills.sort((a, b) => a.name.localeCompare(b.name)),
  })).sort((a, b) => a.name.localeCompare(b.name));
}

function groupsToManifest(groups) {
  return Object.fromEntries(
    groups.map((group) => [group.name, group.skills.map((skill) => skill.name).sort()]),
  );
}

function managedSkillNamesFromManifest(manifest) {
  return new Set([
    ...manifest.skills,
    ...Object.values(manifest.groups).flatMap((skillNames) =>
      Array.isArray(skillNames) ? skillNames : [],
    ),
  ]);
}

function skillNamesFromGroups(groups) {
  return new Set(groups.flatMap((group) => group.skills.map((skill) => skill.name)));
}

function groupNamesFromGroups(groups) {
  return new Set(groups.map((group) => group.name));
}

async function copyDirRecursive(src, dest) {
  await fs.mkdir(dest, { recursive: true });
  const entries = await fs.readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      await copyDirRecursive(srcPath, destPath);
    } else {
      await fs.copyFile(srcPath, destPath);
    }
  }
}

async function removeIfExists(targetPath) {
  await fs.rm(targetPath, { recursive: true, force: true });
}

async function cleanupManagedSkills(skillsDir, manifest, groups) {
  const oldSkillNames = managedSkillNamesFromManifest(manifest);
  const newSkillNames = skillNamesFromGroups(groups);

  for (const skillName of oldSkillNames) {
    if (!newSkillNames.has(skillName)) {
      await removeIfExists(path.join(skillsDir, skillName));
    }
  }

  for (const skillName of newSkillNames.values()) {
    await removeIfExists(path.join(skillsDir, skillName));
  }
}

async function removeLegacyGroupFolders(skillsDir, manifest, groups) {
  const groupNames = new Set([
    ...Object.keys(manifest.groups),
    ...groupNamesFromGroups(groups),
  ]);
  const newSkillNames = skillNamesFromGroups(groups);

  for (const groupName of groupNames) {
    if (!newSkillNames.has(groupName)) {
      await removeIfExists(path.join(skillsDir, groupName));
    }
  }
}

function mergeManagedBlock(existingContent, managedBlock) {
  const beginIndex = existingContent.indexOf(UNITY_BLOCK_BEGIN);
  const endIndex = existingContent.indexOf(UNITY_BLOCK_END, beginIndex);

  if (beginIndex !== -1 && endIndex !== -1) {
    return [
      existingContent.slice(0, beginIndex).trimEnd(),
      managedBlock,
      existingContent.slice(endIndex + UNITY_BLOCK_END.length).trimStart(),
    ]
      .filter((part) => part.length > 0)
      .join('\n\n')
      .concat('\n');
  }

  if (existingContent.trim().length === 0) {
    return `${managedBlock}\n`;
  }

  return `${existingContent.trimEnd()}\n\n${managedBlock}\n`;
}

async function installProjectInstructionFiles() {
  const managedBlock = (await fs.readFile(INSTRUCTION_SOURCE, 'utf-8')).trim();

  for (const fileName of PROJECT_INSTRUCTION_FILES) {
    const targetPath = path.join(PROJECT_DIR, fileName);
    const existingContent = existsSync(targetPath) ? await fs.readFile(targetPath, 'utf-8') : '';
    await fs.writeFile(targetPath, mergeManagedBlock(existingContent, managedBlock), 'utf-8');
  }

  return PROJECT_INSTRUCTION_FILES.length;
}

async function installTarget(target, groups) {
  await fs.mkdir(target.skillsDir, { recursive: true });
  const manifest = await readManifest(target.skillsDir);
  const manifestGroups = groupsToManifest(groups);
  let installed = 0;

  await cleanupManagedSkills(target.skillsDir, manifest, groups);

  for (const group of groups) {
    for (const skill of group.skills) {
      await copyDirRecursive(skill.src, path.join(target.skillsDir, skill.name));
      installed++;
    }
  }

  await removeLegacyGroupFolders(target.skillsDir, manifest, groups);
  await writeManifest(target.skillsDir, manifestGroups, target.name);

  return installed;
}

async function initCommand(args) {
  if (args.length > 0) {
    fail('ag-unity init does not accept a project path. cd into the Unity project, then run ag-unity init.');
    return;
  }

  const groups = await discoverSkillGroups();

  console.log('');
  console.log('AG Unity Skills - Project Init');
  console.log('================================');
  console.log(`Project: ${PROJECT_DIR}`);
  console.log('');

  for (const target of PROJECT_TARGETS) {
    const installed = await installTarget(target, groups);
    console.log(`+ ${target.name}: ${installed} skills -> ${path.relative(PROJECT_DIR, target.skillsDir)}`);
  }

  const instructionCount = await installProjectInstructionFiles();
  console.log(`+ Project instructions: ${instructionCount} files -> AGENTS.md, CLAUDE.md`);

  console.log('');
  console.log('Next steps: open this project in Antigravity, Codex, or Claude Code.');
}

async function listCommand(args) {
  if (args.length > 0) {
    fail('ag-unity list does not accept arguments.');
    return;
  }

  const groups = await discoverSkillGroups();

  console.log(`ag-unity ${pkg.version}`);
  for (const group of groups) {
    console.log('');
    console.log(`${group.name} (${group.skills.length})`);
    for (const skill of group.skills) {
      console.log(`  - ${skill.name}`);
    }
  }
}

async function main() {
  const [command = 'help', ...args] = process.argv.slice(2);

  if (command === 'init') {
    await initCommand(args);
    return;
  }

  if (command === 'list') {
    await listCommand(args);
    return;
  }

  if (command === 'version' || command === '--version' || command === '-v') {
    console.log(pkg.version);
    return;
  }

  if (command === 'help' || command === '--help' || command === '-h') {
    printHelp();
    return;
  }

  fail(`unknown command: ${command}`);
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
});
