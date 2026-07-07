/**
 * Sanitizes user input before sending to Gemini API.
 * Prevents prompt injection, excessive length, and malicious patterns.
 */

/**
 * Clean and sanitize a user-provided prompt string.
 *
 * @param input - Raw user input
 * @param maxLength - Hard character limit (default: 500, matches router.ts validation)
 * @returns Sanitized string safe to forward to Gemini
 */
export function sanitizePrompt(input: string, maxLength = 500): string {
	// Strip leading/trailing whitespace
	let cleaned = input.trim();

	// Enforce hard length limit
	if (cleaned.length > maxLength) {
		cleaned = cleaned.substring(0, maxLength);
	}

	// Remove common prompt injection patterns
	const injectionPatterns: RegExp[] = [
		/ignore\s+(previous|all|prior)\s+(instructions?|prompts?|context)/gi,
		/you\s+are\s+now\s+/gi,
		/forget\s+(everything|all|previous)/gi,
		/new\s+(role|instruction|prompt|persona)\s*:/gi,
		/\bsystem\s*:\s*/gi,
		/\bassistant\s*:\s*/gi,
		/\[INST\]/gi,
		/<\|system\|>/gi,
		/<\|user\|>/gi,
		/<\|assistant\|>/gi,
	];

	for (const pattern of injectionPatterns) {
		cleaned = cleaned.replace(pattern, '');
	}

	// Collapse excessive newlines (max 2 consecutive)
	cleaned = cleaned.replace(/\n{3,}/g, '\n\n');

	// Remove ASCII control characters except newline (\n) and tab (\t)
	cleaned = cleaned.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');

	return cleaned;
}
