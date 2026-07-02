import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

describe('Astrological Calendar API Endpoint', () => {
	it('returns 400 when Authorization header is missing', async () => {
		const res = await SELF.fetch('http://localhost/api/calendar/month', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				birthDate: '1995-10-25',
				targetYear: 2026,
				targetMonth: 7,
			}),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('Authorization');
	});

	it('returns 400 when parameters are missing', async () => {
		const res = await SELF.fetch('http://localhost/api/calendar/month', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest user_123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				targetYear: 2026,
			}),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('required');
	});

	it('calculates calendar month correctly for July 2026 (Kasa)', async () => {
		const res = await SELF.fetch('http://localhost/api/calendar/month', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest user_123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				targetYear: 2026,
				targetMonth: 7,
			}),
		});
		expect(res.status).toBe(200);
		
		const body = await res.json<{
			target_year: number;
			target_month: number;
			pranata_mangsa: { id: number; nama_mangsa: string; candra: string; tema_makro: string };
			days: Array<{
				date: string;
				weton_hari_ini: string;
				wuku: string;
				neptu: number;
				pancasuda: { sisa_bagi: number; fase: string; tingkat_energi: string; vibe_warna: string; saran_singkat: string };
				timetable: {
					jam_baik: Array<{ range: string; label: string; rekomendasi: string }>;
					jam_naas: Array<{ range: string; label: string; rekomendasi: string }>;
				}
			}>;
		}>();

		expect(body.target_year).toBe(2026);
		expect(body.target_month).toBe(7);
		expect(body.pranata_mangsa.nama_mangsa).toBe('Kasa');
		expect(body.pranata_mangsa.id).toBe(1);

		// July has 31 days
		expect(body.days.length).toBe(31);

		const firstDay = body.days[0];
		expect(firstDay.date).toBe('2026-07-01');
		expect(firstDay.weton_hari_ini).toBeDefined();
		expect(firstDay.wuku).toBeDefined();
		expect(firstDay.pancasuda.vibe_warna).toBeDefined();

		// Verify timetable structure
		expect(firstDay.timetable.jam_baik.length).toBeGreaterThan(0);
		expect(firstDay.timetable.jam_naas.length).toBeGreaterThan(0);
		expect(firstDay.timetable.jam_baik[0].range).toBeTypeOf('string');
		expect(firstDay.timetable.jam_baik[0].label).toBeTypeOf('string');
		expect(firstDay.timetable.jam_baik[0].rekomendasi).toBeTypeOf('string');
	});

	it('handles February leap years correctly (29 days in 2024)', async () => {
		const res = await SELF.fetch('http://localhost/api/calendar/month', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest user_123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				targetYear: 2024,
				targetMonth: 2,
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{ days: Array<any> }>();
		expect(body.days.length).toBe(29);
	});

	it('handles February non-leap years correctly (28 days in 2023)', async () => {
		const res = await SELF.fetch('http://localhost/api/calendar/month', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest user_123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				targetYear: 2023,
				targetMonth: 2,
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{ days: Array<any> }>();
		expect(body.days.length).toBe(28);
	});
});
