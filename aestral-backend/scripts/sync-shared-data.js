/**
 * sync-shared-data.js
 *
 * Copies canonical shared data JSON files from Flutter assets to
 * aestral-backend/src/data/ so TypeScript can import them at build time.
 *
 * Run automatically via the "prebuild" npm script before every wrangler deploy.
 * Canonical source: ../../assets/bazi/
 */

const fs = require('fs');
const path = require('path');

const SHARED_FILES = [
  'bazi-dm-strength-matrix.json',
];

const srcDir = path.join(__dirname, '../../assets/bazi');
const dstDir = path.join(__dirname, '../src/data');

fs.mkdirSync(dstDir, { recursive: true });

for (const file of SHARED_FILES) {
  const src = path.join(srcDir, file);
  const dst = path.join(dstDir, file);
  fs.copyFileSync(src, dst);
  console.log(`[sync-shared-data] ${file} → src/data/${file}`);
}

console.log('[sync-shared-data] Done.');
