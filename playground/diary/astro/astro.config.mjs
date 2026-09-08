import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  // Enable static site generation (SSG) output
  output: 'static',
  // Configure site URL for production canonical URLs
  site: 'https://blog.wayup.cc',
});
