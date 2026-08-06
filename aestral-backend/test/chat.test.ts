import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

const CHAT_URL = 'http://localhost/api/chat';
const GUEST_AUTH = 'Guest test-user-123';

describe('POST /api/chat', () => {
	it('returns 400 when Authorization header is missing', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ prompt: 'Apa arti weton saya?' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('Authorization');
	});

	it('returns 400 when prompt is missing', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({}),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('prompt');
	});

	it('returns 400 when prompt is empty string', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: '   ' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('prompt');
	});

	it('returns 400 when prompt exceeds 4000 characters', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: 'a'.repeat(4001) }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('4000');
	});

	it('returns 400 for invalid JSON body', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: 'not-valid-json',
		});
		expect(res.status).toBe(400);
	});

	it('returns 200 when API configured, or 503/500 if not', async () => {
		const res = await SELF.fetch(CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: 'Apa pengaruh weton saya hari ini?' }),
		});
		// 200 = API key configured + Gemini responded successfully
		// 503 = API key is placeholder, 500 = Gemini error
		expect([200, 503, 500]).toContain(res.status);
	});

	it('returns 429 when rate limit is exceeded', async () => {
		const rateLimitIp = '203.0.113.1'; // TEST-NET IP, unique per this test
		const makeRequest = () =>
			SELF.fetch(CHAT_URL, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: GUEST_AUTH,
					'CF-Connecting-IP': rateLimitIp,
				},
				body: JSON.stringify({ prompt: 'Test rate limit message' }),
			});

		// Send 5 requests to exhaust the limit (they'll hit 503 for API key, not error out)
		for (let i = 0; i < 5; i++) {
			await makeRequest();
		}

		// 6th request should be rate limited
		const res = await makeRequest();
		expect(res.status).toBe(429);
		const body = await res.json<{ error: string; retryAfterSeconds: number }>();
		expect(body.error).toBeTruthy();
		expect(body.retryAfterSeconds).toBeGreaterThan(0);
	}, 45_000);

	it('returns CORS headers on OPTIONS preflight', async () => {
		const res = await SELF.fetch(CHAT_URL, { method: 'OPTIONS' });
		expect(res.status).toBe(204);
		expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
	});
});
