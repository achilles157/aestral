/**
 * Gemini API client for Cloudflare Workers.
 * Uses native fetch() — no external dependencies.
 * Model: gemini-3.1-flash-lite (stable, fast, efficient).
 */

const GEMINI_MODEL = 'gemini-3.1-flash-lite';
const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';

interface GeminiPart {
	text: string;
}

interface GeminiContent {
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
): Promise<string> {
	const url = `${GEMINI_BASE_URL}/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

	const body: GeminiRequestBody = {
		system_instruction: {
			parts: [{ text: systemInstruction }],
		},
		contents: [
			{
				role: 'user',
				parts: [{ text: userPrompt }],
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
		throw new Error(`Gemini API error ${response.status}: ${errorText}`);
	}

	const data = (await response.json()) as GeminiResponse;

	// Check for API-level error
	if (data.error) {
		throw new Error(`Gemini API error: ${data.error.message}`);
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
