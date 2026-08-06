import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
	test: {
		poolOptions: {
			workers: {
				wrangler: { configPath: './wrangler.jsonc' },
				// Override ENVIRONMENT untuk test: fake-jwt-token bypass hanya
				// aktif di non-production. Prod tetap 'production' dari wrangler.jsonc.
				miniflare: {
					bindings: { ENVIRONMENT: 'test' },
				},
			},
		},
	},
});
