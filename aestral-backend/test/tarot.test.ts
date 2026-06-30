import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import { getDeterministicCard, getWeightedRandomCard } from '../src/tarot';

// --- Unit Tests: getDeterministicCard ---

describe('getDeterministicCard', () => {
	it('always returns the same index for the same birthDate', () => {
		const a = getDeterministicCard('1995-10-25');
		const b = getDeterministicCard('1995-10-25');
		const c = getDeterministicCard('1995-10-25');
		expect(a).toBe(b);
		expect(b).toBe(c);
	});

	it('returns different indices for different birthDates', () => {
		const a = getDeterministicCard('1995-10-25');
		const b = getDeterministicCard('2000-01-01');
		expect(a).not.toBe(b);
	});

	it('returns a value in range 0-77', () => {
		const dates = [
			'1990-01-01',
			'1995-10-25',
			'2000-12-31',
			'1985-06-15',
			'2010-03-08',
		];
		for (const d of dates) {
			const idx = getDeterministicCard(d);
			expect(idx).toBeGreaterThanOrEqual(0);
			expect(idx).toBeLessThanOrEqual(77);
		}
	});
});

// --- Unit Tests: getWeightedRandomCard ---

describe('getWeightedRandomCard', () => {
	it('returns a value in range 0-77', () => {
		for (let i = 0; i < 50; i++) {
			const idx = getWeightedRandomCard('Geni Jaya', 'Sinta');
			expect(idx).toBeGreaterThanOrEqual(0);
			expect(idx).toBeLessThanOrEqual(77);
		}
	});
});

// --- Integration Tests: POST /api/tarot/draw ---

describe('POST /api/tarot/draw', () => {
	it('returns isDynamic: false for Guest auth', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/draw', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest anon-123',
			},
			body: JSON.stringify({ birthDate: '1995-10-25' }),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			cardIndex: number;
			message: string;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(false);
		expect(body.cardIndex).toBeGreaterThanOrEqual(0);
		expect(body.cardIndex).toBeLessThanOrEqual(77);
		expect(body.message).toContain('Kartu Jiwa');
	});

	it('returns isDynamic: true for Bearer auth', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/draw', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Bearer fake-jwt-token',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				pangarasan: 'Geni Jaya',
				wukuHariIni: 'Sinta',
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			cardIndex: number;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(true);
		expect(body.cardIndex).toBeGreaterThanOrEqual(0);
		expect(body.cardIndex).toBeLessThanOrEqual(77);
	});

	it('returns 400 when no Authorization header', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/draw', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ birthDate: '1995-10-25' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toBeTruthy();
	});

	it('returns 400 when birthDate is missing', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/draw', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest anon-123',
			},
			body: JSON.stringify({}),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('birthDate');
	});
});
