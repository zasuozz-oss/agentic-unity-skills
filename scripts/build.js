#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'src', 'cli', 'index.js');
const DIST_DIR = path.join(ROOT, 'dist', 'cli');
const DIST = path.join(DIST_DIR, 'index.js');

console.log('[build] preparing ag-unity CLI');
fs.rmSync(path.join(ROOT, 'dist'), { recursive: true, force: true });
fs.mkdirSync(DIST_DIR, { recursive: true });
fs.copyFileSync(SRC, DIST);
fs.chmodSync(DIST, 0o755);
console.log('[build] wrote dist/cli/index.js');
