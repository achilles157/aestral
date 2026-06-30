import { describe, it, expect } from 'vitest';
import {
	parseAuthHeader,
	decodeJwtPayload,
	isTokenExpired,
	validateFirebaseClaims,
} from '../src/auth';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/** Base64url-encodes a string (no padding). */
function toBase64Url(input: string): string {
	return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * Builds a fake JWT string (header.payload.signature) with base64url-encoded
 * parts. The signature is a dummy — we're only testing claim-level validation.
 */
function createMockJwt(payload: Record<string, unknown>): string {
	const header = toBase64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
	const body = toBase64Url(JSON.stringify(payload));
	const signature = toBase64Url('fake-signature');
	return `${header}.${body}.${signature}`;
}

const PROJECT_ID = 'aestral-achilles';

// ---------------------------------------------------------------------------
// parseAuthHeader
// ---------------------------------------------------------------------------

describe('parseAuthHeader', () => {
	it('parses Bearer token', () => {
		const result = parseAuthHeader('Bearer abc123.def.ghi');
		expect(result).toEqual({ type: 'bearer', value: 'abc123.def.ghi' });
	});

	it('parses Guest id', () => {
		const result = parseAuthHeader('Guest guest-uuid-001');
		expect(result).toEqual({ type: 'guest', value: 'guest-uuid-001' });
	});

	it('is case-insensitive for the scheme', () => {
		expect(parseAuthHeader('BEARER tok')).toEqual({ type: 'bearer', value: 'tok' });
		expect(parseAuthHeader('guest id')).toEqual({ type: 'guest', value: 'id' });
	});

	it('returns null for null header', () => {
		expect(parseAuthHeader(null)).toBeNull();
	});

	it('returns null for empty string', () => {
		expect(parseAuthHeader('')).toBeNull();
	});

	it('returns null when no space separator exists', () => {
		expect(parseAuthHeader('BearerNoSpace')).toBeNull();
	});

	it('returns null for unknown scheme', () => {
		expect(parseAuthHeader('Basic abc123')).toBeNull();
	});

	it('returns null when value part is empty', () => {
		expect(parseAuthHeader('Bearer ')).toBeNull();
	});
});

// ---------------------------------------------------------------------------
// decodeJwtPayload
// ---------------------------------------------------------------------------

describe('decodeJwtPayload', () => {
	it('decodes a valid JWT payload', () => {
		const payload = { sub: 'user-1', name: 'Test', iat: 1000 };
		const jwt = createMockJwt(payload);
		const decoded = decodeJwtPayload(jwt);
		expect(decoded).toEqual(payload);
	});

	it('handles base64url characters (+ / =) correctly', () => {
		// Payload with chars that differ between base64 and base64url
		const payload = { data: 'a+b/c==d' };
		const jwt = createMockJwt(payload);
		const decoded = decodeJwtPayload(jwt);
		expect(decoded).toEqual(payload);
	});

	it('returns null for empty string', () => {
		expect(decodeJwtPayload('')).toBeNull();
	});

	it('returns null for token with wrong number of parts', () => {
		expect(decodeJwtPayload('only.two')).toBeNull();
		expect(decodeJwtPayload('a.b.c.d')).toBeNull();
	});

	it('returns null for garbage payload', () => {
		expect(decodeJwtPayload('aaa.!!!invalid-base64!!!.ccc')).toBeNull();
	});

	it('returns null for non-object payload (e.g. array)', () => {
		const header = toBase64Url(JSON.stringify({ alg: 'RS256' }));
		const body = toBase64Url(JSON.stringify([1, 2, 3]));
		const sig = toBase64Url('sig');
		expect(decodeJwtPayload(`${header}.${body}.${sig}`)).toBeNull();
	});
});

// ---------------------------------------------------------------------------
// isTokenExpired
// ---------------------------------------------------------------------------

describe('isTokenExpired', () => {
	it('returns true when exp is in the past', () => {
		const pastExp = Math.floor(Date.now() / 1000) - 3600; // 1 hour ago
		expect(isTokenExpired({ exp: pastExp })).toBe(true);
	});

	it('returns false when exp is in the future', () => {
		const futureExp = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
		expect(isTokenExpired({ exp: futureExp })).toBe(false);
	});

	it('returns true when exp is missing', () => {
		expect(isTokenExpired({})).toBe(true);
	});

	it('returns true when exp is not a number', () => {
		expect(isTokenExpired({ exp: 'not-a-number' })).toBe(true);
	});

	it('returns true when exp equals current time (boundary)', () => {
		const now = Math.floor(Date.now() / 1000);
		expect(isTokenExpired({ exp: now })).toBe(true);
	});
});

// ---------------------------------------------------------------------------
// validateFirebaseClaims
// ---------------------------------------------------------------------------

describe('validateFirebaseClaims', () => {
	function validPayload(): Record<string, unknown> {
		return {
			iss: `https://securetoken.google.com/${PROJECT_ID}`,
			aud: PROJECT_ID,
			sub: 'firebase-uid-123',
		};
	}

	it('returns true for fully valid claims', () => {
		expect(validateFirebaseClaims(validPayload(), PROJECT_ID)).toBe(true);
	});

	it('rejects wrong issuer', () => {
		const p = validPayload();
		p.iss = 'https://securetoken.google.com/wrong-project';
		expect(validateFirebaseClaims(p, PROJECT_ID)).toBe(false);
	});

	it('rejects wrong audience', () => {
		const p = validPayload();
		p.aud = 'wrong-project';
		expect(validateFirebaseClaims(p, PROJECT_ID)).toBe(false);
	});

	it('rejects missing sub', () => {
		const p = validPayload();
		delete p.sub;
		expect(validateFirebaseClaims(p, PROJECT_ID)).toBe(false);
	});

	it('rejects empty sub', () => {
		const p = validPayload();
		p.sub = '';
		expect(validateFirebaseClaims(p, PROJECT_ID)).toBe(false);
	});

	it('rejects non-string sub', () => {
		const p = validPayload();
		p.sub = 12345;
		expect(validateFirebaseClaims(p, PROJECT_ID)).toBe(false);
	});

	it('works end-to-end with createMockJwt', () => {
		const payload = {
			...validPayload(),
			exp: Math.floor(Date.now() / 1000) + 3600,
			iat: Math.floor(Date.now() / 1000),
		};
		const jwt = createMockJwt(payload);
		const decoded = decodeJwtPayload(jwt);

		expect(decoded).not.toBeNull();
		expect(isTokenExpired(decoded!)).toBe(false);
		expect(validateFirebaseClaims(decoded!, PROJECT_ID)).toBe(true);
	});
});
