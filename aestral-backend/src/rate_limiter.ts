/**
 * Simple in-memory IP rate limiter for Cloudflare Workers.
 * No external dependencies — perfect for zero-budget architecture.
 */

const requestLog = new Map<string, number[]>();

/**
 * Check if a given IP has exceeded the rate limit within the time window.
 * Automatically cleans up expired entries on each call.
 *
 * @param ip - The client IP address (e.g. from CF-Connecting-IP header)
 * @param maxRequests - Maximum allowed requests within the window
 * @param windowMs - Time window in milliseconds
 * @returns true if the request should be rejected (rate limited)
 */
export function isRateLimited(ip: string, maxRequests: number, windowMs: number): boolean {
	const now = Date.now();
	const cutoff = now - windowMs;

	let timestamps = requestLog.get(ip);

	if (!timestamps) {
		timestamps = [now];
		requestLog.set(ip, timestamps);
		return false;
	}

	// Remove expired timestamps
	const cleaned = timestamps.filter((t) => t > cutoff);

	if (cleaned.length >= maxRequests) {
		// Still rate limited — keep the existing array
		return true;
	}

	// Add current request
	cleaned.push(now);
	requestLog.set(ip, cleaned);
	return false;
}

/**
 * Get the time remaining (in seconds) before the rate limit window resets for the given IP.
 * Returns 0 if not currently limited.
 */
export function getRateLimitResetSeconds(ip: string, windowMs: number): number {
	const timestamps = requestLog.get(ip);
	if (!timestamps || timestamps.length === 0) return 0;

	const oldest = Math.min(...timestamps);
	const remaining = oldest + windowMs - Date.now();
	return remaining > 0 ? Math.ceil(remaining / 1000) : 0;
}
