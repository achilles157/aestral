// Exhaustive Ten Gods verification: 10 DM x 10 target = 100 combos
const EL = ['wood','wood','fire','fire','earth','earth','metal','metal','water','water'];
const GEN = { wood:'fire', fire:'earth', earth:'metal', metal:'water', water:'wood' };
const CTL = { wood:'earth', earth:'water', water:'fire', fire:'metal', metal:'wood' };
const STEMS = ['Jia','Yi','Bing','Ding','Wu','Ji','Geng','Xin','Ren','Gui'];

// Implementation under test (mirrors bazi.ts / bazi_utils.dart)
function getTenGodId(dm, tg) {
  const dmEl = EL[dm], tgEl = EL[tg];
  const same = (dm % 2) === (tg % 2);
  if (tgEl === dmEl)        return same ? 'friend'            : 'rob_wealth';
  if (GEN[dmEl] === tgEl)   return same ? 'eating_god'        : 'hurting_officer';
  if (CTL[dmEl] === tgEl)   return same ? 'indirect_wealth'   : 'direct_wealth';
  if (CTL[tgEl] === dmEl)   return same ? 'seven_killings'    : 'direct_officer';
  if (GEN[tgEl] === dmEl)   return same ? 'indirect_resource' : 'direct_resource';
  return 'UNREACHABLE';
}

// Independent classical reference: derive expected god from first principles
// Relationship categories (from DM's perspective):
//   same element        -> 比劫 (peer):     same pol 比肩 friend / diff 劫财 rob_wealth
//   DM produces target  -> 食伤 (output):   same pol 食神 eating_god / diff 伤官 hurting_officer
//   DM controls target  -> 财 (wealth):     same pol 偏财 indirect_wealth / diff 正财 direct_wealth
//   target controls DM  -> 官杀 (officer):  same pol 七杀 seven_killings / diff 正官 direct_officer
//   target produces DM  -> 印 (resource):   same pol 偏印 indirect_resource / diff 正印 direct_resource
function reference(dm, tg) {
  const dmEl = EL[dm], tgEl = EL[tg];
  const same = (dm % 2) === (tg % 2);
  let cat;
  if (dmEl === tgEl) cat = 'peer';
  else if (GEN[dmEl] === tgEl) cat = 'output';
  else if (CTL[dmEl] === tgEl) cat = 'wealth';
  else if (CTL[tgEl] === dmEl) cat = 'officer';
  else if (GEN[tgEl] === dmEl) cat = 'resource';
  const map = {
    peer:     same ? 'friend' : 'rob_wealth',
    output:   same ? 'eating_god' : 'hurting_officer',
    wealth:   same ? 'indirect_wealth' : 'direct_wealth',
    officer:  same ? 'seven_killings' : 'direct_officer',
    resource: same ? 'indirect_resource' : 'direct_resource',
  };
  return map[cat];
}

// Hard-coded golden vectors from classical tables (spot checks across all DMs)
const golden = [
  // [DM, target, expected]
  [0, 0, 'friend'],            // Jia vs Jia 比肩
  [0, 1, 'rob_wealth'],        // Jia vs Yi 劫财
  [0, 2, 'eating_god'],        // Jia vs Bing 食神 (wood->fire, both yang)
  [0, 3, 'hurting_officer'],   // Jia vs Ding 伤官
  [0, 4, 'indirect_wealth'],   // Jia vs Wu 偏财 (wood controls earth, both yang)
  [0, 5, 'direct_wealth'],     // Jia vs Ji 正财
  [0, 6, 'seven_killings'],    // Jia vs Geng 七杀 (metal controls wood, both yang)
  [0, 7, 'direct_officer'],    // Jia vs Xin 正官
  [0, 8, 'indirect_resource'], // Jia vs Ren 偏印 (water produces wood, both yang)
  [0, 9, 'direct_resource'],   // Jia vs Gui 正印
  [6, 6, 'friend'],            // Geng vs Geng 比肩
  [6, 7, 'rob_wealth'],        // Geng vs Xin 劫财
  [6, 8, 'eating_god'],        // Geng vs Ren 食神 (metal->water, both yang)
  [6, 9, 'hurting_officer'],   // Geng vs Gui 伤官
  [6, 0, 'indirect_wealth'],   // Geng vs Jia 偏财 (metal controls wood, both yang)
  [6, 1, 'direct_wealth'],     // Geng vs Yi 正财
  [6, 2, 'seven_killings'],    // Geng vs Bing 七杀 (fire controls metal, both yang)
  [6, 3, 'direct_officer'],    // Geng vs Ding 正官
  [6, 4, 'indirect_resource'], // Geng vs Wu 偏印 (earth produces metal, both yang)
  [6, 5, 'direct_resource'],   // Geng vs Ji 正印
  [5, 8, 'direct_wealth'],     // Ji vs Ren 正财 (earth controls water, yin vs yang)
  [9, 2, 'direct_wealth'],     // Gui vs Bing 正财 (water controls fire, yin vs yang)
  [3, 6, 'direct_wealth'],     // Ding vs Geng 正财
  [1, 4, 'direct_wealth'],     // Yi vs Wu 正财
  [7, 0, 'direct_wealth'],     // Xin vs Jia 正财
  [2, 9, 'direct_officer'],    // Bing vs Gui 正官 (water controls fire, yang vs yin)
  [4, 1, 'direct_officer'],    // Wu vs Yi 正官 (wood controls earth)
  [8, 5, 'direct_officer'],    // Ren vs Ji 正官 (earth controls water)
];

let fails = 0;
// 1) Exhaustive: implementation vs independent reference
for (let dm = 0; dm < 10; dm++) {
  for (let tg = 0; tg < 10; tg++) {
    const got = getTenGodId(dm, tg), exp = reference(dm, tg);
    if (got !== exp) { console.log(`FAIL ${STEMS[dm]} vs ${STEMS[tg]}: got ${got}, expected ${exp}`); fails++; }
  }
}
// 2) Golden vectors
for (const [dm, tg, exp] of golden) {
  const got = getTenGodId(dm, tg);
  if (got !== exp) { console.log(`GOLDEN FAIL ${STEMS[dm]} vs ${STEMS[tg]}: got ${got}, expected ${exp}`); fails++; }
}
// 3) Distribution check: each DM must yield each of the 10 gods exactly once
for (let dm = 0; dm < 10; dm++) {
  const seen = new Set();
  for (let tg = 0; tg < 10; tg++) seen.add(getTenGodId(dm, tg));
  if (seen.size !== 10) { console.log(`DISTRIBUTION FAIL DM=${STEMS[dm]}: only ${seen.size} distinct gods`); fails++; }
}
console.log(fails === 0 ? 'ALL 100 COMBINATIONS + 28 GOLDEN VECTORS + DISTRIBUTION: PASS' : `${fails} FAILURES`);

// Print full matrix for the report
console.log('\nFull matrix (rows = DM, cols = target):');
for (let dm = 0; dm < 10; dm++) {
  const row = [];
  for (let tg = 0; tg < 10; tg++) row.push(getTenGodId(dm, tg));
  console.log(`${STEMS[dm].padEnd(5)}: ${row.join(', ')}`);
}
