import { parseAuthHeader } from './auth';
import { getDeterministicThreeCards, getMangsaDeterministicThreeCards } from './tarot';
import { getWetonInsight, getPranataMangsaId, getJamInsight } from './weton';
import { calculateBaziChart, type BaziChartResult } from './bazi';
import { callGemini } from './gemini';
import { buildSystemInstruction, type AiContext } from './system_prompt';
import { isRateLimited, getRateLimitResetSeconds } from './rate_limiter';
import { buildTarotSystemInstruction, buildTarotUserPrompt, parseTarotResponse, type TarotCardInput, type TarotReadingContext } from './tarot_reading_prompt';

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
		return handleTarotDraw(request);
	}

	if (method === 'POST' && pathname === '/api/weton/daily') {
		return handleWetonDaily(request);
	}

	if (method === 'POST' && pathname === '/api/calendar/month') {
		return handleCalendarMonth(request);
	}

	if (method === 'POST' && pathname === '/api/chat') {
		return handleChat(request, env);
	}

	if (method === 'POST' && pathname === '/api/tarot/reading') {
		return handleTarotReading(request, env);
	}

	if (method === 'POST' && pathname === '/api/bazi/chart') {
		return handleBaziChart(request);
	}

	if (method === 'POST' && pathname === '/api/bazi/insight') {
		return handleBaziInsight(request, env);
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

async function handleTarotDraw(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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

async function handleWetonDaily(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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

const MANGSA_THEMES: Record<number, { nama: string; candra: string; tema: string }> = {
	1: { nama: 'Kasa', candra: 'Sotya murca saking embanan', tema: 'Ego-Death & Decluttering' },
	2: { nama: 'Karo', candra: 'Bantala rengka', tema: 'Vulnerability & Resilience' },
	3: { nama: 'Katiga', candra: 'Suta manut ing bapa', tema: 'Mentorship & Disiplin' },
	4: { nama: 'Kapat', candra: 'Waspa kumembeng jroning kalbu', tema: 'Emotional Healing & Transisi' },
	5: { nama: 'Kalima', candra: 'Pancuran mas sumawur ing jagad', tema: 'Abundance & Peluang' },
	6: { nama: 'Kanem', candra: 'Rasa mulya kasucian', tema: 'Maturitas & Flow' },
	7: { nama: 'Kapitu', candra: 'Wisa kentar ing maruta', tema: 'Cozy Cocooning & Boundaries' },
	8: { nama: 'Kawolu', candra: 'Anjrah jroning kayun', tema: 'Passion & Kolaborasi' },
	9: { nama: 'Kasanga', candra: 'Wedharing wacana mulya', tema: 'Ekspresi Diri & Sharing' },
	10: { nama: 'Kadasa', candra: 'Gedhong mineb jroning kalbu', tema: 'Financial & Security' },
	11: { nama: 'Dhesta', candra: 'Sotya sinarawedi', tema: 'Apresiasi & Perlambatan' },
	12: { nama: 'Sada', candra: 'Tirta sah saking sasana', tema: 'Detachment & Refleksi' },
};

async function handleCalendarMonth(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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
	const theme = MANGSA_THEMES[midPranataId];

	// Determine total days in target month
	const totalDays = new Date(targetYear, targetMonth, 0).getDate();

	const daysList = [];

	for (let d = 1; d <= totalDays; d++) {
		const dateStr = `${targetYear}-${targetMonth.toString().padStart(2, '0')}-${d.toString().padStart(2, '0')}`;

		const insight = getWetonInsight(birthDate, dateStr);

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
			pancasuda: {
				sisa_bagi: sisaBagiVal,
				fase: insight.daily.fase,
				tingkat_energi: tingkatEnergi,
				vibe_warna: vibeWarna,
				saran_singkat: saranSingkat,
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
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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

// --- Ba Zi Chart Handler ---

interface BaziChartBody {
	birthDate?: string;
	birthHour?: number;
	latitude?: number;
	longitude?: number;
}

async function handleBaziChart(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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

// --- Ba Zi Insight Handler ---

interface BaziInsightBody extends BaziChartBody {
	prompt?: string;
	/** Optional Day Master arketipe label from 10day-masters.json */
	dayMasterArketipe?: string;
}

async function handleBaziInsight(request: Request, env: Env): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

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

		const aiContext: AiContext = {
			baziChart: {
				yearPillar:     formatPillar(chart.yearPillar),
				monthPillar:    formatPillar(chart.monthPillar),
				dayPillar:      formatPillar(chart.dayPillar),
				hourPillar:     chart.hourPillar ? formatPillar(chart.hourPillar) : null,
				dayMasterId:    chart.dayMasterId,
				dayMasterLabel,
				wuXingBalance:  wuXingStr,
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
