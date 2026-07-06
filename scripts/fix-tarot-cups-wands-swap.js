/**
 * fix-tarot-cups-wands-swap.js
 *
 * Corrects the bilateral Cups/Wands data swap in tarot-merged.json.
 *
 * Affected fields on all 28 cards (14 Cups + 14 Wands):
 *   - img              : suit letter in filename was crossed (w→c, c→w)
 *   - ai_hook_id       : English card name in parentheses had wrong suit
 *   - fortune_telling_id   : Indonesian translations were swapped between suits
 *   - questions_to_ask_id  : Indonesian translations were swapped between suits
 *
 * English fields (fortune_telling_en, questions_to_ask_en) and all other fields
 * are correct and are NOT touched.
 */

const fs   = require('fs');
const path = require('path');

const FILE = path.resolve(__dirname, '..', 'assets', 'tarot', 'tarot-merged.json');

// ── Load ──────────────────────────────────────────────────────────────────────
const cards = JSON.parse(fs.readFileSync(FILE, 'utf8'));

const cupsCards  = cards.filter(c => c.suit === 'Cups');
const wandsCards = cards.filter(c => c.suit === 'Wands');

if (cupsCards.length !== 14 || wandsCards.length !== 14) {
  console.error(`Expected 14 Cups and 14 Wands cards, found ${cupsCards.length} and ${wandsCards.length}. Aborting.`);
  process.exit(1);
}

// ── Build position maps (key = zero-padded number from img filename) ──────────
// Cups currently have w{N}.jpg, Wands currently have c{N}.jpg — both wrong.
const cupsByPos  = {};  // N -> cupsCard
const wandsByPos = {};  // N -> wandsCard

for (const card of cupsCards) {
  const m = card.img.match(/^w(\d+)\.jpg$/);
  if (!m) { console.error(`Unexpected Cups img: ${card.img} (${card.name_en}). Aborting.`); process.exit(1); }
  cupsByPos[m[1]] = card;
}
for (const card of wandsCards) {
  const m = card.img.match(/^c(\d+)\.jpg$/);
  if (!m) { console.error(`Unexpected Wands img: ${card.img} (${card.name_en}). Aborting.`); process.exit(1); }
  wandsByPos[m[1]] = card;
}

// Verify every Cups position has a matching Wands position
const positions = Object.keys(cupsByPos);
for (const N of positions) {
  if (!wandsByPos[N]) {
    console.error(`No matching Wands card at position ${N} for Cups card "${cupsByPos[N].name_en}". Aborting.`);
    process.exit(1);
  }
}

// ── Apply fixes ───────────────────────────────────────────────────────────────
let fixedCount = 0;

for (const N of positions) {
  const cup  = cupsByPos[N];
  const wand = wandsByPos[N];

  // 1. img – swap the suit letter in the filename
  cup.img  = `c${N}.jpg`;
  wand.img = `w${N}.jpg`;

  // 2. ai_hook_id – fix the parenthetical English name
  cup.ai_hook_id  = cup.ai_hook_id.replace(/\(([^)]+) of Wands\)/, '($1 of Cups)');
  wand.ai_hook_id = wand.ai_hook_id.replace(/\(([^)]+) of Cups\)/, '($1 of Wands)');

  // 3. fortune_telling_id & questions_to_ask_id – swap between the two cards
  const tmpFortune   = cup.fortune_telling_id;
  const tmpQuestions = cup.questions_to_ask_id;
  cup.fortune_telling_id   = wand.fortune_telling_id;
  cup.questions_to_ask_id  = wand.questions_to_ask_id;
  wand.fortune_telling_id  = tmpFortune;
  wand.questions_to_ask_id = tmpQuestions;

  fixedCount++;
}

// ── Write back ────────────────────────────────────────────────────────────────
fs.writeFileSync(FILE, JSON.stringify(cards, null, 2), 'utf8');
console.log(`\n✓ Fixed ${fixedCount} Cups/Wands pairs (${fixedCount * 2} cards, 4 fields each).\n`);

// ── Verify ────────────────────────────────────────────────────────────────────
const fixed = JSON.parse(fs.readFileSync(FILE, 'utf8'));
const fc = fixed.filter(c => c.suit === 'Cups');
const fw = fixed.filter(c => c.suit === 'Wands');

let errors = 0;

for (const card of fc) {
  if (!card.img.startsWith('c')) { console.error(`FAIL cups img: ${card.name_en} → ${card.img}`); errors++; }
  if (card.ai_hook_id.includes('of Wands)')) { console.error(`FAIL cups hook: ${card.name_en}`); errors++; }
}
for (const card of fw) {
  if (!card.img.startsWith('w')) { console.error(`FAIL wands img: ${card.name_en} → ${card.img}`); errors++; }
  if (card.ai_hook_id.includes('of Cups)')) { console.error(`FAIL wands hook: ${card.name_en}`); errors++; }
}

if (errors === 0) {
  console.log('Verification passed — no remaining img or ai_hook_id errors.\n');
  console.log('Sample spot-check:');
  [0, 6, 13].forEach(i => {
    const c = fc[i], w = fw[i];
    console.log(`  Cups  [${i}] ${c.name_en.padEnd(20)} img:${c.img}  hook:${c.ai_hook_id.match(/\(([^)]+)\)/)?.[0]}`);
    console.log(`         fortune_id[0]: ${c.fortune_telling_id[0].slice(0, 65)}`);
    console.log(`         fortune_en[0]: ${c.fortune_telling_en[0].slice(0, 65)}`);
    console.log(`  Wands [${i}] ${w.name_en.padEnd(20)} img:${w.img}  hook:${w.ai_hook_id.match(/\(([^)]+)\)/)?.[0]}`);
    console.log(`         fortune_id[0]: ${w.fortune_telling_id[0].slice(0, 65)}`);
    console.log(`         fortune_en[0]: ${w.fortune_telling_en[0].slice(0, 65)}`);
    console.log();
  });
} else {
  console.error(`\n${errors} verification error(s) found. Review the output above.`);
  process.exit(1);
}
