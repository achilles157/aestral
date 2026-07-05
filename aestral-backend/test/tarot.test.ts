import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import { getDeterministicThreeCards, getWeeklyDeterministicThreeCards } from '../src/tarot';

// --- Unit Tests: unique deterministic cards ---

describe('getDeterministicThreeCards', () => {
	it('always returns the same three cards for the same birthDate', () => {
		const a = getDeterministicThreeCards('1995-10-25');
		const b = getDeterministicThreeCards('1995-10-25');
		expect(a).toEqual(b);
	});

	it('returns different cards for different birthDates', () => {
		const a = getDeterministicThreeCards('1995-10-25');
		const b = getDeterministicThreeCards('2000-01-01');
		expect(a).not.toEqual(b);
	});

	it('returns three unique card indexes', () => {
		const cards = getDeterministicThreeCards('1995-10-25');
		expect(cards).toHaveLength(3);
		
		const idxs = cards.map(c => c.cardIndex);
		const uniqueIdxs = new Set(idxs);
		expect(uniqueIdxs.size).toBe(3);
		
		for (const card of cards) {
			expect(card.cardIndex).toBeGreaterThanOrEqual(0);
			expect(card.cardIndex).toBeLessThanOrEqual(77);
			expect(card.isReversed).toBeTypeOf('boolean');
		}
		expect(cards[0].label).toBe('past');
		expect(cards[1].label).toBe('present');
		expect(cards[2].label).toBe('future');
	});
});

describe('getWeeklyDeterministicThreeCards', () => {
	it('returns three unique card indexes and is deterministic', () => {
		const a = getWeeklyDeterministicThreeCards('1995-10-25', 'Sinta', 'Geni Jaya');
		const b = getWeeklyDeterministicThreeCards('1995-10-25', 'Sinta', 'Geni Jaya');
		expect(a).toEqual(b);
		
		expect(a).toHaveLength(3);
		const idxs = a.map(c => c.cardIndex);
		const uniqueIdxs = new Set(idxs);
		expect(uniqueIdxs.size).toBe(3);
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
			cards: Array<{ cardIndex: number; isReversed: boolean; label: string }>;
			message: string;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(false);
		expect(body.cards).toHaveLength(3);
		
		const uniqueIdxs = new Set(body.cards.map(c => c.cardIndex));
		expect(uniqueIdxs.size).toBe(3);
		expect(body.cards[0].label).toBe('past');
	});

	it('returns isDynamic: false and drawType: birth for Bearer auth with drawType birth', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/draw', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Bearer fake-jwt-token',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				drawType: 'birth',
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			drawType: string;
			cards: Array<{ cardIndex: number; isReversed: boolean; label: string }>;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(false);
		expect(body.drawType).toBe('birth');
		expect(body.cards).toHaveLength(3);
		expect(body.cards[0].cardIndex).toBe(getDeterministicThreeCards('1995-10-25')[0].cardIndex);
	});

	it('returns isDynamic: true and drawType: weekly for Bearer auth', async () => {
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
				drawType: 'weekly',
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			drawType: string;
			cards: Array<{ cardIndex: number; isReversed: boolean; label: string }>;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(true);
		expect(body.drawType).toBe('weekly');
		expect(body.cards).toHaveLength(3);
		const uniqueIdxs = new Set(body.cards.map(c => c.cardIndex));
		expect(uniqueIdxs.size).toBe(3);
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
