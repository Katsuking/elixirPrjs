import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  // Enable static site generation (SSG) output
  output: 'static',
  // Configure site URL for production canonical URLs
  site: 'https://blog.wayup.cc',
  // Integrate MDX and React support
  integrations: [mdx(), react()],
});
