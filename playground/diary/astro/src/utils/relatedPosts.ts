import type { CollectionEntry } from 'astro:content';

/**
 * Calculate and return related posts scored by 3-tier category hierarchy & matching tags.
 * Scoring weights:
 * - Child category match: +5 points
 * - Sub category match: +3 points
 * - Main category match: +1 point
 * - Common tag match: +1 point per tag
 *
 * @param currentPost Current post object
 * @param allPosts Array of all blog entries
 * @param limit Maximum number of related posts to return (default: 3)
 * @returns Sorted array of related CollectionEntry<'blog'>
 */
export function getRelatedPosts(
  currentPost: CollectionEntry<'blog'>,
  allPosts: CollectionEntry<'blog'>[],
  limit: number = 3
): CollectionEntry<'blog'>[] {
  const currentCategory = currentPost.data.category;
  const currentTags = currentPost.data.tags || [];

  // Filter out the current post itself
  const candidates = allPosts.filter((post) => post.slug !== currentPost.slug);

  // Score each candidate post
  const scored = candidates.map((post) => {
    let score = 0;
    const postCategory = post.data.category;
    const postTags = post.data.tags || [];

    if (currentCategory && postCategory) {
      // Small category (Child) match: +5 points
      if (
        currentCategory.child &&
        postCategory.child &&
        currentCategory.child === postCategory.child
      ) {
        score += 5;
      }

      // Medium category (Sub) match: +3 points
      if (
        currentCategory.sub &&
        postCategory.sub &&
        currentCategory.sub === postCategory.sub
      ) {
        score += 3;
      }

      // Large category (Main) match: +1 point
      if (
        currentCategory.main &&
        postCategory.main &&
        currentCategory.main === postCategory.main
      ) {
        score += 1;
      }
    }

    // Matching tags count: +1 point per tag
    const commonTags = postTags.filter((tag) => currentTags.includes(tag));
    score += commonTags.length * 1;

    return { post, score };
  });

  // Sort by score descending, fallback to publication date
  scored.sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }
    return new Date(b.post.data.pubDate).getTime() - new Date(a.post.data.pubDate).getTime();
  });

  // Filter posts with score > 0
  let results = scored.filter((item) => item.score > 0).map((item) => item.post);

  // Fallback: If not enough related posts, fill with recent posts
  if (results.length < limit) {
    const existingSlugs = new Set(results.map((p) => p.slug));
    const fallbacks = candidates
      .filter((p) => !existingSlugs.has(p.slug))
      .sort((a, b) => new Date(b.data.pubDate).getTime() - new Date(a.data.pubDate).getTime());
    
    results = [...results, ...fallbacks];
  }

  return results.slice(0, limit);
}
