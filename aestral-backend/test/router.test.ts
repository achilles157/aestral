import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

describe('API Router', () => {
	it('GET /api/health returns 200 with status ok', async () => {
		const res = await SELF.fetch('http://localhost/api/health');
		expect(res.status).toBe(200);
		const body = await res.json<{ status: string; version: string }>();
		expect(body.status).toBe('ok');
		expect(body.version).toBe('0.1.0');
	});

	it('POST /api/weton/daily returns 200', async () => {
		const res = await SELF.fetch('http://localhost/api/weton/daily', {
			method: 'POST',
		});
		expect(res.status).toBe(200);
		const body = await res.json<{ success: boolean; endpoint: string }>();
		expect(body.success).toBe(true);
		expect(body.endpoint).toBe('weton-daily');
	});

	it('unknown path returns 404', async () => {
		const res = await SELF.fetch('http://localhost/nope');
		expect(res.status).toBe(404);
	});

	it('OPTIONS returns 204 with CORS headers', async () => {
		const res = await SELF.fetch('http://localhost/api/health', {
			method: 'OPTIONS',
		});
		expect(res.status).toBe(204);
		expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
		expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST');
		expect(res.headers.get('Access-Control-Allow-Headers')).toContain('Authorization');
	});
});
