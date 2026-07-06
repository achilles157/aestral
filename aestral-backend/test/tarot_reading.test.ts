import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

const READING_URL = 'http://localhost/api/tarot/reading';
const GUEST_AUTH = 'Guest test-user-456';

const VALID_CARDS = [
	{
		label: 'past',
		nameId: 'Sang Pengelana',
		isReversed: false,
		uprightMeaning: 'Kebebasan, petualangan baru, potensi tak terbatas',
		reversedMeaning: 'Kecerobohan, keputusan impulsif tanpa pertimbangan',
		archetypeId: 'Si Pejalan Bebas',
		elementalId: 'Udara',
		keywordsId: ['kebebasan', 'potensi', 'petualangan'],
		aiHookId: 'Petualangan apa yang baru saja Anda mulai?',
	},
	{
		label: 'present',
		nameId: 'Sang Penyihir',
		isReversed: true,
		uprightMeaning: 'Kemauan, kemampuan, sumber daya tersedia',
		reversedMeaning: 'Manipulasi, bakat tidak digunakan, potensi terkunci',
		archetypeId: 'Sang Pencipta',
		elementalId: 'Api',
		keywordsId: ['kemauan', 'kemampuan', 'manifestasi'],
		aiHookId: 'Potensi apa yang sedang terblokir dalam diri Anda?',
	},
	{
		label: 'future',
		nameId: 'Bintang',
		isReversed: false,
		uprightMeaning: 'Harapan, inspirasi, ketenangan setelah badai',
		reversedMeaning: 'Keputusasaan, kehilangan harapan, ketidakpercayaan diri',
		archetypeId: 'Sang Pemimpi',
		elementalId: 'Air',
		keywordsId: ['harapan', 'inspirasi', 'penyembuhan'],
		aiHookId: 'Bintang apa yang sedang Anda ikuti?',
	},
];

describe('POST /api/tarot/reading', () => {
	it('returns 400 when Authorization header is missing', async () => {
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ cards: VALID_CARDS }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('Authorization');
	});

	it('returns 400 when cards array is missing', async () => {
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: GUEST_AUTH },
			body: JSON.stringify({}),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('cards');
	});

	it('returns 400 when cards array has wrong length', async () => {
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: GUEST_AUTH },
			body: JSON.stringify({ cards: [VALID_CARDS[0]] }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('3');
	});

	it('returns 400 when a card is missing required fields', async () => {
		const badCards = [
			{ label: 'past', nameId: 'Test' }, // missing isReversed
			VALID_CARDS[1],
			VALID_CARDS[2],
		];
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: GUEST_AUTH },
			body: JSON.stringify({ cards: badCards }),
		});
		expect(res.status).toBe(400);
	});

	it('returns 400 for invalid JSON body', async () => {
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: GUEST_AUTH },
			body: 'invalid-json',
		});
		expect(res.status).toBe(400);
	});

	it('returns 200 when API configured, or 503/500 if not', async () => {
		const res = await SELF.fetch(READING_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: GUEST_AUTH },
			body: JSON.stringify({ cards: VALID_CARDS }),
		});
		// 200 = API key configured + Gemini responded successfully
		// 503 = API key is placeholder, 500 = Gemini error
		expect([200, 503, 500]).toContain(res.status);
	});

	it('returns 429 when rate limit is exceeded', async () => {
		const rateLimitIp = '198.51.100.1';
		const makeRequest = () =>
			SELF.fetch(READING_URL, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: GUEST_AUTH,
					'CF-Connecting-IP': rateLimitIp,
				},
				body: JSON.stringify({ cards: VALID_CARDS }),
			});

		for (let i = 0; i < 5; i++) {
			await makeRequest();
		}

		const res = await makeRequest();
		expect(res.status).toBe(429);
		const body = await res.json<{ retryAfterSeconds: number }>();
		expect(body.retryAfterSeconds).toBeGreaterThan(0);
	}, 45_000);

	it('returns CORS headers on OPTIONS preflight', async () => {
		const res = await SELF.fetch(READING_URL, { method: 'OPTIONS' });
		expect(res.status).toBe(204);
		expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
	});
});
