import { defineCollection, z } from 'astro:content';

// Define blog collection schema using Zod validation
const blogCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    pubDate: z.date(),
    description: z.string().optional(),
    author: z.string().default('WayUp Team'),
    // 3-tier category structure (Main -> Sub -> Child)
    category: z.object({
      main: z.string(),
      sub: z.string().optional(),
      child: z.string().optional(),
    }).optional(),
    // Optional tags array
    tags: z.array(z.string()).default([]),
  }),
});

export const collections = {
  blog: blogCollection,
};
