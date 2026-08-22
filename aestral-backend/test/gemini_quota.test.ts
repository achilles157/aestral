import { describe, it, expect } from 'vitest';
import {
	DEFAULT_GEMINI_DAILY_LIMIT,
	quotaKeyForDate,
	quotaKeyToday,
	secondsUntilMidnight,
	getGeminiDailyLimit,
	incrementGeminiUsage,
	buildQuotaExceededPayload,
} from '../src/gemini_quota';

/** Mock KVNamespace — store in-memory dengan opsi gagal untuk uji fail-open. */
class MockKv {
	store = new Map<string, string>();
	fail = false;

	async get(key: string): Promise<string | null> {
		if (this.fail) throw new Error('KV unavailable');
		return this.store.get(key) ?? null;
	}

	async put(key: string, value: string): Promise<void> {
		if (this.fail) throw new Error('KV unavailable');
		this.store.set(key, value);
	}
}

describe('Gemini Daily Quota', () => {
	it('membuat key KV dengan format tanggal YYYY-MM-DD', () => {
		expect(quotaKeyForDate('2026-08-08')).toBe('gemini_daily_2026-08-08');
	});

	it('quotaKeyToday selalu diawali prefix gemini_daily_', () => {
		expect(quotaKeyToday()).toMatch(/^gemini_daily_\d{4}-\d{2}-\d{2}$/);
	});

	it('secondsUntilMidnight mengembalikan nilai positif < 24 jam', () => {
		const secs = secondsUntilMidnight();
		expect(secs).toBeGreaterThan(0);
		expect(secs).toBeLessThanOrEqual(86400);
	});

	it('getGeminiDailyLimit memakai default saat env kosong', () => {
		expect(getGeminiDailyLimit({})).toBe(DEFAULT_GEMINI_DAILY_LIMIT);
	});

	it('getGeminiDailyLimit memakai override env yang valid', () => {
		expect(getGeminiDailyLimit({ GEMINI_DAILY_LIMIT: 100 })).toBe(100);
	});

	it('getGeminiDailyLimit mengabaikan nilai override tidak valid', () => {
		expect(getGeminiDailyLimit({ GEMINI_DAILY_LIMIT: 0 })).toBe(DEFAULT_GEMINI_DAILY_LIMIT);
		expect(getGeminiDailyLimit({ GEMINI_DAILY_LIMIT: -5 })).toBe(DEFAULT_GEMINI_DAILY_LIMIT);
	});

	it('mengizinkan request di bawah limit dan mencatat counter', async () => {
		const kv = new MockKv();
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, 3)).toBe(true);
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, 3)).toBe(true);
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, 3)).toBe(true);
		const key = quotaKeyToday();
		expect(kv.store.get(key)).toBe('3');
	});

	it('menolak request saat limit tercapai (exhausted)', async () => {
		const kv = new MockKv();
		const limit = 2;
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, limit)).toBe(true);
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, limit)).toBe(true);
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, limit)).toBe(false);
	});

	it('counter per tanggal terisolasi (reset harian = key baru)', async () => {
		expect(quotaKeyForDate('2026-08-08')).not.toBe(quotaKeyForDate('2026-08-09'));
	});

	it('fail-open saat KV error — request tetap diizinkan', async () => {
		const kv = new MockKv();
		kv.fail = true;
		expect(await incrementGeminiUsage(kv as unknown as KVNamespace, 1)).toBe(true);
	});

	it('buildQuotaExceededPayload mengembalikan kode ORACLE_REST + retryAfterSeconds', () => {
		const payload = buildQuotaExceededPayload(480);
		expect(payload.code).toBe('ORACLE_REST');
		expect(payload.error).toContain('beristirahat');
		expect(payload.message.length).toBeGreaterThan(0);
		expect(payload.retryAfterSeconds).toBeGreaterThan(0);
		expect(payload.limit).toBe(480);
	});

	it('buildQuotaExceededPayload menyimpan limit dari env override', () => {
		expect(buildQuotaExceededPayload(100).limit).toBe(100);
	});
});
