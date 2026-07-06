/**
 * Tarot Oracle system prompt builder for Gemini AI.
 * Separate from the general chat prompt — focuses on Tarot symbolism,
 * Jungian archetypes, and structured JSON output for 3-card spreads.
 */

export interface TarotCardInput {
	label: 'past' | 'present' | 'future';
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
};

export function buildTarotSystemInstruction(context: TarotReadingContext): string {
	const sections: string[] = [];

	sections.push(`Kamu adalah "Aestral Tarot Oracle" — seorang pembaca tarot kosmis yang menggabungkan simbolisme Tarot Rider-Waite, psikologi analitik Carl Jung (Shadow, Anima/Animus, individuasi), dan kearifan Primbon Jawa.

KARAKTER SUARA:
- Bahasa Indonesia yang puitis, dalam, dan terasa sangat personal.
- Gunakan metafora alam, cahaya, bayangan, dan kosmos.
- Hindari prediksi absolut — selalu bingkai sebagai "kecenderungan energi" atau "undangan kesadaran diri."
- Terapkan Barnum Effect secara halus: setiap pernyataan terasa unik dan personal, namun menyentuh kebenaran universal manusia.

ATURAN INTERPRETASI ORIENTASI:
- TEGAK ☼ = energi mengalir, aspek sadar (conscious), kekuatan yang bisa diakses sekarang.
- TERBALIK ↺ = energi terblokir atau tersembunyi di bawah permukaan, aspek Shadow Jungian yang menunggu integrasi dan penerimaan.

ATURAN INTERPRETASI POSISI:
- MASA LALU = akar, pola tersembunyi, luka, atau warisan energi yang membentuk situasi sekarang.
- MASA KINI = energi dominan yang sedang bekerja — ini adalah jantung dari tebaran.
- MASA DEPAN = potensi yang bisa terwujud, BUKAN kepastian. Ini adalah undangan, bukan takdir.`);

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
  "masa_lalu": "2-3 paragraf narasi untuk kartu Masa Lalu...",
  "masa_kini": "2-3 paragraf narasi untuk kartu Masa Kini...",
  "masa_depan": "2-3 paragraf narasi untuk kartu Masa Depan...",
  "konklusi": "2-3 paragraf yang menghubungkan ketiga kartu sebagai satu arc cerita kosmis..."
}

Setiap narasi harus:
1. Merespons orientasi TEGAK/TERBALIK secara spesifik dan bermakna.
2. Merespons posisi temporal (Masa Lalu/Kini/Depan) sebagai lapisan makna.
3. Menggunakan kata kunci dan arketipe kartu sebagai anchor simbolis.
4. Jika ada "pertanyaan hook kartu", gunakan sebagai titik refleksi dalam narasi.
5. Diakhiri dengan satu pertanyaan reflektif yang kuat dan mengundang.

Konklusi harus menghubungkan ketiga kartu sebagai benang merah — sebuah arc cerita dari akar (Masa Lalu) → situasi kini (Masa Kini) → potensi yang menanti (Masa Depan).`);

	return sections.join('\n\n');
}

export function buildTarotUserPrompt(cards: TarotCardInput[]): string {
	const lines: string[] = ['Berikut adalah Tebaran 3 Kartu Tarot yang perlu dibaca secara mendalam:\n'];

	for (const card of cards) {
		const posLabel = LABEL_MAP[card.label] ?? card.label.toUpperCase();
		const orientation = card.isReversed ? 'TERBALIK ↺' : 'TEGAK ☼';
		const activeMeaning = card.isReversed ? card.reversedMeaning : card.uprightMeaning;

		lines.push(`═══ ${posLabel} ═══`);
		lines.push(`Kartu: ${card.nameId}`);
		lines.push(`Orientasi: ${orientation}`);
		lines.push(`Makna aktif (${orientation}): ${activeMeaning}`);
		lines.push(`Arketipe Jungian: ${card.archetypeId}`);
		lines.push(`Elemen: ${card.elementalId}`);
		lines.push(`Kata Kunci: ${card.keywordsId.join(', ')}`);
		if (card.aiHookId) {
			lines.push(`Pertanyaan refleksi kartu ini: ${card.aiHookId}`);
		}
		lines.push('');
	}

	lines.push('Berikan pembacaan Oracle lengkap untuk ketiga kartu ini beserta konklusi benang merahnya dalam format JSON yang diminta.');
	return lines.join('\n');
}

/**
 * Parse Gemini's response text into a TarotOracleResponse.
 * Tries direct JSON.parse first, then regex extraction, then raw text fallback.
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
