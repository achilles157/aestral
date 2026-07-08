import { describe, it, expect } from 'vitest';
import { isRateLimited, getRateLimitResetSeconds } from '../src/rate_limiter';

// Mock KVNamespace for testing rate limiter without relying on live environment bindings
const mockKv = {
	store: new Map<string, string>(),
	async get(key: string) {
		return this.store.get(key) || null;
	},
	async put(key: string, value: string) {
		this.store.set(key, value);
	}
} as unknown as KVNamespace;

describe('Rate Limiter', () => {
	it('allows requests below the limit', async () => {
		const ip = 'test-ip-allow-1';
		// First 3 requests of a limit=5 should all pass
		expect(await isRateLimited(ip, 5, 60_000, mockKv)).toBe(false);
		expect(await isRateLimited(ip, 5, 60_000, mockKv)).toBe(false);
		expect(await isRateLimited(ip, 5, 60_000, mockKv)).toBe(false);
	});

	it('blocks requests exceeding the limit', async () => {
		const ip = 'test-ip-block-1';
		const max = 3;
		// Exhaust the limit
		for (let i = 0; i < max; i++) {
			await isRateLimited(ip, max, 60_000, mockKv);
		}
		// Next request should be rate limited
		expect(await isRateLimited(ip, max, 60_000, mockKv)).toBe(true);
	});

	it('allows requests from different IPs independently', async () => {
		const ip1 = 'test-ip-ind-1';
		const ip2 = 'test-ip-ind-2';
		const max = 2;

		// Exhaust ip1
		await isRateLimited(ip1, max, 60_000, mockKv);
		await isRateLimited(ip1, max, 60_000, mockKv);
		expect(await isRateLimited(ip1, max, 60_000, mockKv)).toBe(true);

		// ip2 should still be free
		expect(await isRateLimited(ip2, max, 60_000, mockKv)).toBe(false);
	});

	it('returns 0 reset seconds for unknown IP', async () => {
		expect(await getRateLimitResetSeconds('never-seen-ip', 60_000, mockKv)).toBe(0);
	});

	it('returns positive reset seconds for a rate-limited IP', async () => {
		const ip = 'test-ip-reset-1';
		const max = 1;
		await isRateLimited(ip, max, 60_000, mockKv); // Consume the limit
		await isRateLimited(ip, max, 60_000, mockKv); // Now rate limited

		const resetSecs = await getRateLimitResetSeconds(ip, 60_000, mockKv);
		expect(resetSecs).toBeGreaterThan(0);
		expect(resetSecs).toBeLessThanOrEqual(60);
	});

	it('allows requests again after the window expires', () => {
		const ip = 'test-ip-window-1';
		const max = 2;
		const shortWindow = 1; // 1ms window — expires immediately

		// Exhaust limit with short window
		return new Promise<void>(async (resolve) => {
			await isRateLimited(ip, max, shortWindow, mockKv);
			await isRateLimited(ip, max, shortWindow, mockKv);

			// Wait for window to expire then check again
			setTimeout(async () => {
				expect(await isRateLimited(ip, max, shortWindow, mockKv)).toBe(false);
				resolve();
			}, 10);
		});
	});
});
