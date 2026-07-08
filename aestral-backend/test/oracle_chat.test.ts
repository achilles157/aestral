import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

const ORACLE_CHAT_URL = 'http://localhost/api/oracle/chat';
const GUEST_AUTH = 'Guest test-user-123';

describe('POST /api/oracle/chat', () => {
	it('returns 400 when Authorization header is missing', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ prompt: 'Halo Ki Sabdo' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('Authorization');
	});

	it('returns 400 when prompt is missing', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ oracleType: 'weton' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('prompt');
	});

	it('returns 400 when prompt is empty string', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: '   ', oracleType: 'weton' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('prompt');
	});

	it('returns 400 when prompt exceeds 600 characters', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: 'a'.repeat(601), oracleType: 'weton' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('600');
	});

	it('returns 400 when oracleType is invalid', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({ prompt: 'Halo', oracleType: 'invalid-type' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('oracleType');
	});

	it('returns 200 when API configured, or 503/500 if not', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Apa arti weton lahir saya?',
				oracleType: 'weton',
				context: {
					wetonLahir: {
						nama: 'Minggu Legi',
						neptu: 10,
						elemen: 'Kayu',
						karakter: 'Sabar, tekun, ulet',
					},
				},
			}),
		});
		// 200 = API key configured + Gemini structured output responded successfully
		// 503 = API key is placeholder, 500 = Gemini error
		expect([200, 503, 500]).toContain(res.status);
	});

	it('returns 429 when rate limit is exceeded', async () => {
		const rateLimitIp = '203.0.113.2'; // Unique test-net IP for this test
		const makeRequest = () =>
			SELF.fetch(ORACLE_CHAT_URL, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: GUEST_AUTH,
					'CF-Connecting-IP': rateLimitIp,
				},
				body: JSON.stringify({ prompt: 'Test rate limit message', oracleType: 'weton' }),
			});

		// Exhaust rate limit
		for (let i = 0; i < 5; i++) {
			await makeRequest();
		}

		const res = await makeRequest();
		expect(res.status).toBe(429);
		const body = await res.json<{ error: string; retryAfterSeconds: number }>();
		expect(body.error).toBeTruthy();
		expect(body.retryAfterSeconds).toBeGreaterThan(0);
	}, 45_000);

	it('accepts all 4 valid oracle types without 400', async () => {
		const types = ['weton', 'bazi', 'tarot', 'synthesis'];
		for (const oracleType of types) {
			const res = await SELF.fetch(ORACLE_CHAT_URL, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: GUEST_AUTH,
				},
				body: JSON.stringify({ prompt: 'Halo Oracle', oracleType }),
			});
			expect([200, 503, 500]).toContain(res.status);
		}
	}, 30_000);

	it('accepts session metadata fields (isFirstOpen, daysSinceLastOpen, lastTopic)', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Apa yang perlu kuketahui hari ini?',
				oracleType: 'weton',
				isFirstOpen: false,
				daysSinceLastOpen: 3,
				lastTopic: 'Karier & Rezeki',
			}),
		});
		expect([200, 503, 500]).toContain(res.status);
	});

	it('accepts chatHistory for multi-turn conversation', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Lanjutkan — ceritakan lebih dalam.',
				oracleType: 'weton',
				chatHistory: [
					{ role: 'user', parts: [{ text: 'Halo Ki Sabdo' }] },
					{ role: 'model', parts: [{ text: 'Rahayu. Apa yang ingin kamu selaraskan?' }] },
				],
			}),
		});
		expect([200, 503, 500]).toContain(res.status);
	});

	it('response has message field when status is 200', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Bagaimana energiku hari ini?',
				oracleType: 'weton',
				context: {
					wetonLahir: { nama: 'Senin Pon', neptu: 12, elemen: 'Air', karakter: 'Tenang' },
				},
			}),
		});
		if (res.status === 200) {
			const body = await res.json<{ message: string; card?: unknown }>();
			expect(typeof body.message).toBe('string');
			expect(body.message.length).toBeGreaterThan(0);
		} else {
			expect([503, 500]).toContain(res.status);
		}
	});

	it('accepts synthesis oracle with multi-system context', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Apa benang merah dari semua sistemku?',
				oracleType: 'synthesis',
				context: {
					wetonLahir: { nama: 'Minggu Legi', neptu: 10 },
					baziChart: { dayMasterId: 'jia', dayMasterElement: 'kayu' },
					tarotCards: [{ name: 'The Sun', label: 'present', isReversed: false }],
				},
			}),
		});
		expect([200, 503, 500]).toContain(res.status);
	});

	it('accepts compatibility and plannerHour context fields', async () => {
		const res = await SELF.fetch(ORACLE_CHAT_URL, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: GUEST_AUTH,
			},
			body: JSON.stringify({
				prompt: 'Bagaimana kecocokan kami?',
				oracleType: 'weton',
				context: {
					wetonLahir: { neptu: 12 },
					compatibility: {
						neptu1: 12,
						neptu2: 8,
						namaFase: 'Mawolu',
						arketipeRelasi: 'Dinamis',
						dinamikaPsikologis: 'Saling melengkapi',
						potensiGesekan: 'Perbedaan tempo',
						saranKomunikasi: 'Jujur dan terbuka',
					},
					plannerHour: { label: 'Saat Pandita', range: '06:00–08:00' },
				},
			}),
		});
		expect([200, 503, 500]).toContain(res.status);
	});
});
