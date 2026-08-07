import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
	test: {
		poolOptions: {
			workers: {
				wrangler: { configPath: './wrangler.jsonc' },
				// Override ENVIRONMENT untuk test: fake-jwt-token bypass hanya
				// aktif di non-production. Prod tetap 'production' dari wrangler.jsonc.
				miniflare: {
					bindings: {
						ENVIRONMENT: 'test',
						// Override Gemini key jadi placeholder di test: handler balas 503
						// tanpa menyentuh jaringan. Mencegah test integrasi menggantung /
						// timeout saat kuota harian Gemini habis (flaky pre-existing).
						GEMINI_API_KEY: 'PLACEHOLDER_REPLACE_WITH_WRANGLER_SECRET',
					},
				},
			},
		},
	},
});
