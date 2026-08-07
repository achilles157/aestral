import { describe, it, expect } from 'vitest';
import {
	buildSynthesisSystemInstruction,
	parseSynthesisResponse,
	labelDisplayName,
} from '../src/tarot_reading_prompt';

// ─── Regression: spread tematik harus mendapat narasi per label, bukan duplikat konklusi ───

describe('parseSynthesisResponse (spread tematik)', () => {
	const thematicLabels = ['potensi', 'tantangan', 'arah'];

	it('memetakan cardReadings per label asli', () => {
		const raw = JSON.stringify({
			cardReadings: [
				{ label: 'potensi', narrative: 'Kamu punya kekuatan untuk berkembang...' },
				{ label: 'tantangan', narrative: 'Ada hambatan yang perlu kamu hadapi...' },
				{ label: 'arah', narrative: 'Langkah terbaikmu adalah...' },
			],
			synthesis: 'Benang merah dari ketiga kartu ini...',
		});
		const result = parseSynthesisResponse(raw, thematicLabels);
		expect(result.cardReadings).toHaveLength(3);
		expect(result.cardReadings.map((r) => r.label)).toEqual(thematicLabels);
		expect(result.synthesis).toContain('Benang merah');
	});

	it('tidak menduplikasi narasi antar kartu (bug: semua = konklusi)', () => {
		const raw = JSON.stringify({
			cardReadings: [
				{ label: 'potensi', narrative: 'Narasi potensi yang unik.' },
				{ label: 'tantangan', narrative: 'Narasi tantangan yang unik.' },
				{ label: 'arah', narrative: 'Narasi arah yang unik.' },
			],
			synthesis: 'Konklusi yang sama sekali berbeda.',
		});
		const result = parseSynthesisResponse(raw, thematicLabels);
		const narratives = result.cardReadings.map((r) => r.narrative);
		expect(new Set(narratives).size).toBe(3); // tiga narasi berbeda
		expect(narratives).not.toContain(result.synthesis); // tak ada yang menyamar jadi konklusi
	});

	it('fallback ke synthesis hanya untuk label yang tidak dijawab Gemini', () => {
		const raw = JSON.stringify({
			cardReadings: [{ label: 'potensi', narrative: 'Hanya potensi yang dijawab.' }],
			synthesis: 'Synthesis umum.',
		});
		const result = parseSynthesisResponse(raw, thematicLabels);
		const byLabel = new Map(result.cardReadings.map((r) => [r.label, r.narrative]));
		expect(byLabel.get('potensi')).toContain('Hanya potensi');
		// Label yang hilang tetap dapat synthesis — tapi narasi potensi TIDAK boleh berubah
		expect(byLabel.get('potensi')).not.toBe(result.synthesis);
	});

	it('mendukung format legacy masa_lalu/masa_kini/masa_depan untuk label klasik', () => {
		const raw = JSON.stringify({
			masa_lalu: 'Narasi masa lalu.',
			masa_kini: 'Narasi masa kini.',
			masa_depan: 'Narasi masa depan.',
			konklusi: 'Konklusi klasik.',
		});
		const result = parseSynthesisResponse(raw, ['past', 'present', 'future']);
		expect(result.cardReadings).toHaveLength(3);
		expect(result.cardReadings[0].narrative).toContain('masa lalu');
		expect(result.synthesis).toContain('Konklusi klasik');
	});

	it('fallback terakhir: teks mentah sebagai synthesis (tidak crash)', () => {
		const result = parseSynthesisResponse('Teks bebas tanpa JSON.', thematicLabels);
		expect(result.cardReadings).toEqual([]);
		expect(result.synthesis).toContain('Teks bebas');
	});
});

describe('buildSynthesisSystemInstruction (prompt label-aware)', () => {
	it('memuat semua label tematik + deskripsi posisinya', () => {
		const labels = ['potensi', 'tantangan', 'arah'];
		const instruction = buildSynthesisSystemInstruction({}, labels);
		for (const l of labels) {
			expect(instruction).toContain(l);
		}
		expect(instruction).toContain('POTENSI');
		expect(instruction).toContain('TANTANGAN');
		expect(instruction).toContain('ARAH');
		expect(instruction).toContain('cardReadings');
		expect(instruction).toContain('jangan menyalin atau menduplikasi');
	});

	it('memuat label mangsa energy/guidance', () => {
		const instruction = buildSynthesisSystemInstruction({}, ['energy', 'guidance']);
		expect(instruction).toContain('ENERGI');
		expect(instruction).toContain('PANDUAN');
		expect(instruction).toContain('cardReadings');
	});
});

describe('labelDisplayName', () => {
	it('memetakan label tematik ke nama tampilan', () => {
		expect(labelDisplayName('potensi')).toBe('POTENSI');
		expect(labelDisplayName('daya_tarik')).toBe('DAYA TARIK');
		expect(labelDisplayName('past')).toBe('MASA LALU');
	});

	it('fallback uppercase untuk label tak dikenal', () => {
		expect(labelDisplayName('label_baru')).toBe('LABEL_BARU');
	});
});
