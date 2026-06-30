import { parseAuthHeader } from './auth';
import { getDeterministicCard, getWeightedRandomCard } from './tarot';
import { getWetonInsight } from './weton';

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

export async function handleRequest(request: Request): Promise<Response> {
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

	return json({ error: 'Not Found' }, 404);
}

// --- Tarot Draw Handler ---

interface TarotDrawBody {
	birthDate?: string;
	pangarasan?: string;
	wukuHariIni?: string;
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

	if (authToken.type === 'guest') {
		const cardIndex = getDeterministicCard(body.birthDate);
		return json({
			success: true,
			isDynamic: false,
			cardIndex,
			message: 'Kartu Jiwa (Soul Card) — daftar untuk pembacaan harian dinamis.',
		});
	}

	// Bearer (registered user)
	const cardIndex = getWeightedRandomCard(
		body.pangarasan ?? '',
		body.wukuHariIni ?? '',
	);
	return json({ success: true, isDynamic: true, cardIndex });
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
