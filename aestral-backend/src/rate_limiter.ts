/**
 * KV-backed IP rate limiter for Cloudflare Workers.
 *
 * Replaces the previous in-memory Map implementation — state now persists
 * across cold starts and redeploys via Cloudflare KV.
 *
 * Strategy: sliding window with timestamp array stored per IP key.
 * Fail-open: if KV is unavailable, the request is allowed through rather
 * than blocking legitimate users.
 */

/**
 * Check if a given IP has exceeded the rate limit within the time window.
 *
 * @param ip         - Client IP address (e.g. from CF-Connecting-IP header)
 * @param maxRequests - Maximum allowed requests within the window
 * @param windowMs   - Sliding window size in milliseconds
 * @param kv         - Cloudflare KV namespace binding (RATE_LIMIT_KV)
 * @returns true if the request should be rejected (rate limited)
 */
export async function isRateLimited(
	ip: string,
	maxRequests: number,
	windowMs: number,
	kv: KVNamespace,
): Promise<boolean> {
	const now = Date.now();
	const cutoff = now - windowMs;
	const ttlSeconds = Math.ceil(windowMs / 1000);

	try {
		// Load existing timestamps for this IP
		const raw = await kv.get(ip);
		let timestamps: number[] = raw ? (JSON.parse(raw) as number[]) : [];

		// Remove expired timestamps (sliding window)
		timestamps = timestamps.filter((t) => t > cutoff);

		if (timestamps.length >= maxRequests) {
			// Over limit — persist cleaned array (don't add current request)
			await kv.put(ip, JSON.stringify(timestamps), { expirationTtl: ttlSeconds });
			return true;
		}

		// Under limit — record this request
		timestamps.push(now);
		await kv.put(ip, JSON.stringify(timestamps), { expirationTtl: ttlSeconds });
		return false;
	} catch (err) {
		// Fail-open: KV error should not block legitimate users
		console.error('isRateLimited: KV error (fail-open):', err);
		return false;
	}
}

/**
 * Get the time remaining (in seconds) before the oldest request in the window expires.
 * Returns 0 if not currently limited or on KV error.
 */
export async function getRateLimitResetSeconds(
	ip: string,
	windowMs: number,
	kv: KVNamespace,
): Promise<number> {
	try {
		const raw = await kv.get(ip);
		if (!raw) return 0;

		const timestamps = JSON.parse(raw) as number[];
		if (timestamps.length === 0) return 0;

		const oldest = Math.min(...timestamps);
		const remaining = oldest + windowMs - Date.now();
		return remaining > 0 ? Math.ceil(remaining / 1000) : 0;
	} catch {
		return 0;
	}
}
