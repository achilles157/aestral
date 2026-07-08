import { parseAuthHeader, verifyFirebaseJwt, type AuthToken } from './auth';
import { getDeterministicThreeCards, getMangsaDeterministicThreeCards } from './tarot';
import { getWetonInsight, getPranataMangsaId, getJamInsight, checkIsDinoWas, dateToJdn, calculateTotalNeptu } from './weton';
import { calculateBaziChart, calculateLuckPillars, type BaziChartResult } from './bazi';
import { callGemini } from './gemini';
import { buildSystemInstruction, type AiContext } from './system_prompt';
import { isRateLimited, getRateLimitResetSeconds } from './rate_limiter';
import { buildTarotSystemInstruction, buildTarotUserPrompt, parseTarotResponse, type TarotCardInput, type TarotReadingContext } from './tarot_reading_prompt';
import MANGSA_THEMES from './data/mangsa-themes.json';
import COMPATIBILITY_DATA from './data/kamus-kompatibilitas-pasangan.json';

// Maps Pancasuda sisa_bagi result to planner label category (see assets/weton/kamus-label-planner.json)
const PLANNER_LABEL_MAP: Record<number, string> = {
	0: 'restorasi',
	1: 'ekspansi',
	2: 'stabil',
	3: 'ekspansi',
	4: 'restorasi',
};

const CORS_HEADERS: Record<string, string> = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function json(data: unknown, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
	});
}

/**
 * Parses and validates the Authorization header.
 *
 * - Missing / malformed header → 401
 * - Bearer tokens: validates JWT expiry + Firebase iss/aud/sub claims → 401/403
 * - Guest tokens: accepted as-is (limited feature set enforced per handler)
 *
 * Returns `{ authToken }` on success, or an error `Response` to short-circuit.
 */
async function requireAuth(
	authHeader: string | null,
	env: Env,
): Promise<{ authToken: AuthToken } | Response> {
	const authToken = parseAuthHeader(authHeader);
	if (!authToken) {
		return json({ error: 'Authorization header diperlukan' }, 401);
	}
	if (authToken.type === 'bearer') {
		const err = await verifyFirebaseJwt(authToken.value, env.FIREBASE_PROJECT_ID, env.RATE_LIMIT_KV);
		if (err) return json({ error: err.error }, err.status);
	}
	return { authToken };
}

export async function handleRequest(request: Request, env: Env): Promise<Response> {
	const url = new URL(request.url);
	const { pathname } = url;
	const method = request.method;

	// CORS preflight
	if (method === 'OPTIONS') {
		return new Response(null, { status: 204, headers: CORS_HEADERS });
	}

	// Routes
	if (method === 'GET' && pathname === '/api/health') {
		return json({ status: 'ok', version: '0.1.0' });
	}

	if (method === 'POST' && pathname === '/api/tarot/draw') {
		return handleTarotDraw(request, env);
	}

	if (method === 'POST' && pathname === '/api/weton/daily') {
		return handleWetonDaily(request, env);
	}

	if (method === 'POST' && pathname === '/api/calendar/month') {
		return handleCalendarMonth(request, env);
	}

	if (method === 'POST' && pathname === '/api/chat') {
		return handleChat(request, env);
	}

	if (method === 'POST' && pathname === '/api/tarot/reading') {
		return handleTarotReading(request, env);
	}

	if (method === 'POST' && pathname === '/api/bazi/chart') {
		return handleBaziChart(request, env);
	}

	if (method === 'POST' && pathname === '/api/bazi/luck-pillars') {
		return handleBaziLuckPillars(request, env);
	}

	if (method === 'POST' && pathname === '/api/bazi/insight') {
		return handleBaziInsight(request, env);
	}

	if (method === 'POST' && pathname === '/api/weton/compatibility') {
		return handleWetonCompatibility(request, env);
	}

	return json({ error: 'Not Found' }, 404);
}

// --- Tarot Draw Handler ---

interface TarotDrawBody {
	birthDate?: string;
	pangarasan?: string;
	drawType?: 'birth' | 'mangsa';
	mangsaId?: number;
}

async function handleTarotDraw(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	let body: TarotDrawBody;
	try {
		body = (await request.json()) as TarotDrawBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required' }, 400);
	}

	const drawType = body.drawType ?? (authToken.type === 'guest' ? 'birth' : 'mangsa');

	if (authToken.type === 'guest' || drawType === 'birth') {
		const cards = getDeterministicThreeCards(body.birthDate, body.pangarasan);
		return json({
			success: true,
			isDynamic: false,
			drawType: 'birth',
			cards,
			message: 'Tebaran 3 Kartu Tarot (Masa Lalu, Masa Kini, Masa Depan) berhasil diselaraskan.',
		});
	}

	// Cosmic cycle draw — default for registered users
	if (!body.mangsaId || body.mangsaId < 1 || body.mangsaId > 12) {
			return json({ error: 'mangsaId (1–12) diperlukan untuk tebaran kosmis' }, 400);
		}
		const cards = getMangsaDeterministicThreeCards(body.birthDate, body.mangsaId, body.pangarasan);
		return json({
			success: true,
			isDynamic: true,
			drawType: 'mangsa',
			cards,
			message: 'Tebaran 3 Kartu Tarot mengikuti siklus kosmis yang sedang berlangsung.',
		});
}

// --- Weton Daily Handler ---

interface WetonDailyBody {
	birthDate?: string;
	targetDate?: string;
}

async function handleWetonDaily(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	let body: WetonDailyBody;
	try {
		body = (await request.json()) as WetonDailyBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required' }, 400);
	}

	const { birthDate, targetDate } = body;

	if (authToken.type === 'guest') {
		const data = getWetonInsight(birthDate, birthDate);
		return json({
			success: true,
			isDynamic: false,
			data,
		});
	}

	// Bearer (registered user)
	const target = targetDate || new Date().toISOString().split('T')[0];
	const data = getWetonInsight(birthDate, target);
	return json({
		success: true,
		isDynamic: true,
		data,
	});
}

// --- Calendar Month Handler ---

interface CalendarMonthBody {
	birthDate?: string;
	targetYear?: number;
	targetMonth?: number;
}

async function handleCalendarMonth(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	let body: CalendarMonthBody;
	try {
		body = (await request.json()) as CalendarMonthBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !body.targetYear || !body.targetMonth) {
		return json({ error: 'birthDate, targetYear, and targetMonth are required' }, 400);
	}

	const { birthDate, targetYear, targetMonth } = body;

	// Calculate active Pranata Mangsa of the selected month (using 15th as midpoint representation)
	const midPranataId = getPranataMangsaId(targetYear, targetMonth, 15);
	// Source of truth: src/data/mangsa-themes.json (array index = id - 1)
	const theme = MANGSA_THEMES[midPranataId - 1];

	// Determine total days in target month
	const totalDays = new Date(targetYear, targetMonth, 0).getDate();

	const daysList = [];

	for (let d = 1; d <= totalDays; d++) {
		const dateStr = `${targetYear}-${targetMonth.toString().padStart(2, '0')}-${d.toString().padStart(2, '0')}`;

		const insight   = getWetonInsight(birthDate, dateStr);
		const isDinoWas = checkIsDinoWas(birthDate, dateStr);

		const sisaBagiVal = insight.daily.sisaBagi;
		let vibeWarna = 'blue';
		let saranSingkat = '';
		let tingkatEnergi = 'Stabil';

		switch (sisaBagiVal) {
			case 1:
				vibeWarna = 'blue';
				tingkatEnergi = 'Tinggi';
				saranSingkat = 'Hari baik untuk bersosialisasi dan memperkuat branding diri.';
				break;
			case 2:
				vibeWarna = 'green';
				tingkatEnergi = 'Stabil';
				saranSingkat = 'Sangat bagus untuk transaksi bisnis, belajar, dan melatih fokus.';
				break;
			case 3:
				vibeWarna = 'gold';
				tingkatEnergi = 'Tinggi';
				saranSingkat = 'Ideal untuk memulai kebiasaan baru atau investasi jangka panjang.';
				break;
			case 4:
				vibeWarna = 'orange';
				tingkatEnergi = 'Waspada';
				saranSingkat = 'Energi tubuh menurun. Tidur cukup dan hindari kelelahan fisik.';
				break;
			case 0:
				vibeWarna = 'purple';
				tingkatEnergi = 'Waspada';
				saranSingkat = 'Momen refleksi batin. Tunda keputusan penting, hindari konfrontasi.';
				break;
		}

		// Map timetable from jamBaik & jamNaas
		const jamBaikParsed = insight.daily.jamBaik.map(item => {
			const match = item.match(/^([\d: -]+)\s*\(([^)]+)\)$/);
			const range = match ? match[1].trim() : '06:00 - 08:24';
			const label = match ? match[2].trim() : 'Jam Rahayu';
			
			let rekomendasi = 'Energi hari ini kondusif, saatnya bergerak maju dengan percaya diri.';
			if (label.includes('Rezeki')) {
				rekomendasi = 'Waktunya bersinar! Waktu terbaik buat pitching ide, nego gaji/proyek, atau bikin deal finansial penting.';
			} else if (label.includes('Gedhong')) {
				rekomendasi = 'Saatnya menata aset. Sangat cocok untuk investasi, tanda tangan kontrak, atau merapikan workspace.';
			}
			return { range, label, rekomendasi };
		});

		const jamNaasParsed = insight.daily.jamNaas.map(item => {
			const match = item.match(/^([\d: -]+)\s*\(([^)]+)\)$/);
			const range = match ? match[1].trim() : '08:24 - 10:48';
			const label = match ? match[2].trim() : 'Jam Waspada';
			
			let rekomendasi = 'Fase energi rawan, luangkan waktu sejenak untuk menenangkan diri.';
			if (label.includes('Loro')) {
				rekomendasi = 'Jeda dulu. Fase ini bikin gampang capek. Hindari meeting tegang, ambil minum, dan luruskan punggung.';
			} else if (label.includes('Pati')) {
				rekomendasi = 'Fase pelepasan ego. Tunda peluncuran penting atau keputusan krusial. Fokus evaluasi mandiri atau istirahat total.';
			}
			return { range, label, rekomendasi };
		});

		daysList.push({
			date: dateStr,
			weton_hari_ini: `${insight.targetWeton.saptawara} ${insight.targetWeton.pancawara}`,
			wuku: insight.targetWeton.wuku,
			neptu: insight.targetWeton.totalNeptu,
			// Dino Was overrides Pancasuda in the planner hierarchy (Primbon Betaljemur Adammakna)
			is_dino_was: isDinoWas,
			pancasuda: {
				sisa_bagi: sisaBagiVal,
				fase: insight.daily.fase,
				tingkat_energi: tingkatEnergi,
				vibe_warna: vibeWarna,
				saran_singkat: saranSingkat,
				planner_label: isDinoWas ? 'restorasi' : (PLANNER_LABEL_MAP[sisaBagiVal] ?? 'stabil'),
			},
			timetable: {
				jam_baik: jamBaikParsed,
				jam_naas: jamNaasParsed,
			}
		});
	}

	return json({
		target_year: targetYear,
		target_month: targetMonth,
		pranata_mangsa: {
			id: midPranataId,
			nama_mangsa: theme.nama,
			candra: theme.candra,
			tema_makro: theme.tema,
		},
		days: daysList,
	});
}

// --- AI Chat Handler ---

interface ChatBody {
	prompt: string;
	wetonLahir?: {
		nama: string;
		neptu: number;
		elemen: string;
		karakter?: string;
	};
	wukuBerjalan?: {
		nama: string;
		elemen: string;
		dewaPenaung?: string;
		pesanKesadaran?: string;
	};
	pranataMangsa?: {
		nama: string;
		arketipe: string;
		karakterEnergi?: string;
		pesanKesadaran?: string;
	};
	tarotCards?: Array<{
		name: string;
		element: string;
		meaning: string;
		label: 'past' | 'present' | 'future';
		isReversed?: boolean;
	}>;
	pangarasan?: string;
}

// Rate limit: 5 requests per minute per IP
const CHAT_RATE_LIMIT_MAX = 5;
const CHAT_RATE_LIMIT_WINDOW_MS = 60_000;

async function handleChat(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	// Extract client IP from Cloudflare header
	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';

	// Check rate limit (now async with KV)
	if (await isRateLimited(clientIp, CHAT_RATE_LIMIT_MAX, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(
			JSON.stringify({
				error: 'Terlalu banyak pertanyaan. Kosmis butuh waktu untuk bernafas. Coba lagi dalam beberapa saat.',
				retryAfterSeconds: resetSeconds,
			}),
			{
				status: 429,
				headers: {
					'Content-Type': 'application/json',
					'Retry-After': String(resetSeconds),
					...CORS_HEADERS,
				},
			},
		);
	}

	// Parse body
	let body: ChatBody;
	try {
		body = (await request.json()) as ChatBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.prompt || body.prompt.trim().length === 0) {
		return json({ error: 'prompt is required' }, 400);
	}

	if (body.prompt.trim().length > 500) {
		return json({ error: 'prompt terlalu panjang (maksimal 500 karakter)' }, 400);
	}

	// Check Gemini API key is configured
	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	// Build AI context from request body
	const aiContext: AiContext = {
		wetonLahir: body.wetonLahir,
		wukuBerjalan: body.wukuBerjalan,
		pranataMangsa: body.pranataMangsa,
		tarotCards: body.tarotCards,
		pangarasan: body.pangarasan,
	};

	// Build system instruction and call Gemini
	try {
		const systemInstruction = buildSystemInstruction(aiContext);
		const aiResponse = await callGemini(systemInstruction, body.prompt.trim(), apiKey);
		return json({ success: true, response: aiResponse });
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Terjadi kesalahan pada orakel kosmis.';
		return json({ error: message }, 500);
	}
}

// --- Tarot Oracle Reading Handler ---

interface TarotReadingBody {
	cards?: TarotCardInput[];
	wetonLahir?: TarotReadingContext['wetonLahir'];
	wukuBerjalan?: TarotReadingContext['wukuBerjalan'];
}

async function handleTarotReading(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';
	if (await isRateLimited(clientIp, CHAT_RATE_LIMIT_MAX, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(
			JSON.stringify({
				error: 'Terlalu banyak permintaan. Orakel sedang beristirahat sejenak.',
				retryAfterSeconds: resetSeconds,
			}),
			{
				status: 429,
				headers: {
					'Content-Type': 'application/json',
					'Retry-After': String(resetSeconds),
					...CORS_HEADERS,
				},
			},
		);
	}

	let body: TarotReadingBody;
	try {
		body = (await request.json()) as TarotReadingBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.cards || !Array.isArray(body.cards) || body.cards.length !== 3) {
		return json({ error: 'cards harus berupa array 3 kartu (past, present, future)' }, 400);
	}

	for (const card of body.cards) {
		if (!card.label || !card.nameId || typeof card.isReversed !== 'boolean') {
			return json({ error: 'Setiap kartu harus memiliki label, nameId, dan isReversed' }, 400);
		}
	}

	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	const context: TarotReadingContext = {
		wetonLahir: body.wetonLahir,
		wukuBerjalan: body.wukuBerjalan,
	};

	try {
		const systemInstruction = buildTarotSystemInstruction(context);
		const userPrompt = buildTarotUserPrompt(body.cards);
		const rawResponse = await callGemini(systemInstruction, userPrompt, apiKey);
		const reading = parseTarotResponse(rawResponse);

		return json({
			success: true,
			cardReadings: [
				{ label: 'past', narrative: reading.masa_lalu },
				{ label: 'present', narrative: reading.masa_kini },
				{ label: 'future', narrative: reading.masa_depan },
			],
			synthesis: reading.konklusi,
		});
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Terjadi kesalahan pada orakel tarot.';
		return json({ error: message }, 500);
	}
}

// --- Weton Compatibility Handler ---

interface WetonCompatibilityBody {
	birthDate1?: string;
	birthDate2?: string;
}

interface CompatibilityEntry {
	sisa_bagi: number;
	nama_tradisional: string;
	arketipe_relasi: string;
	dinamika_psikologis: string;
	potensi_gesekan: string;
	saran_komunikasi: string;
	ai_hook: string;
}

async function handleWetonCompatibility(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	// Kompatibilitas hanya untuk registered user
	if (authToken.type === 'guest') {
		return json({ error: 'Fitur kompatibilitas pasangan memerlukan akun terdaftar.' }, 403);
	}

	let body: WetonCompatibilityBody;
	try {
		body = (await request.json()) as WetonCompatibilityBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate1 || !body.birthDate2) {
		return json({ error: 'birthDate1 dan birthDate2 diperlukan (format: YYYY-MM-DD)' }, 400);
	}

	const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
	if (!dateRegex.test(body.birthDate1) || !dateRegex.test(body.birthDate2)) {
		return json({ error: 'Format tanggal harus YYYY-MM-DD' }, 400);
	}

	try {
		const [y1, m1, d1] = body.birthDate1.split('-').map(Number);
		const [y2, m2, d2] = body.birthDate2.split('-').map(Number);
		const jdn1 = dateToJdn(y1, m1, d1);
		const jdn2 = dateToJdn(y2, m2, d2);
		const neptu1 = calculateTotalNeptu(jdn1);
		const neptu2 = calculateTotalNeptu(jdn2);

		// Modulo 8: hasil 0 = Pesthi (sisa_bagi: 0 di JSON)
		const sisaBagi = (neptu1 + neptu2) % 8;

		const entry = (COMPATIBILITY_DATA as CompatibilityEntry[]).find(
			(e) => e.sisa_bagi === sisaBagi,
		);

		if (!entry) {
			return json({ error: 'Data kompatibilitas tidak ditemukan untuk sisa bagi ini.' }, 500);
		}

		return json({
			success: true,
			data: {
				neptu1,
				neptu2,
				sisa_bagi: sisaBagi,
				nama_fase: entry.nama_tradisional,
				arketipe_relasi: entry.arketipe_relasi,
				dinamika_psikologis: entry.dinamika_psikologis,
				potensi_gesekan: entry.potensi_gesekan,
				saran_komunikasi: entry.saran_komunikasi,
				ai_hook: entry.ai_hook,
			},
		});
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Gagal menghitung kompatibilitas.';
		return json({ error: message }, 500);
	}
}

// --- Ba Zi Chart Handler ---

interface BaziChartBody {
	birthDate?: string;
	birthHour?: number;
	latitude?: number;
	longitude?: number;
}

async function handleBaziChart(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	let body: BaziChartBody;
	try {
		body = (await request.json()) as BaziChartBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required (format: YYYY-MM-DD)' }, 400);
	}

	// Validate date format
	if (!/^\d{4}-\d{2}-\d{2}$/.test(body.birthDate)) {
		return json({ error: 'birthDate must be in YYYY-MM-DD format' }, 400);
	}

	// Validate optional hour
	if (body.birthHour !== undefined && (body.birthHour < 0 || body.birthHour > 23)) {
		return json({ error: 'birthHour must be between 0 and 23' }, 400);
	}

	try {
		const result: BaziChartResult = calculateBaziChart(
			body.birthDate,
			body.birthHour,
			body.latitude,
			body.longitude,
		);

		return json({
			success: true,
			isDynamic: authToken.type !== 'guest',
			data: result,
		});
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Gagal menghitung peta Ba Zi.';
		return json({ error: message }, 500);
	}
}

// --- Ba Zi Luck Pillars Handler ---

interface BaziLuckPillarsBody extends BaziChartBody {
	isMale?: boolean;
}

async function handleBaziLuckPillars(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	// Luck Pillars requires registered user (gender is personal data)
	if (authToken.type === 'guest') {
		return json({ error: 'Da Yun membutuhkan akun terdaftar' }, 403);
	}

	let body: BaziLuckPillarsBody;
	try {
		body = (await request.json()) as BaziLuckPillarsBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required (format: YYYY-MM-DD)' }, 400);
	}

	if (!/^\d{4}-\d{2}-\d{2}$/.test(body.birthDate)) {
		return json({ error: 'birthDate must be in YYYY-MM-DD format' }, 400);
	}

	if (body.isMale === undefined || body.isMale === null) {
		return json({ error: 'isMale is required for Da Yun calculation' }, 400);
	}

	try {
		const chart = calculateBaziChart(
			body.birthDate,
			body.birthHour,
			body.latitude,
			body.longitude,
		);

		const result = calculateLuckPillars(
			body.birthDate,
			chart.monthPillar,
			chart.yearPillar.stemIndex,
			body.isMale,
		);

		return json({
			success: true,
			pillars:   result.pillars,
			isForward: result.isForward,
			startAge:  result.startAge,
		});
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Gagal menghitung Da Yun.';
		return json({ error: message }, 500);
	}
}

// --- Ba Zi Insight Handler ---

interface BaziInsightBody extends BaziChartBody {
	prompt?: string;
	/** Optional Day Master arketipe label from 10day-masters.json */
	dayMasterArketipe?: string;
	/** Required for Da Yun active pillar context */
	isMale?: boolean;
	/** Current age of the user — used to find active Da Yun pillar */
	currentAge?: number;
}

async function handleBaziInsight(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';
	if (await isRateLimited(clientIp, CHAT_RATE_LIMIT_MAX, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(
			JSON.stringify({
				error: 'Terlalu banyak pertanyaan. Orakel kosmis sedang beristirahat.',
				retryAfterSeconds: resetSeconds,
			}),
			{
				status: 429,
				headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS },
			},
		);
	}

	let body: BaziInsightBody;
	try {
		body = (await request.json()) as BaziInsightBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required (format: YYYY-MM-DD)' }, 400);
	}

	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	try {
		const chart: BaziChartResult = calculateBaziChart(
			body.birthDate,
			body.birthHour,
			body.latitude,
			body.longitude,
		);

		// Format pillar strings for AI context
		const formatPillar = (p: BaziChartResult['yearPillar']) =>
			`${p.stemNameId} ${p.branchZodiacId} (${p.stemSymbol}${p.branchSymbol} — ${p.id})`;

		const { kayu, api, tanah, logam, air } = chart.wuXingBalance;
		const wuXingStr = `Kayu:${kayu} Api:${api} Tanah:${tanah} Logam:${logam} Air:${air}`;

		const arketipe = body.dayMasterArketipe ?? chart.dayMasterElement;
		const polarity = chart.dayPillar.stemIndex % 2 === 0 ? 'Yang' : 'Yin';
		const dayMasterLabel = `${chart.dayMasterId.charAt(0).toUpperCase() + chart.dayMasterId.slice(1)} — ${chart.dayMasterElement.charAt(0).toUpperCase() + chart.dayMasterElement.slice(1)} ${polarity} — ${arketipe}`;

		// Format Ten Gods as readable string for AI context
		const tg = chart.tenGods;
		const tenGodsStr = [
			`Tahun: ${tg.year}`,
			`Bulan: ${tg.month}`,
			tg.hour ? `Jam: ${tg.hour}` : null,
		].filter(Boolean).join(' | ');

		// Format Day Master Strength for AI context
		const dmStr = chart.dmStrength;
		const dmStrengthStr = `${dmStr.label} | Yong Shen: ${dmStr.yongShen.join(', ')} | Ji Shen: ${dmStr.jiShen.join(', ')}`;

		// Format Da Yun aktif for AI context (if isMale + currentAge provided)
		let daYunAktif: string | undefined;
		if (body.isMale !== undefined && body.currentAge !== undefined) {
			const lp = calculateLuckPillars(
				body.birthDate,
				chart.monthPillar,
				chart.yearPillar.stemIndex,
				body.isMale,
			);
			const active = lp.pillars.find(
				p => body.currentAge! >= p.startAge && body.currentAge! <= p.endAge,
			);
			if (active) {
				daYunAktif =
					`${active.pillar.stemNameId} ${active.pillar.branchZodiacId} ` +
					`(${active.pillar.stemSymbol}${active.pillar.branchSymbol}) — ` +
					`usia ${active.startAge}–${active.endAge}`;
			}
		}

		const aiContext: AiContext = {
			baziChart: {
				yearPillar:     formatPillar(chart.yearPillar),
				monthPillar:    formatPillar(chart.monthPillar),
				dayPillar:      formatPillar(chart.dayPillar),
				hourPillar:     chart.hourPillar ? formatPillar(chart.hourPillar) : null,
				dayMasterId:    chart.dayMasterId,
				dayMasterLabel,
				wuXingBalance:  wuXingStr,
				tenGods:        tenGodsStr,
				dmStrength:     dmStrengthStr,
				daYunAktif,
			},
		};

		const userPrompt = body.prompt?.trim() ||
			`Bacakan peta kosmis Ba Zi saya. Fokus pada Day Master saya dan apa yang perlu saya sadari tentang diri sendiri.`;

		const systemInstruction = buildSystemInstruction(aiContext);
		const aiResponse = await callGemini(systemInstruction, userPrompt, apiKey);

		return json({
			success: true,
			chart,
			response: aiResponse,
			trueSolarTimeNote: chart.trueSolarTimeNote,
		});
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Terjadi kesalahan pada orakel Ba Zi.';
		return json({ error: message }, 500);
	}
}
