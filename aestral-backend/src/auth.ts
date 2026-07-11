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

const FIREBASE_JWKS_URL =
	'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const JWKS_CACHE_KEY = 'firebase_jwks_v1';
const JWKS_CACHE_TTL_SECONDS = 21_600; // 6 hours — matches Google's typical Cache-Control

/**
 * Fetches Firebase public keys from Google, caching the result in KV.
 * On a cold cache miss this adds one network round-trip; subsequent calls
 * within the TTL window are served entirely from KV (~1 ms).
 */
async function getFirebaseJwks(kv: KVNamespace): Promise<JsonWebKey[]> {
	const cached = await kv.get<{ keys: JsonWebKey[] }>(JWKS_CACHE_KEY, 'json');
	if (cached?.keys?.length) return cached.keys;

	const resp = await fetch(FIREBASE_JWKS_URL);
	if (!resp.ok) throw new Error(`JWKS fetch failed: ${resp.status}`);

	const jwks = (await resp.json()) as { keys: JsonWebKey[] };
	await kv.put(JWKS_CACHE_KEY, JSON.stringify(jwks), {
		expirationTtl: JWKS_CACHE_TTL_SECONDS,
	});
	return jwks.keys;
}

/**
 * Full Firebase JWT verification — two layers:
 *   1. Claims validation (structure, expiry, iss/aud/sub) — no network, fast.
 *   2. RS256 signature verification against Google's public keys (KV-cached).
 *
 * Fail-open on JWKS fetch errors so a transient Google outage doesn't block
 * legitimate users; claims validation still filters malformed/expired tokens.
 *
 * Returns `{ error, status }` if the token is invalid, or `null` if valid.
 */
export async function verifyFirebaseJwt(
	token: string,
	projectId: string,
	kv: KVNamespace,
): Promise<{ error: string; status: number } | null> {
	// ── Layer 1: claims (fast path — no network) ─────────────────────────────
	const payload = decodeJwtPayload(token);
	if (!payload) return { error: 'Token tidak valid atau rusak', status: 401 };
	if (isTokenExpired(payload)) return { error: 'Token kedaluwarsa, silakan login ulang', status: 401 };
	if (!validateFirebaseClaims(payload, projectId)) return { error: 'Token tidak dikenali', status: 403 };

	// ── Layer 2: RS256 signature ─────────────────────────────────────────────
	const parts = token.split('.');

	let header: Record<string, unknown>;
	try {
		const decoded = atob(parts[0].replace(/-/g, '+').replace(/_/g, '/'));
		header = JSON.parse(decoded) as Record<string, unknown>;
	} catch {
		return { error: 'Token header tidak dapat dibaca', status: 401 };
	}

	if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
		return { error: 'Algoritma token tidak didukung', status: 401 };
	}

	let keys: JsonWebKey[];
	try {
		keys = await getFirebaseJwks(kv);
	} catch {
		// JWKS endpoint unreachable AND KV cache empty — fail closed.
		// Failing open here would let forged tokens pass signature check
		// during a Google outage. Legitimate users can retry momentarily.
		console.warn('[Auth] JWKS tidak tersedia — menolak token untuk mencegah bypass');
		return { error: 'Layanan autentikasi sementara tidak tersedia. Coba lagi.', status: 503 };
	}

	const jwk = keys.find((k) => (k as unknown as { kid?: string }).kid === header.kid);
	if (!jwk) return { error: 'Kunci publik token tidak ditemukan', status: 401 };

	try {
		const cryptoKey = await crypto.subtle.importKey(
			'jwk',
			jwk,
			{ name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
			false,
			['verify'],
		);

		const signingInput = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
		const sigPadded = parts[2].replace(/-/g, '+').replace(/_/g, '/');
		const sigBytes = Uint8Array.from(atob(sigPadded), (c) => c.charCodeAt(0));

		const valid = await crypto.subtle.verify(
			{ name: 'RSASSA-PKCS1-v1_5' },
			cryptoKey,
			sigBytes,
			signingInput,
		);

		return valid ? null : { error: 'Tanda tangan token tidak valid', status: 401 };
	} catch {
		return { error: 'Verifikasi token gagal', status: 401 };
	}
}
