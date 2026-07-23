/**
 * Unit tests for Ba Zi computation logic.
 *
 * Tests use direct function imports (not HTTP SELF.fetch) because:
 *   1. `calculateLuckPillars` requires registered auth — not testable via HTTP in test env
 *   2. Direct import is more appropriate for pure computation unit tests
 *   3. Faster (no HTTP round-trip)
 */

import { describe, it, expect } from 'vitest';
import { calculateBaziChart, calculateLuckPillars } from '../src/bazi';

// ── Solar Term boundary ───────────────────────────────────────────────────────
//
// Li Chun 2000 = Feb 4. The year changes EXACTLY on the Jié day.
//   2000-02-03 → Ji Mao  (stem 5, Yin year)
//   2000-02-04 → Geng Chen (stem 6, Yang year)
// Rule: born ON the Jié = first day of the new period (strict < in getYearPillar)

describe('Ba Zi — Solar Term boundary (Li Chun 2000)', () => {
	it('born exactly ON Li Chun (2000-02-04) = new year: Geng Chen (Yang)', () => {
		const chart = calculateBaziChart('2000-02-04', null, null, null);
		expect(chart.yearPillar.stemIndex).toBe(6);   // Geng (庚)
		expect(chart.yearPillar.branchIndex).toBe(4); // Chen (辰)
		expect(chart.yearPillar.stemId).toBe('geng');
		expect(chart.yearPillar.branchId).toBe('chen');
	});

	it('born day before Li Chun (2000-02-03) = previous year: Ji Mao (Yin)', () => {
		const chart = calculateBaziChart('2000-02-03', null, null, null);
		expect(chart.yearPillar.stemIndex).toBe(5);   // Ji (己)
		expect(chart.yearPillar.branchIndex).toBe(3); // Mao (卯)
		expect(chart.yearPillar.stemId).toBe('ji');
		expect(chart.yearPillar.branchId).toBe('mao');
	});

	it('Feb 4 and Feb 3 produce different year pillars (boundary is clean)', () => {
		const before = calculateBaziChart('2000-02-03', null, null, null);
		const onDay  = calculateBaziChart('2000-02-04', null, null, null);
		expect(before.yearPillar.stemIndex).not.toBe(onDay.yearPillar.stemIndex);
		expect(before.yearPillar.branchIndex).not.toBe(onDay.yearPillar.branchIndex);
	});
});

// ── Luck Pillars — all four direction cases ───────────────────────────────────
//
// 2000-06-15 → Geng Chen (stem 6, Yang year)
// 1999-06-15 → Ji Mao   (stem 5, Yin  year)
// Direction: isForward = (isMale === isYangYear)
//   Male  + Yang → forward  (true)
//   Male  + Yin  → backward (false)
//   Female + Yang → backward (false)
//   Female + Yin  → forward  (true)

describe('Ba Zi — Luck Pillars direction (all 4 cases)', () => {
	function getLp(birthDate: string, isMale: boolean) {
		const chart = calculateBaziChart(birthDate, null, null, null);
		return calculateLuckPillars(birthDate, chart.monthPillar, chart.yearPillar.stemIndex, isMale);
	}

	it('Male + Yang year (2000) → isForward: true', () => {
		expect(getLp('2000-06-15', true).isForward).toBe(true);
	});

	it('Male + Yin year (1999) → isForward: false', () => {
		expect(getLp('1999-06-15', true).isForward).toBe(false);
	});

	it('Female + Yang year (2000) → isForward: false', () => {
		expect(getLp('2000-06-15', false).isForward).toBe(false);
	});

	it('Female + Yin year (1999) → isForward: true', () => {
		expect(getLp('1999-06-15', false).isForward).toBe(true);
	});

	it('returns exactly 8 pillars', () => {
		expect(getLp('1990-06-15', true).pillars).toHaveLength(8);
	});

	it('start age is within valid range [1, 99]', () => {
		const result = getLp('1990-06-15', true);
		expect(result.startAge).toBeGreaterThanOrEqual(1);
		expect(result.startAge).toBeLessThanOrEqual(99);
	});

	it('each pillar starts exactly 10 years after previous', () => {
		const { pillars } = getLp('1990-06-15', true);
		for (let i = 1; i < pillars.length; i++) {
			expect(pillars[i].startAge - pillars[i - 1].startAge).toBe(10);
		}
	});

	it('forward and backward yield different first pillars for same birth date', () => {
		const fwd = getLp('2000-06-15', true);  // forward
		const bwd = getLp('2000-06-15', false); // backward
		const same = fwd.pillars[0].pillar.stemIndex   === bwd.pillars[0].pillar.stemIndex
		          && fwd.pillars[0].pillar.branchIndex === bwd.pillars[0].pillar.branchIndex;
		expect(same).toBe(false);
	});

	it('Solar Term boundary: Feb 3 (Yin year) vs Feb 4 (Yang year) → different direction for same gender', () => {
		// Male born Feb 3 → Ji Mao (Yin) → backward
		// Male born Feb 4 → Geng Chen (Yang) → forward
		expect(getLp('2000-02-03', true).isForward).toBe(false);
		expect(getLp('2000-02-04', true).isForward).toBe(true);
	});
});
