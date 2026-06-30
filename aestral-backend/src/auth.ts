/**
 * Firebase JWT Auth helpers for Cloudflare Workers.
 *
 * Handles Authorization header parsing, JWT payload decoding,
 * expiry checking, and Firebase-specific claim validation.
 * Does NOT verify RS256 signatures (requires JWK fetch — separate task).
 */

export interface AuthToken {
	type: 'bearer' | 'guest';
	value: string;
}

/**
 * Parses the Authorization header into a typed token descriptor.
 *
 * Accepted formats:
 *   `Bearer <jwt>`  → { type: 'bearer', value: '<jwt>' }
 *   `Guest <id>`    → { type: 'guest',  value: '<id>' }
 *
 * Returns `null` for missing, empty, or malformed headers.
 */
export function parseAuthHeader(header: string | null): AuthToken | null {
	if (!header) return null;

	const spaceIdx = header.indexOf(' ');
	if (spaceIdx === -1) return null;

	const scheme = header.slice(0, spaceIdx).toLowerCase();
	const value = header.slice(spaceIdx + 1).trim();

	if (!value) return null;

	if (scheme === 'bearer') return { type: 'bearer', value };
	if (scheme === 'guest') return { type: 'guest', value };

	return null;
}

/**
 * Base64url-decodes a string (no padding required).
 * Uses atob which is available in Workers runtime.
 */
function base64UrlDecode(input: string): string {
	// Replace URL-safe chars and add padding
	const padded = input.replace(/-/g, '+').replace(/_/g, '/');
	const pad = padded.length % 4;
	const withPad = pad ? padded + '='.repeat(4 - pad) : padded;
	return atob(withPad);
}

/**
 * Splits a JWT into 3 parts, base64url-decodes the payload (part[1]),
 * and parses the JSON.
 *
 * Returns `null` if the token is malformed or the payload is not valid JSON.
 */
export function decodeJwtPayload(token: string): Record<string, unknown> | null {
	if (!token) return null;

	const parts = token.split('.');
	if (parts.length !== 3) return null;

	try {
		const decoded = base64UrlDecode(parts[1]);
		const payload = JSON.parse(decoded);

		if (typeof payload !== 'object' || payload === null || Array.isArray(payload)) {
			return null;
		}

		return payload as Record<string, unknown>;
	} catch {
		return null;
	}
}

/**
 * Returns `true` if the token's `exp` claim is in the past.
 * If `exp` is missing or not a number, treats the token as expired.
 */
export function isTokenExpired(payload: Record<string, unknown>): boolean {
	const exp = payload.exp;
	if (typeof exp !== 'number') return true;

	const nowSeconds = Math.floor(Date.now() / 1000);
	return nowSeconds >= exp;
}

/**
 * Validates Firebase Auth-specific JWT claims:
 *   - `iss` must be `https://securetoken.google.com/<projectId>`
 *   - `aud` must equal `projectId`
 *   - `sub` must be a non-empty string
 *
 * Returns `true` only if all checks pass.
 */
export function validateFirebaseClaims(
	payload: Record<string, unknown>,
	projectId: string,
): boolean {
	const expectedIssuer = `https://securetoken.google.com/${projectId}`;

	if (payload.iss !== expectedIssuer) return false;
	if (payload.aud !== projectId) return false;
	if (typeof payload.sub !== 'string' || payload.sub.length === 0) return false;

	return true;
}
