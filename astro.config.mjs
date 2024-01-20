import sitemap from '@astrojs/sitemap';
import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
	outDir: './docs',
	redirects: {
		'/': '/blog'
	},
	site: 'https://david-04.github.io',
	integrations: [
		starlight({
			title: "David's blog",
			favicon: "../public/favicon.ico",
			social: {
				github: 'https://github.com/david-04',
			},
			customCss: ['./src/assets/customization.css'],
			sidebar: [
				{
					label: 'Blog',
					link: 'blog/',
					// items: [
					// 	// Each item here is one entry in the navigation menu.
					// 	{ label: 'Example Guide', link: '/guides/example/' },
					// ],
				},
			],
			pagination: false,
			tableOfContents: {
				minHeadingLevel: 1,
				maxHeadingLevel: 5,
			},
			lastUpdated: false,
			favicon: '/favicon.ico',
		}),
		sitemap({
			filter: (page) => {
				return ["/blog/"].map(path => `https://david-04.github.io${path}`).includes(page)
			}
		}),
	],
});
