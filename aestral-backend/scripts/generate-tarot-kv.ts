/**
 * Build script: pre-generate Tarot synthesis templates for Cloudflare KV.
 *
 * Usage:  npx tsx scripts/generate-tarot-kv.ts [--output ./kv-tarot.json]
 *
 * This script:
 *   1. Generates 150 templates (25 Mangsa + 125 Birth combos)
 *   2. Writes them as a JSON file for manual KV upload
 *   3. Prints KV namespace setup instructions
 *
 * After running, upload with:
 *   wrangler kv:key put --binding=TAROT_KV "v3:template:mangsa:cups-wands:00" --path=kv-tarot.json  (per key)
 *   OR use wrangler kv:bulk put --binding=TAROT_KV kv-tarot-bulk.json
 *
 * Generated file formats:
 *   - kv-tarot.json: single template preview (first entry)
 *   - kv-tarot-bulk.json: [{key, value, metadata}, ...] for wrangler bulk upload
 */

import { generateAllTemplates } from '../src/tarot-synthesis';
import * as fs from 'fs';
import * as path from 'path';

const OUT_DIR = path.resolve(__dirname, '..');

function main() {
	const templates = generateAllTemplates();
	console.log(`Generated ${templates.size} synthesis templates (25 Mangsa + 125 Birth).\n`);

	// Preview: show a few entries
	let count = 0;
	for (const [key, value] of templates) {
		if (count < 3) {
			const parsed = JSON.parse(value);
			console.log(`  ${key}`);
			console.log(`    label: ${parsed.label}`);
			console.log(`    frame: ${parsed.frame.slice(0, 80)}...\n`);
		}
		count++;
	}

	// Write bulk upload format
	const bulkEntries = Array.from(templates.entries()).map(([key, value]) => ({
		key,
		value,
		metadata: { kind: JSON.parse(value).label },
	}));

	const bulkPath = path.join(OUT_DIR, 'kv-tarot-bulk.json');
	fs.writeFileSync(bulkPath, JSON.stringify(bulkEntries, null, 2), 'utf-8');
	console.log(`Bulk upload file written: ${bulkPath} (${bulkEntries.length} entries)`);

	// Write single-template preview
	const previewPath = path.join(OUT_DIR, 'kv-tarot-preview.json');
	const first = templates.entries().next().value;
	if (first) {
		fs.writeFileSync(previewPath, JSON.stringify({ key: first[0], value: JSON.parse(first[1]) }, null, 2), 'utf-8');
		console.log(`Preview file written:     ${previewPath}`);
	}

	console.log('\nNext steps:');
	console.log('  1. Create KV namespace:  wrangler kv:namespace create TAROT_KV');
	console.log('  2. Copy the namespace ID into wrangler.jsonc kv_namespaces');
	console.log('  3. Upload templates:     wrangler kv:bulk put --binding=TAROT_KV kv-tarot-bulk.json');
	console.log('  4. Deploy:               npm run deploy');
}

main();
