import { parseAuthHeader, verifyFirebaseJwt, type AuthToken } from './auth';
import { getDeterministicThreeCards, getMangsaDeterministicThreeCards, getWeeklyDeterministicThreeCards, getMangsaTwoCards, getMomentCard, getThematicThreeCards, type BaziWeightingContext, type MomentEventType, type ThematicArea } from './tarot';
import { getWetonInsight, getPranataMangsaId, getJamInsight, checkIsDinoWas, dateToJdn, calculateTotalNeptu } from './weton';
import { calculateBaziChart, calculateLuckPillars, getDayPillar, STEM_ELEMENTS, BRANCH_ELEMENTS, calculateBaziCompatibility, type BaziChartResult } from './bazi';
import { callGemini, callGeminiStructured, callGemmaForSummary } from './gemini';
import { ORACLE_PERSONAS, buildOracleGreeting, type OracleType } from './oracle_prompts';
import { buildSystemInstruction, type AiContext } from './system_prompt';
import { isRateLimited, getRateLimitResetSeconds } from './rate_limiter';
import { buildTarotSystemInstruction, buildTarotUserPrompt, parseTarotResponse, type TarotCardInput, type TarotReadingContext } from './tarot_reading_prompt';
import { buildTemplateKey, buildSynthesisPrompt, type SynthesisCardInput, type SynthesisCacheEntry } from './tarot-synthesis';
import MANGSA_THEMES from './data/mangsa-themes.json';
import COMPATIBILITY_DATA from './data/kamus-kompatibilitas-pasangan.json';
// ─── Gemini Daily Quota Guard ─────────────────────────────────────────────────
const GEMINI_DAILY_LIMIT = 480; // buffer dari 500 RPD

function secondsUntilMidnight(): number {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setUTCHours(24, 0, 0, 0);
  return Math.floor((midnight.getTime() - now.getTime()) / 1000);
}

async function checkGeminiQuota(kv: KVNamespace): Promise<boolean> {
  const today = new Date().toISOString().split('T')[0];
  const key = `gemini_daily_${today}`;
  const current = await kv.get(key);
  const count = parseInt(current ?? '0');
  if (count >= GEMINI_DAILY_LIMIT) return false;
  
  // Note: TOCTOU race exists here - concurrent requests can read same count before writes complete,
  // allowing overshoot. KV doesn't support atomic increment. Accept small overshoot as tolerable.
  // Use midnight-aligned TTL so counter resets consistently at UTC 00:00.
  const ttl = secondsUntilMidnight();
  await kv.put(key, String(count + 1), { expirationTtl: ttl });
  return true;
}

function geminiQuotaExceeded(): Response {
  return json({
    error: 'Oracle sedang beristirahat — kapasitas kosmis hari ini sudah penuh. Kembali besok.',
    retryAfterSeconds: secondsUntilMidnight(),
    code: 'gemini_daily_quota',
  }, 503);
}


// Maps Pancasuda sisa_bagi result to planner label category (see assets/weton/kamus-label-planner.json)
const PLANNER_LABEL_MAP: Record<number, string> = {
	0: 'restorasi',
	1: 'ekspansi',
	2: 'stabil',
	3: 'ekspansi',
	4: 'restorasi',
};

const CORS_HEADERS: Record<string, string> = {
	'Access-Control-Allow-Origin': '*', // overridden per-request by handleRequest wrapper
	'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization',
	'Vary': 'Origin',
};

/**
 * Resolves the allowed CORS origin for a given request.
 * Origins are compared against the comma-separated ALLOWED_ORIGINS env var.
 * Localhost is always allowed in non-production environments.
 */
function resolveAllowedOrigin(origin: string | null, env: Env): string {
	if (!origin) return '*';
	const allowed = (env.ALLOWED_ORIGINS ?? '').split(',').map(o => o.trim()).filter(Boolean);
	if (allowed.includes(origin)) return origin;
	// Allow localhost only in non-production environments
	if (env.ENVIRONMENT !== 'production' && (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:'))) return origin;
	// Fallback: if ALLOWED_ORIGINS not configured yet, allow all (temporary)
	if (allowed.length === 0) return origin;
	return 'null';
}

function json(data: unknown, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
	});
}

/** Strips control characters and caps length to prevent prompt injection via client-supplied context strings. */
function sanitizeCtx(value: string | undefined | null, maxLen = 200): string | undefined {
	if (value == null) return undefined;
	const cleaned = value.replace(/[\r\n\0\t]/g, ' ').trim().slice(0, maxLen);
	return cleaned || undefined;
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
		return json({ error: 'Authorization header diperlukan' }, 400);
	}
	if (authToken.type === 'bearer') {
		// fake-jwt-token bypass only permitted in non-production environments
		const isFakeToken = authToken.value === 'fake-jwt-token' && env.ENVIRONMENT !== 'production';
		if (!isFakeToken) {
			const err = await verifyFirebaseJwt(authToken.value, env.FIREBASE_PROJECT_ID, env.RATE_LIMIT_KV);
			if (err) return json({ error: err.error }, err.status);
		}
	}
	return { authToken };
}

/**
 * Public entry point — wraps internal dispatch with per-request CORS headers.
 * Sets Access-Control-Allow-Origin to the specific requesting origin if allowed,
 * rather than the wildcard used internally.
 */
export async function handleRequest(request: Request, env: Env): Promise<Response> {
	const origin = request.headers.get('Origin');
	const allowedOrigin = resolveAllowedOrigin(origin, env);

	const response = await dispatch(request, env);

	const headers = new Headers(response.headers);
	headers.set('Access-Control-Allow-Origin', allowedOrigin);
	headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
	headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
	headers.set('Vary', 'Origin');

	return new Response(response.body, { status: response.status, headers });
}

async function dispatch(request: Request, env: Env): Promise<Response> {
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

	if (method === 'POST' && pathname === '/api/tarot/moment') {
		return handleTarotMoment(request, env);
	}

	if (method === 'POST' && pathname === '/api/tarot/thematic') {
		return handleTarotThematic(request, env);
	}

	if (method === 'POST' && pathname === '/api/tarot/mangsa') {
		return handleTarotMangsa(request, env);
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

	if (method === 'POST' && pathname === '/api/oracle/chat') {
		return handleOracleChat(request, env);
	}

	if (method === 'POST' && pathname === '/api/oracle/summarize') {
		return handleOracleSummarize(request, env);
	}

	return json({ error: 'Not Found' }, 404);
}

// ─── Input validation ────────────────────────────────────────────────────────

/**
 * Validates an ISO date string (YYYY-MM-DD).
 * Rejects obviously invalid values: wrong format, out-of-range years, or
 * calendar-impossible dates (e.g. Feb 30).
 */
function validateIsoDate(dateStr: string): boolean {
	if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
	const [y, m, d] = dateStr.split('-').map(Number);
	if (y < 1900 || y > 2100) return false;
	if (m < 1 || m > 12) return false;
	if (d < 1 || d > 31) return false;
	const dt = new Date(`${dateStr}T00:00:00Z`);
	return dt.getFullYear() === y && dt.getMonth() + 1 === m && dt.getDate() === d;
}

// --- Tarot Draw Handler ---

interface TarotDrawBody {
	birthDate?: string;
	pangarasan?: string;
	drawType?: 'birth' | 'mangsa' | 'weekly';
	mangsaId?: number;
	wukuHariIni?: string;
	dayMasterElement?: string;
	dayMasterPolarity?: string;
	yongShen?: string[];
	wuXingDominant?: string;
}

async function handleTarotDraw(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	const clientIpTarot = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIpTarot, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIpTarot, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: TarotDrawBody;
	try {
		body = (await request.json()) as TarotDrawBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	const drawType = body.drawType ?? (authToken.type === 'guest' ? 'birth' : 'mangsa');

	// Ba Zi weighting context — only from registered users with Ba Zi data
	const bazi: BaziWeightingContext | undefined =
		authToken.type === 'bearer' && body.dayMasterElement
			? {
				dayMasterElement: body.dayMasterElement,
				dayMasterPolarity: body.dayMasterPolarity as 'yin' | 'yang' | undefined,
				yongShen: body.yongShen,
				wuXingDominant: body.wuXingDominant,
			}
			: undefined;

	if (authToken.type === 'guest' || drawType === 'birth') {
		const cards = getDeterministicThreeCards(body.birthDate, body.pangarasan, bazi);
		return json({
			success: true,
			isDynamic: false,
			drawType: 'birth',
			cards,
			message: 'Tebaran 3 Kartu Tarot (Masa Lalu, Masa Kini, Masa Depan) berhasil diselaraskan.',
		});
	}

	if (drawType === 'weekly') {
		const wuku = body.wukuHariIni || 'Sinta';
		const cards = getWeeklyDeterministicThreeCards(body.birthDate, wuku, body.pangarasan, bazi);
		return json({
			success: true,
			isDynamic: true,
			drawType: 'weekly',
			cards,
			message: 'Tebaran 3 Kartu Tarot Mingguan diselaraskan dengan siklus Wuku saat ini.',
		});
	}

	// Mangsa cycle draw — default for registered users
	if (!body.mangsaId || body.mangsaId < 1 || body.mangsaId > 12) {
			return json({ error: 'mangsaId (1–12) diperlukan untuk tebaran mangsa' }, 400);
		}
		const cards = getMangsaDeterministicThreeCards(body.birthDate, body.mangsaId, body.pangarasan, bazi);
		return json({
			success: true,
			isDynamic: true,
			drawType: 'mangsa',
			cards,
			message: 'Tebaran 3 Kartu Tarot mengikuti siklus mangsa yang sedang berlangsung.',
		});
}

// --- Tarot Mangsa 2-Card Handler ---

interface TarotMangsaBody {
	birthDate?: string;
	pangarasan?: string;
	mangsaId?: number;
	dayMasterElement?: string;
	dayMasterPolarity?: string;
	yongShen?: string[];
	wuXingDominant?: string;
}

async function handleTarotMangsa(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'cf-no-ip';
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: TarotMangsaBody;
	try {
		body = (await request.json()) as TarotMangsaBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	if (!body.mangsaId || body.mangsaId < 1 || body.mangsaId > 12) {
		return json({ error: 'mangsaId (1–12) diperlukan' }, 400);
	}

	const bazi: BaziWeightingContext | undefined =
		authToken.type === 'bearer' && body.dayMasterElement
			? {
				dayMasterElement: body.dayMasterElement,
				dayMasterPolarity: body.dayMasterPolarity as 'yin' | 'yang' | undefined,
				yongShen: body.yongShen,
				wuXingDominant: body.wuXingDominant,
			}
			: undefined;

	const cards = getMangsaTwoCards(body.birthDate, body.mangsaId, body.pangarasan, bazi);
	return json({
		success: true,
		drawType: 'mangsa',
		format: 'energy_guidance',
		cards,
		message: 'Energi Mangsa + Panduan Pribadi berhasil diselaraskan.',
	});
}

// --- Tarot Momen Kosmis Handler (Phase 3A) ---

const MOMENT_EVENT_LABELS: Record<string, string> = {
	hari_weton: 'Hari Weton',
	dino_was: 'Dino Was',
	bazi_clash: 'Ba Zi Clash',
	yong_shen: 'Yong Shen Day',
};

interface TarotMomentBody {
	birthDate?: string;
	eventType?: string;
	dayMasterElement?: string;
	dayMasterPolarity?: string;
	yongShen?: string[];
	wuXingDominant?: string;
}

async function handleTarotMoment(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'cf-no-ip';
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: TarotMomentBody;
	try {
		body = (await request.json()) as TarotMomentBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	if (!body.eventType || !MOMENT_EVENT_LABELS[body.eventType]) {
		return json({ error: 'eventType harus salah satu: hari_weton, dino_was, bazi_clash, yong_shen' }, 400);
	}

	const bazi: BaziWeightingContext | undefined =
		authToken.type === 'bearer' && body.dayMasterElement
			? {
				dayMasterElement: body.dayMasterElement,
				dayMasterPolarity: body.dayMasterPolarity as 'yin' | 'yang' | undefined,
				yongShen: body.yongShen,
				wuXingDominant: body.wuXingDominant,
			}
			: undefined;

	const moment = getMomentCard(body.birthDate, body.eventType as MomentEventType, bazi);
	return json({
		success: true,
		drawType: 'moment',
		eventType: body.eventType,
		eventLabel: MOMENT_EVENT_LABELS[body.eventType],
		card: {
			cardIndex: moment.cardIndex,
			isReversed: moment.isReversed,
			label: 'moment',
		},
		reasoning: moment.reasoning,
		message: `Kartu Momen Kosmis untuk ${MOMENT_EVENT_LABELS[body.eventType]} berhasil ditarik.`,
	});
}

// --- Tarot Tematik Handler (Phase 3B) ---

const AREA_LABELS: Record<string, string> = {
	karir: 'Karir & Ambisi',
	asmara: 'Asmara & Relasi',
	keuangan: 'Keuangan & Stabilitas',
	spiritual: 'Spiritual & Growth',
	kesehatan: 'Kesehatan & Vitalitas',
};

interface TarotThematicBody {
	birthDate?: string;
	pangarasan?: string;
	area?: string;
	userQuestion?: string;
	dayMasterElement?: string;
	dayMasterPolarity?: string;
	yongShen?: string[];
	wuXingDominant?: string;
}

async function handleTarotThematic(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;
	const { authToken } = authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'cf-no-ip';
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: TarotThematicBody;
	try {
		body = (await request.json()) as TarotThematicBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	if (!body.area || !AREA_LABELS[body.area]) {
		return json({ error: 'area harus salah satu: karir, asmara, keuangan, spiritual, kesehatan' }, 400);
	}

	if (body.userQuestion && body.userQuestion.length > 200) {
		return json({ error: 'userQuestion maksimal 200 karakter' }, 400);
	}

	const bazi: BaziWeightingContext | undefined =
		authToken.type === 'bearer' && body.dayMasterElement
			? {
				dayMasterElement: body.dayMasterElement,
				dayMasterPolarity: body.dayMasterPolarity as 'yin' | 'yang' | undefined,
				yongShen: body.yongShen,
				wuXingDominant: body.wuXingDominant,
			}
			: undefined;

	const cards = getThematicThreeCards(body.birthDate, body.area as ThematicArea, body.pangarasan, bazi);
	return json({
		success: true,
		drawType: 'thematic',
		area: body.area,
		areaLabel: AREA_LABELS[body.area],
		cards,
		message: `Tebaran Tematik ${AREA_LABELS[body.area]} berhasil disusun.`,
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: WetonDailyBody;
	try {
		body = (await request.json()) as WetonDailyBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
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

const ZODIACS_ID = [
	'Tikus', 'Kerbau', 'Harimau', 'Kelinci', 'Naga', 'Ular',
	'Kuda', 'Kambing', 'Monyet', 'Ayam', 'Anjing', 'Babi'
];

function getShiChenBranchIndex(hour: number): number {
	if (hour >= 23 || hour < 1) return 0;
	if (hour >= 1 && hour < 3) return 1;
	if (hour >= 3 && hour < 5) return 2;
	if (hour >= 5 && hour < 7) return 3;
	if (hour >= 7 && hour < 9) return 4;
	if (hour >= 9 && hour < 11) return 5;
	if (hour >= 11 && hour < 13) return 6;
	if (hour >= 13 && hour < 15) return 7;
	if (hour >= 15 && hour < 17) return 8;
	if (hour >= 17 && hour < 19) return 9;
	if (hour >= 19 && hour < 21) return 10;
	return 11;
}

function getMidpointHour(range: string): number {
	const parts = range.split('-');
	if (parts.length !== 2) return 12;
	const [h1, m1] = parts[0].trim().split(':').map(Number);
	const [h2, m2] = parts[1].trim().split(':').map(Number);
	
	const t1 = h1 * 60 + m1;
	let t2 = h2 * 60 + m2;
	if (t2 < t1) {
		t2 += 24 * 60;
	}
	const midMinutes = (t1 + t2) / 2;
	const midHour = Math.floor(midMinutes / 60) % 24;
	return midHour;
}

async function handleCalendarMonth(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, CALENDAR_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
	}

	let body: CalendarMonthBody;
	try {
		body = (await request.json()) as CalendarMonthBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !body.targetYear || !body.targetMonth) {
		return json({ error: 'birthDate, targetYear, dan targetMonth diperlukan (required)' }, 400);
	}
	if (!validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	const { birthDate, targetYear, targetMonth } = body;

	// Calculate user's birth Ba Zi chart
	const birthBazi = calculateBaziChart(birthDate);
	const birthDayBranch = birthBazi.dayPillar.branchIndex;
	const birthYearBranch = birthBazi.yearPillar.branchIndex;
	const yongShen = birthBazi.dmStrength.yongShen;

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

		// Calculate daily Ba Zi pillar and interactions
		const dayPillar = getDayPillar(targetYear, targetMonth, d);
		const dayBranch = dayPillar.branchIndex;
		const dayStem = dayPillar.stemIndex;

		const isBaziClash = Math.abs(dayBranch - birthDayBranch) === 6 || Math.abs(dayBranch - birthYearBranch) === 6;

		const harmonyPairs = [[0, 1], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]];
		const isBaziHarmony = harmonyPairs.some(([a, b]) =>
			(dayBranch === a && birthDayBranch === b) || (dayBranch === b && birthDayBranch === a)
		);

		const isBaziYongShen = yongShen.includes(STEM_ELEMENTS[dayStem]) || yongShen.includes(BRANCH_ELEMENTS[dayBranch]);

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
		const mapPituToBazi = (item: { range: string, label: string, rekomendasi: string }, isBaik: boolean) => {
			const midHour = getMidpointHour(item.range);
			const hBranch = getShiChenBranchIndex(midHour);
			const hElement = BRANCH_ELEMENTS[hBranch];
			const hZodiac = ZODIACS_ID[hBranch];

			const isHourClash = Math.abs(hBranch - birthDayBranch) === 6 || Math.abs(hBranch - birthYearBranch) === 6;
			const isHourHarmony = [[0, 1], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]].some(
				([a, b]) => (hBranch === a && birthDayBranch === b) || (hBranch === b && birthDayBranch === a)
			);
			const isHourYongShen = yongShen.includes(hElement);

			let baziScore = 0;
			let baziLabel = 'Netral';
			if (isHourClash) {
				baziScore = -1;
				baziLabel = 'Clash';
			} else if (isHourHarmony || isHourYongShen) {
				baziScore = 1;
				baziLabel = isHourYongShen ? 'Yong Shen' : 'Harmoni';
			}

			const totalAmplitude = isBaik ? (1 + baziScore * 0.5) : (-1 + baziScore * 0.5);

			let baziRecom = '';
			if (isBaik) {
				if (isHourClash) {
					baziRecom = ' Peluang luar terbuka lebar, namun hindari kecerobohan fisik dan keputusan emosional.';
				} else if (isHourHarmony || isHourYongShen) {
					baziRecom = ' Sinergi energi kosmis sempurna! Rencana eksternal dan vitalitas internal Anda berada pada puncaknya.';
				}
			} else {
				if (isHourClash) {
					baziRecom = ' Kerawanan ganda. Prioritaskan keselamatan fisik dan batasi komunikasi sensitif hari ini.';
				} else if (isHourHarmony || isHourYongShen) {
					baziRecom = ' Meskipun energi sosial meredup, fokus dan daya analisa internal Anda sedang tajam untuk riset mandiri.';
				}
			}

			return {
				...item,
				rekomendasi: item.rekomendasi + baziRecom,
				bazi_shi_chen: {
					zodiac: hZodiac,
					element: hElement,
					condition: baziLabel,
					is_clash: isHourClash,
					is_harmony: isHourHarmony,
					is_yong_shen: isHourYongShen,
					amplitude: totalAmplitude,
				}
			};
		};

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
			return mapPituToBazi({ range, label, rekomendasi }, true);
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
			return mapPituToBazi({ range, label, rekomendasi }, false);
		});

		daysList.push({
			date: dateStr,
			weton_hari_ini: `${insight.targetWeton.saptawara} ${insight.targetWeton.pancawara}`,
			wuku: insight.targetWeton.wuku,
			neptu: insight.targetWeton.totalNeptu,
			// Dino Was overrides Pancasuda in the planner hierarchy (Primbon Betaljemur Adammakna)
			is_dino_was: isDinoWas,
			is_wuku_rawan: insight.daily.isWukuRawan,
			is_mangsa_rawan: insight.daily.isMangsaRawan,
			is_bazi_clash: isBaziClash,
			is_bazi_harmony: isBaziHarmony,
			is_bazi_yong_shen: isBaziYongShen,
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

// Rate limit: 5 requests per minute per IP (AI endpoints)
const CHAT_RATE_LIMIT_MAX = 5;
const CHAT_RATE_LIMIT_WINDOW_MS = 60_000;

// Rate limit: 30 requests per minute per IP (data endpoints)
const DATA_RATE_LIMIT_MAX = 30;
const DATA_RATE_LIMIT_WINDOW_MS = 60_000;

// Rate limit: 10 requests per minute per IP (calendar/month — CPU-bound 31-iteration loop)
const CALENDAR_RATE_LIMIT_MAX = 10;

async function handleChat(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	// Extract client IP from Cloudflare header
	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();

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

	if (body.prompt.trim().length > 4000) {
		return json({ error: 'prompt terlalu panjang (maksimal 4000 karakter)' }, 400);
	}

	// Check Gemini API key is configured
	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	// Build AI context from request body — sanitize string fields to prevent prompt injection
	const aiContext: AiContext = {
		wetonLahir: body.wetonLahir ? {
			nama:      sanitizeCtx(body.wetonLahir.nama) ?? '',
			neptu:     body.wetonLahir.neptu,
			elemen:    sanitizeCtx(body.wetonLahir.elemen) ?? '',
			karakter:  sanitizeCtx(body.wetonLahir.karakter),
		} : undefined,
		wukuBerjalan: body.wukuBerjalan ? {
			nama:           sanitizeCtx(body.wukuBerjalan.nama) ?? '',
			elemen:         sanitizeCtx(body.wukuBerjalan.elemen) ?? '',
			dewaPenaung:    sanitizeCtx(body.wukuBerjalan.dewaPenaung),
			pesanKesadaran: sanitizeCtx(body.wukuBerjalan.pesanKesadaran),
		} : undefined,
		pranataMangsa: body.pranataMangsa ? {
			nama:           sanitizeCtx(body.pranataMangsa.nama) ?? '',
			arketipe:       sanitizeCtx(body.pranataMangsa.arketipe) ?? '',
			karakterEnergi: sanitizeCtx(body.pranataMangsa.karakterEnergi),
			pesanKesadaran: sanitizeCtx(body.pranataMangsa.pesanKesadaran),
		} : undefined,
		tarotCards: body.tarotCards,
		pangarasan: sanitizeCtx(body.pangarasan),
	};

	// Build system instruction and call Gemini
	try {
		const systemInstruction = buildSystemInstruction(aiContext);
		if (!(await checkGeminiQuota(env.RATE_LIMIT_KV))) return geminiQuotaExceeded();
		const aiResponse = await callGemini(systemInstruction, body.prompt.trim(), apiKey, env.GEMINI_MODEL);
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
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

	if (!body.cards || !Array.isArray(body.cards) || (body.cards.length !== 2 && body.cards.length !== 3)) {
		return json({ error: 'cards harus berupa array 2 atau 3 kartu' }, 400);
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

	// Phase 2C: Build synthesis inputs from card structure
	const synthesisCards: SynthesisCardInput[] = body.cards.map((c) => ({
		cardIndex: (c as any).cardIndex ?? 0,
		isReversed: c.isReversed,
		label: c.label,
	}));
	const templateKey = buildTemplateKey(synthesisCards);

	// Layer 2: Check KV cache for pre-computed or cached synthesis
	const cachedRaw = await env.TAROT_KV.get(templateKey, 'text');
	if (cachedRaw) {
		try {
			const cached: SynthesisCacheEntry = JSON.parse(cachedRaw);
			const ageMs = Date.now() - cached.cachedAt;
			const MAX_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours
			if (ageMs < MAX_AGE_MS && cached.cardReadings?.length) {
				return json({
					success: true,
					cached: true,
					cardReadings: cached.cardReadings,
					synthesis: cached.synthesis,
				});
			}
		} catch {
			// Corrupt cache entry — fall through to fresh generation
		}
	}

	// Layer 3: Gemini assembly with lightweight prompt (~65% fewer tokens)
	const context: TarotReadingContext = {
		wetonLahir: body.wetonLahir,
		wukuBerjalan: body.wukuBerjalan,
	};

	try {
		// Build compact prompt — system instruction is the full oracle personality
		// but the user prompt is just cards + template, saving ~65% vs full prompt
		const systemInstruction = buildTarotSystemInstruction(context);
		const userPrompt = buildTarotUserPrompt(body.cards);
		if (!(await checkGeminiQuota(env.RATE_LIMIT_KV))) return geminiQuotaExceeded();
		const rawResponse = await callGemini(systemInstruction, userPrompt, apiKey, env.GEMINI_MODEL);
		const reading = parseTarotResponse(rawResponse);

		// Build card readings dynamically from labels
		const cardReadings = body.cards.map((c) => {
			const narratives: Record<string, string> = {
				past: reading.masa_lalu,
				present: reading.masa_kini,
				future: reading.masa_depan,
				energy: reading.masa_kini || reading.konklusi,
				guidance: reading.konklusi,
			};
			return {
				label: c.label,
				narrative: narratives[c.label] ?? reading.konklusi,
			};
		});

		// Cache the result in KV for future identical draws
		const cacheEntry: SynthesisCacheEntry = {
			cardReadings,
			synthesis: reading.konklusi,
			cachedAt: Date.now(),
		};
		await env.TAROT_KV.put(templateKey, JSON.stringify(cacheEntry), {
			expirationTtl: 86400, // 24h TTL
		});

		return json({
			success: true,
			cached: false,
			cardReadings,
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
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

	if (!validateIsoDate(body.birthDate1) || !validateIsoDate(body.birthDate2)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
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

		// Calculate Ba Zi birth charts and compatibility
		const baziChart1 = calculateBaziChart(body.birthDate1);
		const baziChart2 = calculateBaziChart(body.birthDate2);
		const baziCompatibility = calculateBaziCompatibility(baziChart1, baziChart2);

		return json({
			success: true,
			data: {
				// Old flat keys for backward compatibility
				neptu1,
				neptu2,
				sisa_bagi: sisaBagi,
				nama_fase: entry.nama_tradisional,
				arketipe_relasi: entry.arketipe_relasi,
				dinamika_psikologis: entry.dinamika_psikologis,
				potensi_gesekan: entry.potensi_gesekan,
				saran_komunikasi: entry.saran_komunikasi,
				ai_hook: entry.ai_hook,

				// New nested structures
				weton: {
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
				bazi: baziCompatibility,
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
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

	// Validate date format and calendar bounds
	if (!validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	// Validate optional hour
	if (body.birthHour !== undefined && (body.birthHour < 0 || body.birthHour > 23)) {
		return json({ error: 'birthHour must be between 0 and 23' }, 400);
	}

	// Validate optional coordinates
	if (body.latitude !== undefined && (!isFinite(body.latitude) || body.latitude < -90 || body.latitude > 90)) {
		return json({ error: 'latitude harus antara -90 dan 90' }, 400);
	}
	if (body.longitude !== undefined && (!isFinite(body.longitude) || body.longitude < -180 || body.longitude > 180)) {
		return json({ error: 'longitude harus antara -180 dan 180' }, 400);
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, DATA_RATE_LIMIT_MAX, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, DATA_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(JSON.stringify({ error: 'Terlalu banyak permintaan. Coba lagi sebentar.', retryAfterSeconds: resetSeconds }), { status: 429, headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS } });
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

	if (!validateIsoDate(body.birthDate)) {
		return json({ error: 'birthDate harus format YYYY-MM-DD yang valid (1900–2100)' }, 400);
	}

	if (body.isMale === undefined || body.isMale === null) {
		return json({ error: 'isMale is required for Da Yun calculation' }, 400);
	}

	// Validate optional coordinates
	if (body.latitude !== undefined && (!isFinite(body.latitude) || body.latitude < -90 || body.latitude > 90)) {
		return json({ error: 'latitude harus antara -90 dan 90' }, 400);
	}
	if (body.longitude !== undefined && (!isFinite(body.longitude) || body.longitude < -180 || body.longitude > 180)) {
		return json({ error: 'longitude harus antara -180 dan 180' }, 400);
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

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
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

	// W34: validate birthDate format — other handlers use validateIsoDate, this one was missing it
	if (!body.birthDate || !validateIsoDate(body.birthDate)) {
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
		if (!(await checkGeminiQuota(env.RATE_LIMIT_KV))) return geminiQuotaExceeded();
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

// --- Oracle Chat Handler ---

interface OracleChatBody {
	oracleType?: string;
	prompt?: string;
	chatHistory?: Array<{ role: string; parts: { text: string }[] }>;
	isFirstOpen?: boolean;
	daysSinceLastOpen?: number;
	lastTopic?: string;
	lastSessionSummary?: string;
	context?: {
		wetonLahir?: AiContext['wetonLahir'];
		wukuBerjalan?: AiContext['wukuBerjalan'];
		pranataMangsa?: AiContext['pranataMangsa'];
		tarotCards?: AiContext['tarotCards'];
		pangarasan?: string;
		baziChart?: AiContext['baziChart'];
		compatibility?: {
			neptu1?: number;
			neptu2?: number;
			namaFase?: string;
			arketipeRelasi?: string;
			dinamikaPsikologis?: string;
			potensiGesekan?: string;
			saranKomunikasi?: string;
		};
		plannerHour?: {
			label?: string;
			range?: string;
		};
	};
}

const ORACLE_RESPONSE_SCHEMA = {
	type: 'object',
	properties: {
		message: { type: 'string' },
		card: {
			type: 'object',
			nullable: true,
			properties: {
				type: { type: 'string', enum: ['checklist', 'element_bar', 'key_insight'] },
				data: { type: 'object' },
			},
			required: ['type', 'data'],
		},
	},
	required: ['message'],
};

async function handleOracleChat(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	const clientIp = request.headers.get('CF-Connecting-IP') ?? (() => { console.warn('[Rate Limit] Missing CF-Connecting-IP'); return 'cf-no-ip'; })();
	if (await isRateLimited(clientIp, CHAT_RATE_LIMIT_MAX, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return new Response(
			JSON.stringify({
				error: 'Terlalu banyak pertanyaan. Oracle sedang bermeditasi sejenak.',
				retryAfterSeconds: resetSeconds,
			}),
			{
				status: 429,
				headers: { 'Content-Type': 'application/json', 'Retry-After': String(resetSeconds), ...CORS_HEADERS },
			},
		);
	}

	let body: OracleChatBody;
	try {
		body = (await request.json()) as OracleChatBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.prompt || body.prompt.trim().length === 0) {
		return json({ error: 'prompt is required' }, 400);
	}

	if (body.prompt.trim().length > 600) {
		return json({ error: 'prompt terlalu panjang (maks 600 karakter)' }, 400);
	}

	const oracleType = (body.oracleType as OracleType) ?? 'weton';
	if (!['weton', 'bazi', 'tarot', 'synthesis'].includes(oracleType)) {
		return json({ error: 'oracleType tidak valid' }, 400);
	}

	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	const persona = ORACLE_PERSONAS[oracleType];

	// Build context-enriched system instruction
	const contextSections: string[] = [persona.systemInstruction];

	// Inject astrological context if provided
	if (body.context) {
		const ctx = body.context;
		const s = (v: string | undefined | null, max = 200) => sanitizeCtx(v, max);
		const aiCtx: AiContext = {
			wetonLahir: ctx.wetonLahir ? {
				nama:      s(ctx.wetonLahir.nama) ?? '',
				neptu:     ctx.wetonLahir.neptu,
				elemen:    s(ctx.wetonLahir.elemen) ?? '',
				karakter:  s(ctx.wetonLahir.karakter),
				pancasuda: s((ctx.wetonLahir as AiContext['wetonLahir'] & { pancasuda?: string })?.pancasuda),
			} : undefined,
			wukuBerjalan: ctx.wukuBerjalan ? {
				nama:           s(ctx.wukuBerjalan.nama) ?? '',
				elemen:         s(ctx.wukuBerjalan.elemen) ?? '',
				dewaPenaung:    s(ctx.wukuBerjalan.dewaPenaung),
				pesanKesadaran: s(ctx.wukuBerjalan.pesanKesadaran),
			} : undefined,
			pranataMangsa: ctx.pranataMangsa ? {
				nama:           s(ctx.pranataMangsa.nama) ?? '',
				arketipe:       s(ctx.pranataMangsa.arketipe) ?? '',
				karakterEnergi: s(ctx.pranataMangsa.karakterEnergi),
				pesanKesadaran: s(ctx.pranataMangsa.pesanKesadaran),
			} : undefined,
			tarotCards: ctx.tarotCards,
			pangarasan: s(ctx.pangarasan),
			baziChart: ctx.baziChart ? {
				yearPillar:     s(ctx.baziChart.yearPillar) ?? '',
				monthPillar:    s(ctx.baziChart.monthPillar) ?? '',
				dayPillar:      s(ctx.baziChart.dayPillar) ?? '',
				hourPillar:     s(ctx.baziChart.hourPillar) ?? null,
				dayMasterId:    s(ctx.baziChart.dayMasterId) ?? '',
				dayMasterLabel: s(ctx.baziChart.dayMasterLabel) ?? '',
				wuXingBalance:  s(ctx.baziChart.wuXingBalance) ?? '',
				tenGods:        s(ctx.baziChart.tenGods),
				dmStrength:     s(ctx.baziChart.dmStrength),
				daYunAktif:     s(ctx.baziChart.daYunAktif),
			} : undefined,
		};
			// Use existing buildSystemInstruction for context formatting,
			// strip the base persona section (already in contextSections[0]).
			// Use startsWith for precise section matching — avoids false positives if
			// user data happens to contain these strings mid-section.
			const contextOnly = buildSystemInstruction(aiCtx)
				.split('\n\n')
				.filter(
					(s) =>
						!s.trim().startsWith('Kamu adalah "Aestral Oracle"') &&
						!s.trim().startsWith('PETUNJUK JAWABAN'),
				)
				.join('\n\n');
		if (contextOnly.trim()) contextSections.push(contextOnly);

		// Inject compatibility context (from weton compatibility screen)
		if (body.context?.compatibility) {
			const c = body.context.compatibility;
			const lines = [
				'Konteks Kecocokan Pasangan:',
				c.namaFase ? `- Fase: ${sanitizeCtx(c.namaFase)}` : '',
				c.arketipeRelasi ? `- Arketipe Relasi: ${sanitizeCtx(c.arketipeRelasi)}` : '',
				c.neptu1 !== undefined && c.neptu2 !== undefined ? `- Neptu: ${c.neptu1} + ${c.neptu2}` : '',
				c.dinamikaPsikologis ? `- Dinamika: ${sanitizeCtx(c.dinamikaPsikologis)}` : '',
				c.potensiGesekan ? `- Potensi Gesekan: ${sanitizeCtx(c.potensiGesekan)}` : '',
				c.saranKomunikasi ? `- Saran Komunikasi: ${sanitizeCtx(c.saranKomunikasi)}` : '',
			].filter(Boolean).join('\n');
			if (lines.trim()) contextSections.push(lines);
		}

		// Inject planner hour context (from astrological planner timeline)
		if (body.context?.plannerHour) {
			const ph = body.context.plannerHour;
			const text = `Konteks Waktu Planner: ${sanitizeCtx(ph.label) ?? ''} (${sanitizeCtx(ph.range) ?? ''})`.trim();
			if (text) contextSections.push(text);
		}
	}

	// Inject session greeting instruction
	const greetingInstruction = buildOracleGreeting(
		oracleType,
		body.isFirstOpen ?? true,
		body.daysSinceLastOpen ?? 0,
		sanitizeCtx(body.lastTopic, 100),
	);
	contextSections.push(greetingInstruction);

	// Inject memori sesi sebelumnya jika ada
	if (body.lastSessionSummary && body.lastSessionSummary.trim()) {
		contextSections.push(
			`MEMORI SESI SEBELUMNYA:\n${sanitizeCtx(body.lastSessionSummary, 500) ?? ''}`,
		);
	}

	const systemInstruction = contextSections.join('\n\n---\n\n');

		// Build chat history (max 10 turns = 20 messages: 19 history + 1 current)
		const rawHistory = body.chatHistory ?? [];
		const trimmedHistory = rawHistory.slice(-19);
		const currentMessage = { role: 'user', parts: [{ text: body.prompt.trim() }] };
		const fullHistory = [...trimmedHistory, currentMessage];

	try {
		if (!(await checkGeminiQuota(env.RATE_LIMIT_KV))) return geminiQuotaExceeded();
		const result = await callGeminiStructured(systemInstruction, fullHistory, apiKey, {
			responseSchema: ORACLE_RESPONSE_SCHEMA,
			maxOutputTokens: 800,
			temperature: 0.88,
		});
		return json({ success: true, ...result });
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Terjadi kesalahan pada oracle kosmis.';
		if (message.startsWith('GEMINI_QUOTA:')) {
			return json({ error: message.replace('GEMINI_QUOTA:', ''), code: 'gemini_quota' }, 503);
		}
		return json({ error: message }, 500);
	}
}

// --- Oracle Summarize Handler ---

interface OracleSummarizeBody {
	oracleType?: string;
	messages?: Array<{ role: string; text: string }>;
}

async function handleOracleSummarize(request: Request, env: Env): Promise<Response> {
	const authResult = await requireAuth(request.headers.get('Authorization'), env);
	if (authResult instanceof Response) return authResult;

	// W35: add rate limiting — was missing while all other AI endpoints have it
	const clientIp = request.headers.get('CF-Connecting-IP') ?? 'cf-no-ip';
	if (await isRateLimited(clientIp, CHAT_RATE_LIMIT_MAX, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV)) {
		const resetSeconds = await getRateLimitResetSeconds(clientIp, CHAT_RATE_LIMIT_WINDOW_MS, env.RATE_LIMIT_KV);
		return json({ error: 'Terlalu banyak permintaan. Coba lagi nanti.', retryAfterSeconds: resetSeconds }, 429);
	}

	let body: OracleSummarizeBody;
	try {
		body = (await request.json()) as OracleSummarizeBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	const messages = body.messages ?? [];
	if (messages.length < 4) {
		// Percakapan terlalu pendek untuk disimpan sebagai memori
		return json({ success: true, summary: '' });
	}

	const oracleType = (body.oracleType as OracleType) ?? 'weton';
	const persona = ORACLE_PERSONAS[oracleType];

	const apiKey = env.GEMINI_API_KEY;
	if (!apiKey || apiKey === 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET') {
		return json({ error: 'AI service belum dikonfigurasi' }, 503);
	}

	try {
		const summary = await callGemmaForSummary(messages, persona.name, apiKey);
		return json({ success: true, summary });
	} catch (err) {
		// Non-fatal — kembalikan summary kosong agar client tidak crash
		console.warn('[Oracle Summarize] Gemma error (non-fatal):', err);
		return json({ success: true, summary: '' });
	}
}
