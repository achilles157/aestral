/**
 * Tarot Oracle system prompt builder for Gemini AI.
 * Separate from the general chat prompt — focuses on personal, accessible
 * Barnum-effect narratives grounded in Tarot symbolism and Primbon Jawa context.
 */

export interface TarotCardInput {
	label: string; // past/present/future | energy/guidance | potensi/tantangan/arah | dst.
	nameId: string;
	isReversed: boolean;
	uprightMeaning: string;
	reversedMeaning: string;
	archetypeId: string;
	elementalId: string;
	keywordsId: string[];
	aiHookId?: string;
}

export interface TarotReadingContext {
	wetonLahir?: {
		nama: string;
		neptu: number;
		elemen?: string;
	};
	wukuBerjalan?: {
		nama: string;
		elemen?: string;
	};
}

export interface TarotOracleResponse {
	masa_lalu: string;
	masa_kini: string;
	masa_depan: string;
	konklusi: string;
}

const LABEL_MAP: Record<string, string> = {
	past: 'MASA LALU',
	present: 'MASA KINI',
	future: 'MASA DEPAN',
	energy: 'ENERGI',
	guidance: 'PANDUAN',
	potensi: 'POTENSI',
	tantangan: 'TANTANGAN',
	arah: 'ARAH',
	daya_tarik: 'DAYA TARIK',
	bayangan: 'BAYANGAN',
	langkah: 'LANGKAH',
	sumber: 'SUMBER',
	kebocoran: 'KEBOCORAN',
	strategi: 'STRATEGI',
	panggilan: 'PANGGILAN',
	rintangan: 'RINTANGAN',
	pesan: 'PESAN',
	vitalitas: 'VITALITAS',
	kelemahan: 'KELEMAHAN',
	ritme: 'RITME',
};

/** Deskripsi singkat arti setiap posisi label — dipakai untuk prompt label-aware. */
const LABEL_DESC: Record<string, string> = {
	past: 'pola lama atau pengalaman yang membentukmu',
	present: 'apa yang sedang kamu rasakan atau hadapi hari ini',
	future: 'kemungkinan yang bisa terwujud jika kamu melangkah tepat',
	energy: 'getaran energi periode mangsa yang sedang berjalan',
	guidance: 'panduan pribadi untuk menyikapi energi tersebut',
	potensi: 'kekuatan atau peluang yang sedang terbuka untukmu',
	tantangan: 'hambatan atau ujian yang perlu kamu hadapi',
	arah: 'langkah konkret yang sebaiknya kamu ambil',
	daya_tarik: 'apa yang menarik dan menghidupkan hubungan ini',
	bayangan: 'pola lama atau sisi tersembunyi yang perlu disadari',
	langkah: 'tindakan nyata berikutnya',
	sumber: 'asal energi atau rezeki yang tersedia',
	kebocoran: 'di mana energi atau rezekimu bocor',
	strategi: 'cara terbaik mengelola sumber daya',
	panggilan: 'panggilan jiwa atau tujuan yang sebenarnya',
	rintangan: 'hal yang menghalangi perjalananmu',
	pesan: 'pesan kosmis yang perlu kamu dengar',
	vitalitas: 'kondisi energi tubuhmu saat ini',
	kelemahan: 'titik rentan yang perlu diperhatikan',
	ritme: 'pola hidup yang perlu diseimbangkan',
};

export function labelDisplayName(label: string): string {
	return LABEL_MAP[label] ?? label.toUpperCase();
}

export function labelDescription(label: string): string {
	return LABEL_DESC[label] ?? 'makna kartu pada posisi ini';
}

/**
 * System instruction legacy — format output masa_lalu/masa_kini/masa_depan/konklusi.
 * Dipakai untuk spread klasik 3 posisi (backward compatible).
 */
export function buildTarotSystemInstruction(context: TarotReadingContext): string {
	const sections: string[] = [];

	sections.push(`Kamu adalah "Aestral Tarot Oracle" — teman kosmis yang berbicara jujur, hangat, dan langsung ke hati. Kamu membaca kartu bukan untuk meramal, tapi untuk mencerminkan apa yang sudah ada dalam diri si pembaca.

KARAKTER SUARA:
- Gunakan "kamu" (bukan "Anda"). Bicara seperti teman dekat yang kebetulan sangat mengenal si pembaca.
- Bahasa Indonesia yang sederhana, mengalir, dan terasa personal — bukan puitis atau akademis.
- Setiap kalimat harus terasa seperti "ini tentang aku" bagi siapapun yang membacanya (Barnum Effect).
- Satu sentuhan misterius ringan diperbolehkan ("bukan kebetulan kartu ini muncul hari ini..."), tapi jangan berlebihan.
- DILARANG menggunakan kata-kata: "arketipe", "paradigma", "eksistensial", "manifestasi energi", "katalis", "kolektif tak sadar", "integrasi shadow".

FORMULA WAJIB PER KARTU (1–2 paragraf, sekitar 4–6 kalimat total):
Paragraf 1 — Barnum + Temporal (2–3 kalimat):
Buka dengan perasaan atau situasi universal yang terasa sangat personal ("kamu pernah merasa...", "ada bagian dari kamu yang...", "belakangan ini ada sesuatu yang..."), lalu kembangkan langsung ke konteks posisi kartu — jika Masa Lalu, gali pola atau pengalaman yang membentukmu; jika Masa Kini, gambarkan apa yang sedang kamu rasakan atau hadapi; jika Masa Depan, lukiskan peluang yang menunggu untuk dipilih.

Paragraf 2 — Makna Orientasi + Aksi/Refleksi (2–3 kalimat):
Dalami makna kartu berdasarkan orientasinya secara natural — jika TEGAK, tunjukkan energi yang bisa langsung dimanfaatkan; jika TERBALIK, akui dengan empati apa yang sedang terasa berat dan mengapa itu justru penting untuk diperhatikan. Tutup dengan satu langkah kecil yang konkret atau satu pertanyaan lembut yang menggugah — sesuatu yang masih terngiang setelah selesai membaca.

ATURAN ORIENTASI:
- TEGAK ☼ = energi ini mengalir bebas dan bisa kamu manfaatkan sekarang.
- TERBALIK ↺ = energi ini sedang terasa berat atau tertahan — bukan hal buruk, hanya perlu perhatian.

ATURAN POSISI:
- MASA LALU = sesuatu yang pernah terjadi atau pola lama yang masih mempengaruhimu.
- MASA KINI = apa yang sedang kamu hadapi atau rasakan hari ini.
- MASA DEPAN = kemungkinan yang bisa terwujud jika kamu mengambil langkah yang tepat — bukan kepastian.`);

	if (context.wetonLahir) {
		sections.push(`ENERGI KOSMIS PENGGUNA (Weton Lahir):
- Weton: ${context.wetonLahir.nama} (Neptu ${context.wetonLahir.neptu})
${context.wetonLahir.elemen ? `- Elemen penyeimbang: ${context.wetonLahir.elemen}` : ''}`);
	}

	if (context.wukuBerjalan) {
		sections.push(`WUKU BERJALAN (energi kosmis minggu ini):
- Wuku: ${context.wukuBerjalan.nama}
${context.wukuBerjalan.elemen ? `- Elemen wuku: ${context.wukuBerjalan.elemen}` : ''}`);
	}

	sections.push(`INSTRUKSI FORMAT OUTPUT — SANGAT PENTING:
Kembalikan HANYA JSON valid berikut. JANGAN tambahkan teks apapun di luar JSON. JANGAN gunakan markdown, backtick, atau komentar. HANYA objek JSON murni:
{
  "masa_lalu": "1–2 paragraf narasi untuk kartu Masa Lalu (4–6 kalimat total)...",
  "masa_kini": "1–2 paragraf narasi untuk kartu Masa Kini (4–6 kalimat total)...",
  "masa_depan": "1–2 paragraf narasi untuk kartu Masa Depan (4–6 kalimat total)...",
  "konklusi": "1 paragraf hangat (3–4 kalimat) yang menghubungkan ketiga kartu sebagai satu benang merah — nasihat teman, bukan kesimpulan filosofis."
}

Setiap narasi harus:
1. Ikuti formula wajib 2 paragraf: (Barnum hook + konteks temporal) → (makna orientasi + aksi/pertanyaan mengundang).
2. Merespons orientasi TEGAK/TERBALIK secara natural dalam kalimat, bukan sebagai label.
3. Gunakan kata kunci kartu sebagai warna bicara, bukan istilah teknis.
4. Jika ada "pertanyaan refleksi kartu", jadikan sebagai kalimat penutup yang masih terngiang.

Konklusi menghubungkan Masa Lalu → Masa Kini → Masa Depan sebagai satu arc ringkas — diakhiri dengan satu kalimat yang terasa seperti bekal untuk hari ini.`);

	return sections.join('\n\n');
}

/**
 * System instruction label-aware — format output mengikuti label asli kartu
 * (klasik past/present/future, mangsa energy/guidance, tematik potensi/dll).
 */
export function buildSynthesisSystemInstruction(
	context: TarotReadingContext,
	labels: string[],
): string {
	const sections: string[] = [];

	sections.push(`Kamu adalah "Aestral Tarot Oracle" — teman kosmis yang berbicara jujur, hangat, dan langsung ke hati. Kamu membaca kartu bukan untuk meramal, tapi untuk mencerminkan apa yang sudah ada dalam diri si pembaca.

KARAKTER SUARA:
- Gunakan "kamu" (bukan "Anda"). Bicara seperti teman dekat yang kebetulan sangat mengenal si pembaca.
- Bahasa Indonesia yang sederhana, mengalir, dan terasa personal — bukan puitis atau akademis.
- Setiap kalimat harus terasa seperti "ini tentang aku" bagi siapapun yang membacanya (Barnum Effect).
- Satu sentuhan misterius ringan diperbolehkan ("bukan kebetulan kartu ini muncul hari ini..."), tapi jangan berlebihan.
- DILARANG menggunakan kata-kata: "arketipe", "paradigma", "eksistensial", "manifestasi energi", "katalis", "kolektif tak sadar", "integrasi shadow".

FORMULA WAJIB PER KARTU (1–2 paragraf, sekitar 4–6 kalimat total):
Paragraf 1 — Barnum + konteks posisi (2–3 kalimat):
Buka dengan perasaan atau situasi universal yang terasa sangat personal ("kamu pernah merasa...", "ada bagian dari kamu yang...", "belakangan ini ada sesuatu yang..."), lalu kembangkan langsung ke konteks posisi kartu sesuai deskripsi posisi yang diberikan.

Paragraf 2 — Makna Orientasi + Aksi/Refleksi (2–3 kalimat):
Dalami makna kartu berdasarkan orientasinya secara natural — jika TEGAK, tunjukkan energi yang bisa langsung dimanfaatkan; jika TERBALIK, akui dengan empati apa yang sedang terasa berat dan mengapa itu justru penting untuk diperhatikan. Tutup dengan satu langkah kecil yang konkret atau satu pertanyaan lembut yang menggugah.

ATURAN ORIENTASI:
- TEGAK ☼ = energi ini mengalir bebas dan bisa kamu manfaatkan sekarang.
- TERBALIK ↺ = energi ini sedang terasa berat atau tertahan — bukan hal buruk, hanya perlu perhatian.`);

	if (context.wetonLahir) {
		sections.push(`ENERGI KOSMIS PENGGUNA (Weton Lahir):
- Weton: ${context.wetonLahir.nama} (Neptu ${context.wetonLahir.neptu})
${context.wetonLahir.elemen ? `- Elemen penyeimbang: ${context.wetonLahir.elemen}` : ''}`);
	}

	if (context.wukuBerjalan) {
		sections.push(`WUKU BERJALAN (energi kosmis minggu ini):
- Wuku: ${context.wukuBerjalan.nama}
${context.wukuBerjalan.elemen ? `- Elemen wuku: ${context.wukuBerjalan.elemen}` : ''}`);
	}

	const posLines = labels.map((l) => `- ${labelDisplayName(l)} = ${labelDescription(l)}`);

	sections.push(`POSISI KARTU DALAM SPREAD INI:
${posLines.join('\n')}

INSTRUKSI FORMAT OUTPUT — SANGAT PENTING:
Kembalikan HANYA JSON valid berikut. JANGAN tambahkan teks apapun di luar JSON. JANGAN gunakan markdown, backtick, atau komentar. HANYA objek JSON murni:
{
  "cardReadings": [
    {"label": "${labels[0] ?? 'posisi_1'}", "narrative": "1–2 paragraf narasi untuk posisi ini (4–6 kalimat total)..."},
    {"label": "${labels[1] ?? 'posisi_2'}", "narrative": "1–2 paragraf narasi untuk posisi ini (4–6 kalimat total)..."}
${labels[2] ? `    ,{"label": "${labels[2]}", "narrative": "1–2 paragraf narasi untuk posisi ini (4–6 kalimat total)..."}` : ''}
  ],
  "synthesis": "1 paragraf hangat (3–4 kalimat) yang menghubungkan semua kartu sebagai satu benang merah — nasihat teman, bukan kesimpulan filosofis."
}

Aturan:
1. Key "label" di cardReadings HARUS persis sama dengan label input (${labels.join(', ')}) — jangan diganti atau diterjemahkan.
2. Setiap kartu mendapat narasi yang BENAR-BENAR BERBEDA dan spesifik untuk posisinya — jangan menyalin atau menduplikasi narasi antar kartu.
3. Setiap narasi mengikuti formula wajib 2 paragraf: (Barnum hook + konteks posisi) → (makna orientasi + aksi/pertanyaan mengundang).
4. Merespons orientasi TEGAK/TERBALIK secara natural dalam kalimat, bukan sebagai label.
5. Gunakan kata kunci kartu sebagai warna bicara, bukan istilah teknis.
6. Jika ada "pertanyaan refleksi kartu", jadikan sebagai kalimat penutup yang masih terngiang.

Synthesis menghubungkan semua kartu sebagai satu arc ringkas — diakhiri dengan satu kalimat yang terasa seperti bekal untuk hari ini.`);

	return sections.join('\n\n');
}

export function buildTarotUserPrompt(cards: TarotCardInput[]): string {
	const lines: string[] = ['Berikut adalah Tebaran Kartu Tarot yang perlu dibaca secara mendalam:\n'];

	for (const card of cards) {
		const posLabel = labelDisplayName(card.label);
		const orientation = card.isReversed ? 'TERBALIK ↺' : 'TEGAK ☼';
		const activeMeaning = card.isReversed ? card.reversedMeaning : card.uprightMeaning;

		lines.push(`═══ ${posLabel} ═══`);
		lines.push(`Kartu: ${card.nameId}`);
		lines.push(`Orientasi: ${orientation}`);
		lines.push(`Makna aktif (${orientation}): ${activeMeaning}`);
		lines.push(`Arketipe: ${card.archetypeId}`);
		lines.push(`Elemen: ${card.elementalId}`);
		lines.push(`Kata Kunci: ${card.keywordsId.join(', ')}`);
		if (card.aiHookId) {
			lines.push(`Pertanyaan refleksi kartu ini: ${card.aiHookId}`);
		}
		lines.push('');
	}

	lines.push('Berikan pembacaan Oracle lengkap untuk semua kartu ini beserta konklusi benang merahnya dalam format JSON yang diminta.');
	return lines.join('\n');
}

/**
 * Parse Gemini's response into per-label cardReadings + synthesis.
 *
 * Format target: {"cardReadings":[{"label":"...","narrative":"..."}],"synthesis":"..."}
 * Fallback 1: format lama masa_lalu/masa_kini/masa_depan/konklusi (dipetakan ke label klasik).
 * Fallback 2: seluruh teks mentah sebagai synthesis.
 */
export interface SynthesisResponse {
	cardReadings: Array<{ label: string; narrative: string }>;
	synthesis: string;
}

export function parseSynthesisResponse(raw: string, labels: string[]): SynthesisResponse {
	const text = raw.trim();

	// Attempt 1: direct JSON parse — format cardReadings + synthesis
	try {
		const parsed = JSON.parse(text) as Partial<SynthesisResponse>;
		if (Array.isArray(parsed.cardReadings) && parsed.cardReadings.length > 0) {
			return {
				cardReadings: parsed.cardReadings
					.filter((r) => r && typeof r.label === 'string' && typeof r.narrative === 'string')
					.map((r) => ({ label: r.label, narrative: r.narrative })),
				synthesis: parsed.synthesis ?? '',
			};
		}
	} catch {
		// fall through
	}

	// Attempt 2: extract JSON object from surrounding text / markdown fences
	try {
		const match = text.match(/\{[\s\S]*\}/);
		if (match) {
			const parsed = JSON.parse(match[0]) as Partial<SynthesisResponse> & Record<string, unknown>;
			if (Array.isArray(parsed.cardReadings) && parsed.cardReadings.length > 0) {
				return {
					cardReadings: parsed.cardReadings
						.filter((r) => r && typeof r.label === 'string' && typeof r.narrative === 'string')
						.map((r) => ({ label: r.label, narrative: r.narrative })),
					synthesis: parsed.synthesis ?? '',
				};
			}
		}
	} catch {
		// fall through
	}

	// Attempt 3: legacy format masa_lalu/masa_kini/masa_depan/konklusi
	try {
		const match = text.match(/\{[\s\S]*\}/);
		if (match) {
			const parsed = JSON.parse(match[0]) as Record<string, unknown>;
			const legacyMap: Record<string, string> = {
				past: String(parsed.masa_lalu ?? ''),
				present: String(parsed.masa_kini ?? ''),
				future: String(parsed.masa_depan ?? ''),
			};
			const konklusi = String(parsed.konklusi ?? '');
			const cardReadings = labels
				.filter((l) => legacyMap[l])
				.map((l) => ({ label: l, narrative: legacyMap[l] }));
			if (cardReadings.length > 0 || konklusi) {
				return {
					cardReadings,
					synthesis: konklusi,
				};
			}
		}
	} catch {
		// fall through
	}

	// Attempt 4: raw text fallback
	return { cardReadings: [], synthesis: text };
}

/**
 * Backward-compatible wrapper: parse legacy 3-position format.
 */
export function parseTarotResponse(raw: string): TarotOracleResponse {
	const text = raw.trim();

	// Attempt 1: direct JSON parse
	try {
		const parsed = JSON.parse(text) as TarotOracleResponse;
		if (parsed.masa_lalu && parsed.masa_kini && parsed.masa_depan && parsed.konklusi) {
			return parsed;
		}
	} catch {
		// fall through to next attempt
	}

	// Attempt 2: extract JSON object from surrounding text / markdown fences
	try {
		const match = text.match(/\{[\s\S]*\}/);
		if (match) {
			const parsed = JSON.parse(match[0]) as Partial<TarotOracleResponse>;
			return {
				masa_lalu: parsed.masa_lalu ?? '',
				masa_kini: parsed.masa_kini ?? '',
				masa_depan: parsed.masa_depan ?? '',
				konklusi: parsed.konklusi ?? text,
			};
		}
	} catch {
		// fall through to fallback
	}

	// Attempt 3: return raw text as konklusi (partial reading still useful)
	return {
		masa_lalu: '',
		masa_kini: '',
		masa_depan: '',
		konklusi: text,
	};
}
