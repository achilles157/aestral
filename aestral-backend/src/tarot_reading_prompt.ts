/**
 * Tarot Oracle system prompt builder for Gemini AI.
 * Separate from the general chat prompt — focuses on personal, accessible
 * Barnum-effect narratives grounded in Tarot symbolism and Primbon Jawa context.
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
		lines.push(`Arketipe: ${card.archetypeId}`);
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
