/**
 * Gemini API client for Cloudflare Workers.
 * Uses native fetch() — no external dependencies.
 * Model: gemini-3.1-flash-lite (stable, fast, efficient).
 */

import { sanitizePrompt } from './sanitize';

const GEMINI_MODEL = 'gemini-3.1-flash-lite';
const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';

interface GeminiPart {
	text: string;
}

export interface GeminiContent {
	role: string;
	parts: GeminiPart[];
}

interface GeminiRequestBody {
	system_instruction: {
		parts: GeminiPart[];
	};
	contents: GeminiContent[];
	generationConfig?: {
		maxOutputTokens?: number;
		temperature?: number;
		topP?: number;
	};
}

interface GeminiResponse {
	candidates?: Array<{
		content: {
			parts: GeminiPart[];
		};
		finishReason?: string;
	}>;
	error?: {
		message: string;
		code: number;
	};
}

/**
 * Call the Gemini API with a system instruction and user prompt.
 *
 * @param systemInstruction - The master system prompt (persona, context, guidelines)
 * @param userPrompt - The user's question/message
 * @param apiKey - Gemini API key from env.GEMINI_API_KEY
 * @returns The generated text response
 * @throws Error if the API call fails or returns no content
 */
export async function callGemini(
	systemInstruction: string,
	userPrompt: string,
	apiKey: string,
	model = GEMINI_MODEL,
): Promise<string> {
	const url = `${GEMINI_BASE_URL}/${model}:generateContent?key=${apiKey}`;

	const body: GeminiRequestBody = {
		system_instruction: {
			parts: [{ text: systemInstruction }],
		},
		contents: [
			{
				role: 'user',
				parts: [{ text: sanitizePrompt(userPrompt, 500) }],
			},
		],
		generationConfig: {
			maxOutputTokens: 1024,
			temperature: 0.85,
			topP: 0.9,
		},
	};

	const response = await fetch(url, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body),
	});

	if (!response.ok) {
		const errorText = await response.text();
		console.error(`[Gemini] HTTP ${response.status}:`, errorText); // internal log
		throw new Error(response.status === 429
			? 'GEMINI_QUOTA:Bintang-bintang sedang beristirahat. Oracle akan kembali besok.'
			: 'Layanan AI sedang tidak tersedia. Coba lagi nanti.');
	}

	const data = (await response.json()) as GeminiResponse;

	// Check for API-level error (don't leak to client)
	if (data.error) {
		console.error('[Gemini] API error:', data.error.message, data.error.code);
		throw new Error('Layanan AI mengalami kesalahan. Coba lagi nanti.');
	}

	// Extract text from response
	const candidate = data.candidates?.[0];
	if (!candidate) {
		throw new Error('Gemini API returned no candidates');
	}

	if (candidate.finishReason === 'SAFETY') {
		throw new Error('Respons diblokir oleh filter keamanan Gemini. Coba tanyakan dengan cara yang berbeda.');
	}

	const text = candidate.content?.parts?.[0]?.text;
	if (!text) {
		throw new Error('Gemini API returned empty content');
	}

	return text;
}

/**
 * Call Gemini with multi-turn chat history and optional structured JSON output.
 *
 * @param systemInstruction - Master system prompt
 * @param chatHistory - Full conversation history including the current user message as the last entry
 * @param apiKey - Gemini API key
 * @param options - responseSchema, maxOutputTokens, temperature
 * @returns Parsed JSON object matching the oracle response schema
 */
export async function callGeminiStructured(
	systemInstruction: string,
	chatHistory: GeminiContent[],
	apiKey: string,
	options?: {
		responseSchema?: object;
		maxOutputTokens?: number;
		temperature?: number;
		/** Override Gemini model for this call. Defaults to GEMINI_MODEL. */
		model?: string;
	},
): Promise<{ message: string; card?: { type: string; data: Record<string, unknown> } | null }> {
	const modelToUse = options?.model ?? GEMINI_MODEL;
	const url = `${GEMINI_BASE_URL}/${modelToUse}:generateContent?key=${apiKey}`;

	const generationConfig: Record<string, unknown> = {
		maxOutputTokens: options?.maxOutputTokens ?? 800,
		temperature: options?.temperature ?? 0.88,
		topP: 0.9,
	};

	if (options?.responseSchema) {
		generationConfig.responseMimeType = 'application/json';
		generationConfig.responseSchema = options.responseSchema;
	}

	// Sanitize user messages in history to prevent prompt injection via multi-turn chat
	const sanitizedHistory = chatHistory.map((msg) => ({
		...msg,
		parts: msg.parts.map((part) => ({
			...part,
			text: msg.role === 'user' ? sanitizePrompt(part.text, 600) : part.text,
		})),
	}));

	const body = {
		system_instruction: { parts: [{ text: systemInstruction }] },
		contents: sanitizedHistory,
		generationConfig,
	};

	const response = await fetch(url, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body),
	});

	if (!response.ok) {
		const errorText = await response.text();
		console.error(`[Gemini] HTTP ${response.status}:`, errorText);
		throw new Error(response.status === 429
			? 'GEMINI_QUOTA:Bintang-bintang sedang beristirahat. Oracle akan kembali besok.'
			: 'Layanan AI sedang tidak tersedia. Coba lagi nanti.');
	}

	const data = (await response.json()) as GeminiResponse;

	if (data.error) {
		console.error('[Gemini] API error:', data.error.message, data.error.code);
		throw new Error('Layanan AI mengalami kesalahan. Coba lagi nanti.');
	}

	const candidate = data.candidates?.[0];
	if (!candidate) throw new Error('Gemini API returned no candidates');

	if (candidate.finishReason === 'SAFETY') {
		throw new Error('Respons diblokir oleh filter keamanan Gemini. Coba tanyakan dengan cara yang berbeda.');
	}

	const text = candidate.content?.parts?.[0]?.text;
	if (!text) throw new Error('Gemini API returned empty content');

	try {
		return JSON.parse(text) as { message: string; card?: { type: string; data: Record<string, unknown> } | null };
	} catch {
		// Fallback: wrap raw text if JSON parse fails
		return { message: text, card: null };
	}
}

const GEMMA_SUMMARY_MODEL = 'gemma-4-12b-it';

/**
 * Menggunakan Gemma (quota terpisah dari Gemini) untuk generate
 * ringkasan 2-3 kalimat dari riwayat percakapan oracle.
 * Non-fatal — caller harus handle error secara graceful.
 */
export async function callGemmaForSummary(
	messages: Array<{ role: string; text: string }>,
	oracleName: string,
	apiKey: string,
): Promise<string> {
	const conversation = messages
		.map((m) => `${m.role === 'user' ? 'User' : oracleName}: ${m.text}`)
		.join('\n\n');

	const prompt =
		`Berikut adalah percakapan antara user dan oracle spiritual bernama ${oracleName}.\n\n` +
		`Ringkas percakapan ini dalam 2-3 kalimat bahasa Indonesia yang mencakup:\n` +
		`1. Topik atau keresahan utama yang dibahas\n` +
		`2. Kondisi emosional user yang terdeteksi\n` +
		`3. Pesan atau saran terpenting dari oracle\n\n` +
		`Percakapan:\n${conversation}\n\nRingkasan (2-3 kalimat):`;

	const url = `${GEMINI_BASE_URL}/${GEMMA_SUMMARY_MODEL}:generateContent?key=${apiKey}`;

	const response = await fetch(url, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			contents: [{ role: 'user', parts: [{ text: prompt }] }],
			generationConfig: { maxOutputTokens: 200, temperature: 0.3 },
		}),
	});

	if (!response.ok) {
		throw new Error(`Gemma API ${response.status}`);
	}

	const data = (await response.json()) as GeminiResponse;
	return data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
}
