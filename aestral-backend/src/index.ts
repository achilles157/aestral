import { handleRequest } from './router';

export default {
	async fetch(request): Promise<Response> {
		return handleRequest(request);
	},
} satisfies ExportedHandler<Env>;
