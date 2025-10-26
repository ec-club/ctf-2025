import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		alias: {
			'$core': 'src/core',
			'$assets': 'src/assets',
		},
		adapter: adapter(),
		csp: {
			directives: {
				"default-src": ['self'],
				'script-src': ['self', 'https://cdn.jsdelivr.net', 'sha256-DEM65OVLT37kbej4y/o1ksftM5Skf39MFQ2aMrUGEP8=']
			}
		}
	}
};

export default config;
