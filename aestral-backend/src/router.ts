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

export function handleRequest(request: Request): Response {
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
		return json({ success: true, endpoint: 'tarot-draw' });
	}

	if (method === 'POST' && pathname === '/api/weton/daily') {
		return json({ success: true, endpoint: 'weton-daily' });
	}

	return json({ error: 'Not Found' }, 404);
}
