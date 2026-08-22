import { describe, it, expect } from 'vitest';
import {
	buildSynthesisSystemInstruction,
	buildTarotUserPrompt,
	buildAreaContextBlock,
} from '../src/tarot_reading_prompt';
import { getElementRange } from '../src/tarot';
import { buildTemplateKey } from '../src/tarot-synthesis';

// ─── Regression: Tarot Tematik harus membawa konteks area ──────────────────

const KEYS_CARDS = [
	{ cardIndex: 0, isReversed: false, label: 'sumber', nameId: 'The Fool' },
	{ cardIndex: 34, isReversed: true, label: 'kebocoran', nameId: 'King of Cups' },
	{ cardIndex: 63, isReversed: false, label: 'strategi', nameId: 'King of Swords' },
];

describe('Tarot Tematik — konteks area', () => {
	it('buildSynthesisSystemInstruction menyertakan konteks area KEUANGAN', () => {
		const instr = buildSynthesisSystemInstruction(
			{},
			['sumber', 'kebocoran', 'strategi'],
			'keuangan',
		);
		expect(instr).toContain('KONTEKS AREA PEMBACAAN — KEUANGAN');
		expect(instr).toContain('pendapatan');
		expect(instr).toContain('tabungan');
		expect(instr).toContain('investasi');
		expect(instr).toContain('utang');
		expect(instr).toContain('BUKAN bacaan umum');
	});

	it('buildTarotUserPrompt menyertakan area keuangan', () => {
		const prompt = buildTarotUserPrompt([], 'keuangan');
		expect(prompt).toContain('AREA PEMBACAAN: keuangan');
	});

	it('buildAreaContextBlock kosong tanpa area', () => {
		expect(buildAreaContextBlock(undefined)).toBe('');
		expect(buildAreaContextBlock('tidak_valid')).toBe('');
	});

	it('getElementRange("major") === [0, 21] (regresi bias Major Arcana)', () => {
		expect(getElementRange('major')).toEqual([0, 21]);
	});

	it('buildTemplateKey berbeda antar area (meski struktur kartu sama)', () => {
		expect(buildTemplateKey(KEYS_CARDS, 'keuangan')).not.toBe(
			buildTemplateKey(KEYS_CARDS, 'karir'),
		);
	});

	it('buildTemplateKey berbeda untuk kartu yang berbeda (regresi bug cardIndex=0)', () => {
		const cardsB = [
			{ cardIndex: 0, isReversed: false, label: 'sumber', nameId: 'The Moon' },
			{ cardIndex: 34, isReversed: true, label: 'kebocoran', nameId: 'Queen of Cups' },
			{ cardIndex: 63, isReversed: false, label: 'strategi', nameId: 'Ace of Swords' },
		];
		expect(buildTemplateKey(KEYS_CARDS, 'keuangan')).not.toBe(
			buildTemplateKey(cardsB, 'keuangan'),
		);
	});
});
