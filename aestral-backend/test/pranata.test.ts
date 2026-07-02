import { describe, it, expect } from 'vitest';
import { getPranataMangsaId } from '../src/weton';

describe('Pranata Mangsa Calculation Engine', () => {
	it('correctly maps transition boundary dates', () => {
		// Mangsa 1 - Kasa: 22 June - 1 August
		expect(getPranataMangsaId(2023, 6, 22)).toBe(1);
		expect(getPranataMangsaId(2023, 8, 1)).toBe(1);

		// Mangsa 2 - Karo: 2 August - 24 August
		expect(getPranataMangsaId(2023, 8, 2)).toBe(2);
		expect(getPranataMangsaId(2023, 8, 24)).toBe(2);

		// Mangsa 3 - Katiga: 25 August - 17 September
		expect(getPranataMangsaId(2023, 8, 25)).toBe(3);
		expect(getPranataMangsaId(2023, 9, 17)).toBe(3);

		// Mangsa 4 - Kapat: 18 September - 12 October
		expect(getPranataMangsaId(2023, 9, 18)).toBe(4);
		expect(getPranataMangsaId(2023, 10, 12)).toBe(4);

		// Mangsa 5 - Kalima: 13 October - 8 November
		expect(getPranataMangsaId(2023, 10, 13)).toBe(5);
		expect(getPranataMangsaId(2023, 11, 8)).toBe(5);

		// Mangsa 6 - Kanem: 9 November - 21 December
		expect(getPranataMangsaId(2023, 11, 9)).toBe(6);
		expect(getPranataMangsaId(2023, 12, 21)).toBe(6);

		// Mangsa 7 - Kapitu: 22 December - 2 February
		expect(getPranataMangsaId(2023, 12, 22)).toBe(7);
		expect(getPranataMangsaId(2023, 1, 1)).toBe(7);
		expect(getPranataMangsaId(2023, 2, 2)).toBe(7);

		// Mangsa 8 - Kawolu: 3 February - 28/29 February
		expect(getPranataMangsaId(2023, 2, 3)).toBe(8);

		// Mangsa 9 - Kasanga: 1 March - 25 March
		expect(getPranataMangsaId(2023, 3, 1)).toBe(9);
		expect(getPranataMangsaId(2023, 3, 25)).toBe(9);

		// Mangsa 10 - Kasepuluh: 26 March - 18 April
		expect(getPranataMangsaId(2023, 3, 26)).toBe(10);
		expect(getPranataMangsaId(2023, 4, 18)).toBe(10);

		// Mangsa 11 - Dhesta: 19 April - 11 May
		expect(getPranataMangsaId(2023, 4, 19)).toBe(11);
		expect(getPranataMangsaId(2023, 5, 11)).toBe(11);

		// Mangsa 12 - Sada: 12 May - 21 June
		expect(getPranataMangsaId(2023, 5, 12)).toBe(12);
		expect(getPranataMangsaId(2023, 6, 21)).toBe(12);
	});

	it('correctly handles leap year (wastu) boundary in February', () => {
		// Leap Year (2024): Kawolu (8) ends on Feb 29, Kasanga (9) starts March 1
		expect(getPranataMangsaId(2024, 2, 28)).toBe(8);
		expect(getPranataMangsaId(2024, 2, 29)).toBe(8);
		expect(getPranataMangsaId(2024, 3, 1)).toBe(9);

		// Non-Leap Year (2023): Kawolu (8) ends on Feb 28, Kasanga (9) starts March 1
		expect(getPranataMangsaId(2023, 2, 28)).toBe(8);
		expect(getPranataMangsaId(2023, 3, 1)).toBe(9);
	});
});
