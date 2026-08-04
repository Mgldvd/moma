import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://mgldvd.github.io',
  base: '/moma',
  trailingSlash: 'always',
  integrations: [sitemap()],
});
