import { describe, it, expect } from 'vitest';
import { isRateLimited, getRateLimitResetSeconds } from '../src/rate_limiter';

describe('Rate Limiter', () => {
	it('allows requests below the limit', () => {
		const ip = 'test-ip-allow-1';
		// First 3 requests of a limit=5 should all pass
		expect(isRateLimited(ip, 5, 60_000)).toBe(false);
		expect(isRateLimited(ip, 5, 60_000)).toBe(false);
		expect(isRateLimited(ip, 5, 60_000)).toBe(false);
	});

	it('blocks requests exceeding the limit', () => {
		const ip = 'test-ip-block-1';
		const max = 3;
		// Exhaust the limit
		for (let i = 0; i < max; i++) {
			isRateLimited(ip, max, 60_000);
		}
		// Next request should be rate limited
		expect(isRateLimited(ip, max, 60_000)).toBe(true);
	});

	it('allows requests from different IPs independently', () => {
		const ip1 = 'test-ip-ind-1';
		const ip2 = 'test-ip-ind-2';
		const max = 2;

		// Exhaust ip1
		isRateLimited(ip1, max, 60_000);
		isRateLimited(ip1, max, 60_000);
		expect(isRateLimited(ip1, max, 60_000)).toBe(true);

		// ip2 should still be free
		expect(isRateLimited(ip2, max, 60_000)).toBe(false);
	});

	it('returns 0 reset seconds for unknown IP', () => {
		expect(getRateLimitResetSeconds('never-seen-ip', 60_000)).toBe(0);
	});

	it('returns positive reset seconds for a rate-limited IP', () => {
		const ip = 'test-ip-reset-1';
		const max = 1;
		isRateLimited(ip, max, 60_000); // Consume the limit
		isRateLimited(ip, max, 60_000); // Now rate limited

		const resetSecs = getRateLimitResetSeconds(ip, 60_000);
		expect(resetSecs).toBeGreaterThan(0);
		expect(resetSecs).toBeLessThanOrEqual(60);
	});

	it('allows requests again after the window expires', () => {
		const ip = 'test-ip-window-1';
		const max = 2;
		const shortWindow = 1; // 1ms window — expires immediately

		// Exhaust limit with short window
		isRateLimited(ip, max, shortWindow);
		isRateLimited(ip, max, shortWindow);

		// Wait for window to expire then check again
		// Since window is 1ms, timestamps should be stale on next call
		return new Promise<void>((resolve) => {
			setTimeout(() => {
				expect(isRateLimited(ip, max, shortWindow)).toBe(false);
				resolve();
			}, 10);
		});
	});
});
