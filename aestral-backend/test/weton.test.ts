import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import {
	dateToJdn,
	getSaptawara,
	getPancawara,
	getWuku,
	calculateTotalNeptu,
	calculateSisaBagi,
	getWetonInsight,
} from '../src/weton';

describe('Weton Calculation Engine (Unit Tests)', () => {
	it('dateToJdn returns correct JDN for known dates', () => {
		// 2000-01-01 = JDN 2451545
		expect(dateToJdn(2000, 1, 1)).toBe(2451545);
		// 1995-10-25 = JDN 2450016
		expect(dateToJdn(1995, 10, 25)).toBe(2450016);
		// 1995-10-21 = JDN 2450012
		expect(dateToJdn(1995, 10, 21)).toBe(2450012);
	});

	it('getSaptawara and getPancawara return correct day/pasaran for known dates', () => {
		// 1995-10-25 is Wednesday (Rabu) Pahing
		const jdnWed = dateToJdn(1995, 10, 25);
		const saptaWed = getSaptawara(jdnWed);
		const pancaWed = getPancawara(jdnWed);
		expect(saptaWed.name).toBe('Rabu');
		expect(saptaWed.neptu).toBe(7);
		expect(pancaWed.name).toBe('Pahing');
		expect(pancaWed.neptu).toBe(9);

		// 1995-10-21 is Saturday (Sabtu) Pon
		const jdnSat = dateToJdn(1995, 10, 21);
		const saptaSat = getSaptawara(jdnSat);
		const pancaSat = getPancawara(jdnSat);
		expect(saptaSat.name).toBe('Sabtu');
		expect(saptaSat.neptu).toBe(9);
		expect(pancaSat.name).toBe('Pon');
		expect(pancaSat.neptu).toBe(7);
	});

	it('getWuku returns correct wuku', () => {
		// 1995-10-21 = JDN 2450012 should be Wuku Sinta
		const jdnSat = dateToJdn(1995, 10, 21);
		const wSat = getWuku(jdnSat);
		expect(wSat.index).toBe(0);
		expect(wSat.name).toBe('Sinta');

		// 1995-10-25 = JDN 2450016 should be Wuku Landep (index 1)
		const jdnWed = dateToJdn(1995, 10, 25);
		const wWed = getWuku(jdnWed);
		expect(wWed.index).toBe(1);
		expect(wWed.name).toBe('Landep');
	});

	it('calculateTotalNeptu returns correct neptu sum', () => {
		const jdnSat = dateToJdn(1995, 10, 21); // Sabtu (9) + Pon (7) = 16
		expect(calculateTotalNeptu(jdnSat)).toBe(16);

		const jdnWed = dateToJdn(1995, 10, 25); // Rabu (7) + Pahing (9) = 16
		expect(calculateTotalNeptu(jdnWed)).toBe(16);
	});

	it('calculateSisaBagi returns value 0-4', () => {
		const jdn1 = dateToJdn(1995, 10, 21);
		const jdn2 = dateToJdn(2026, 6, 30);
		const sisa = calculateSisaBagi(jdn1, jdn2);
		expect(sisa).toBeGreaterThanOrEqual(0);
		expect(sisa).toBeLessThanOrEqual(4);
	});

	it('getWetonInsight returns correct structure', () => {
		// Using 1995-10-21 (Sabtu Pon, neptu 16, Sinta)
		// and 2000-01-01 (Sabtu Kliwon, neptu 17, Kuningan)
		const insight = getWetonInsight('1995-10-21', '2000-01-01');
		expect(insight.birthWeton).toEqual({
			saptawara: 'Sabtu',
			pancawara: 'Pon',
			totalNeptu: 16,
			wuku: 'Sinta',
			pranataMangsaId: 5,
		});
		expect(insight.targetWeton.saptawara).toBe('Sabtu');
		expect(insight.targetWeton.pancawara).toBe('Legi');
		expect(insight.targetWeton.totalNeptu).toBe(14);
		expect(insight.targetWeton.wuku).toBe('Sungsang');
		expect(insight.targetWeton.pranataMangsaId).toBe(7);
		expect(insight.daily.sisaBagi).toBe((16 + 14) % 5);
		expect(insight.daily.fase).toBeDefined();
		expect(insight.daily.statusHari).toBeTypeOf('string');
		expect(insight.daily.hariBaik).toBeTypeOf('boolean');
		expect(insight.daily.hariNaasLahir).toBe('Sabtu Pon');
		expect(insight.daily.jamBaik).toBeInstanceOf(Array);
		expect(insight.daily.jamNaas).toBeInstanceOf(Array);
		expect(insight.weekly.wukuIndex).toBe(9); // Sungsang is index 9
		expect(insight.weekly.wukuName).toBe('Sungsang');
	});
});

describe('Weton daily insight API (Integration Tests)', () => {
	it('POST /api/weton/daily with Guest auth returns isDynamic: false', async () => {
		const res = await SELF.fetch('http://localhost/api/weton/daily', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest anon-123',
			},
			body: JSON.stringify({ birthDate: '1995-10-21' }),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			data: any;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(false);
		expect(body.data.birthWeton.saptawara).toBe('Sabtu');
		expect(body.data.birthWeton.pancawara).toBe('Pon');
	});

	it('POST /api/weton/daily with Bearer auth returns isDynamic: true', async () => {
		const res = await SELF.fetch('http://localhost/api/weton/daily', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Bearer fake-jwt-token',
			},
			body: JSON.stringify({
				birthDate: '1995-10-21',
				targetDate: '2026-06-30',
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			isDynamic: boolean;
			data: any;
		}>();
		expect(body.success).toBe(true);
		expect(body.isDynamic).toBe(true);
		expect(body.data.birthWeton.saptawara).toBe('Sabtu');
		expect(body.data.birthWeton.pancawara).toBe('Pon');
		expect(body.data.targetWeton).toBeDefined();
	});

	it('POST /api/weton/daily with no auth returns 400', async () => {
		const res = await SELF.fetch('http://localhost/api/weton/daily', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify({ birthDate: '1995-10-21' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('Authorization');
	});

	it('POST /api/weton/daily with missing birthDate returns 400', async () => {
		const res = await SELF.fetch('http://localhost/api/weton/daily', {
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
