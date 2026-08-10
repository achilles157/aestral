/**
 * Gemini daily quota guard — KV-backed counter harian.
 *
 * Mencegah degradasi silent saat kuota Gemini harian habis: request ditolak
 * dengan respons 503 terstruktur SEBELUM menyentuh API Gemini, sehingga user
 * mendapat pesan yang manusiawi ("Oracle sedang beristirahat") bukan error
 * generik.
 *
 * Pola fail-open sama dengan rate_limiter.ts: jika KV tidak tersedia, request
 * tetap diizinkan daripada memblokir user secara keliru.
 */

/** Buffer 20 dari kuota 500 RPD free tier Gemini. */
export const DEFAULT_GEMINI_DAILY_LIMIT = 480;

/** Key KV untuk counter tanggal tertentu. Dipisahkan agar testable. */
export function quotaKeyForDate(dateStr: string): string {
	return `gemini_daily_${dateStr}`;
}

/** Key KV untuk hari ini (UTC — reset harian selaras dengan TTL). */
export function quotaKeyToday(): string {
	return quotaKeyForDate(new Date().toISOString().split('T')[0]);
}

/** Detik tersisa sampai tengah malam UTC berikutnya. */
export function secondsUntilMidnight(now: Date = new Date()): number {
	const midnight = new Date(now);
	midnight.setUTCHours(24, 0, 0, 0);
	return Math.floor((midnight.getTime() - now.getTime()) / 1000);
}

/** Ambil limit harian dari env, fallback ke default bila tidak valid. */
export function getGeminiDailyLimit(env: { GEMINI_DAILY_LIMIT?: number }): number {
	const configured = env.GEMINI_DAILY_LIMIT;
	return typeof configured === 'number' && configured > 0
		? configured
		: DEFAULT_GEMINI_DAILY_LIMIT;
}

/**
 * Reserve satu slot quota Gemini untuk hari ini.
 *
 * Increment dilakukan SEBELUM pemanggilan Gemini (reservasi) sehingga overshoot
 * akibat race antar request tetap kecil (KV tidak mendukung increment atomik).
 * Counter otomatis reset via TTL tengah malam UTC.
 *
 * Fail-open: error KV dicatat ke log internal dan request tetap diizinkan.
 *
 * @returns true jika request boleh lanjut, false jika kuota harian habis.
 */
export async function incrementGeminiUsage(kv: KVNamespace, limit: number): Promise<boolean> {
	try {
		const key = quotaKeyToday();
		const raw = await kv.get(key);
		const parsed = parseInt(raw ?? '0', 10);
		const current = Number.isFinite(parsed) ? parsed : 0;

		if (current >= limit) return false;

		await kv.put(key, String(current + 1), {
			expirationTtl: secondsUntilMidnight(),
		});
		return true;
	} catch (err) {
		console.error('incrementGeminiUsage: KV error (fail-open):', err);
		return true;
	}
}

/** Payload respons 503 saat kuota habis — dibungkus json() oleh router. */
export function buildQuotaExceededPayload(limit: number): {
	code: string;
	error: string;
	message: string;
	retryAfterSeconds: number;
	limit: number;
} {
	const message =
		'Oracle sedang beristirahat — kapasitas kosmis hari ini sudah penuh. Kembali besok.';
	return {
		code: 'ORACLE_REST',
		error: message,
		message,
		retryAfterSeconds: secondsUntilMidnight(),
		limit,
	};
}
