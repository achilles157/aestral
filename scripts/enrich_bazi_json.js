/**
 * Enrichment script for Ba Zi JSON assets.
 * Run: node scripts/enrich_bazi_json.js
 *
 * 1. bazi-pillars.json  — tambah `element_id` (shorthand untuk color-mapping di Flutter)
 * 2. 10day-masters.json — tambah `ai_hook` (teaser untuk AI Oracle)
 * 3. 10gods.json        — tambah `ai_hook` (teaser untuk AI Oracle)
 */

const fs = require('fs');
const path = require('path');

const BASE = path.join(__dirname, '..', 'assets', 'bazi');

// ── 1. bazi-pillars.json ──────────────────────────────────────────────────

const pillarsPath = path.join(BASE, 'bazi-pillars.json');
const pillars = JSON.parse(fs.readFileSync(pillarsPath, 'utf8'));

const stemWordToId = {
  kayu: 'kayu',
  api: 'api',
  tanah: 'tanah',
  logam: 'logam',
  air: 'air',
};

const enrichedPillars = pillars.map((p) => {
  const firstWord = p.element_composition.stem_element.split(' ')[0].toLowerCase();
  const element_id = stemWordToId[firstWord] || firstWord;
  return { ...p, element_id };
});

fs.writeFileSync(pillarsPath, JSON.stringify(enrichedPillars, null, 2));
console.log(`✓ bazi-pillars.json: element_id ditambahkan ke ${enrichedPillars.length} entri`);

// ── 2. 10day-masters.json ─────────────────────────────────────────────────

const mastersPath = path.join(BASE, '10day-masters.json');
const masters = JSON.parse(fs.readFileSync(mastersPath, 'utf8'));

const masterHooks = {
  jia: 'Kamu adalah Sang Pelopor yang selalu tumbuh ke atas — tapi ada satu akar tersembunyi yang selama ini menahanmu dari puncak tertinggimu. Tanya AI Oracle untuk menemukannya.',
  yi: 'Kelenturanmu membuatmu bertahan dalam badai apapun — tapi ada satu titik buta yang membuat orang mengambil keuntungan tanpa kamu sadari. Tanya AI Oracle untuk melihatnya.',
  bing: 'Karisma Mataharimu menerangi siapa saja di sekitarmu — tapi ada satu energi yang secara diam-diam menguras cahayamu sendiri. Tanya AI Oracle untuk mengetahuinya.',
  ding: 'Kehangatan Lilinmu menenangkan semua orang — tapi ada satu kerentanan yang terus-menerus memadamkan apimu di momen paling penting. Tanya AI Oracle untuk mengenal bayangan ini.',
  wu: 'Stabilitasmu adalah fondasi bagi banyak orang — tapi ada satu ketakutan tersembunyi yang membuat Gunung ini tidak pernah benar-benar maju. Tanya AI Oracle.',
  ji: 'Kamu merawat semua orang dengan tulus — tapi ada satu kebutuhan terdalam yang tidak pernah kamu berikan pada dirimu sendiri. Tanya AI Oracle untuk menemukannya.',
  geng: 'Ketajamanmu sangat kuat dan tanpa kompromi — tapi ada satu luka lama yang terus membuat pedang ini retak di saat paling krusial. Tanya AI Oracle.',
  xin: 'Kilauanmu mempesona dunia dari luar — tapi ada satu bayangan gelap yang menyembunyikan nilai sejatimu dari dirimu sendiri. Tanya AI Oracle untuk melihatnya.',
  ren: 'Arus bawahmu membawa kebijaksanaan yang dalam — tapi ada satu rintangan tersembunyi yang membuat sungai besar ini terus berputar di tempat yang sama. Tanya AI Oracle.',
  gui: 'Intuisi jernihmu menyentuh kebenaran yang tidak bisa dilihat orang lain — tapi ada satu pola bawah sadar yang terus mengaburkan visimu sendiri. Tanya AI Oracle untuk mengungkapnya.',
};

const enrichedMasters = masters.map((m) => ({
  ...m,
  ai_hook: masterHooks[m.id] || '',
}));

fs.writeFileSync(mastersPath, JSON.stringify(enrichedMasters, null, 2));
console.log(`✓ 10day-masters.json: ai_hook ditambahkan ke ${enrichedMasters.length} entri`);

// ── 3. 10gods.json ────────────────────────────────────────────────────────

const godsPath = path.join(BASE, '10gods.json');
const gods = JSON.parse(fs.readFileSync(godsPath, 'utf8'));

const godHooks = {
  bi_jian: 'Saudara-saudaramu di sekitarmu bisa jadi penopang terbesar — atau penguras energi terbesar. AI Oracle bisa membedakannya untukmu.',
  jie_cai: 'Kompetisimu sangat kuat dan tak kenal lelah — tapi ada satu musuh tersembunyi yang selama ini kamu anggap teman. Tanya AI Oracle.',
  shi_shen: 'Kreativitasmu mengalir bebas dan penuh cahaya — tapi ada satu blok tersembunyi yang terus menghentikan ekspresimu di titik paling vital. Tanya AI Oracle.',
  shang_guan: 'Bakatmu melampaui batas konvensi — tapi ada satu energi destruktif yang diam-diam mengancam fondasi terkuatmu. Tanya AI Oracle untuk mengelolanya.',
  pian_cai: 'Nasibmu tertarik pada peluang tak terduga — tapi ada satu pola pengeluaran tersembunyi yang terus memiskinkan kekayaan sejatimu. Tanya AI Oracle.',
  zheng_cai: 'Rezekimu tumbuh lewat komitmen dan kerja keras — tapi ada satu keyakinan keliru tentang uang yang menghambat kemakmuranmu. Tanya AI Oracle untuk melihatnya.',
  pian_guan: 'Ambisimu luar biasa dan tak tergoyahkan — tapi ada satu tekanan yang secara diam-diam menggerus kesehatan dan kebahagiaanmu. Tanya AI Oracle.',
  zheng_guan: 'Integritasmu adalah asetmu yang paling berharga — tapi ada satu aturan yang kamu ikuti yang justru membatasimu dari nasib terbaikmu. Tanya AI Oracle.',
  pian_yin: 'Wawasanmu menembus dimensi yang tidak bisa dijangkau sembarang orang — tapi ada satu obsesi yang membuat pikiranmu tidak pernah benar-benar istirahat. Tanya AI Oracle.',
  zheng_yin: 'Dukungan dan perlindungan mengalir alami ke arahmu — tapi ada satu ketergantungan tersembunyi yang membuat pertumbuhanmu terhenti. Tanya AI Oracle untuk membebaskannya.',
};

const enrichedGods = gods.map((g) => ({
  ...g,
  ai_hook: godHooks[g.id] || '',
}));

fs.writeFileSync(godsPath, JSON.stringify(enrichedGods, null, 2));
console.log(`✓ 10gods.json: ai_hook ditambahkan ke ${enrichedGods.length} entri`);

console.log('\nSemua asset Ba Zi berhasil di-enrich. ✓');
