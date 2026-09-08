/**
 * Calculate estimated reading time for a markdown/mdx article body.
 * Supports both CJK (Japanese/Chinese/Korean) characters and Western words.
 *
 * @param content Raw markdown/mdx body content string
 * @returns Formatted reading time string (e.g. "読了目安 3分")
 */
export function getReadingTime(content: string = ''): string {
  if (!content) {
    return '読了目安 1分';
  }

  // Remove code blocks, HTML tags, and markdown formatting to count real text
  const cleanText = content
    .replace(/```[\s\S]*?```/g, '')
    .replace(/<[^>]+>/g, '')
    .replace(/#+\s+/g, '')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .trim();

  // Count CJK (Japanese/Chinese/Korean) characters
  const cjkChars = (cleanText.match(/[\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7a3]/g) || []).length;

  // Count non-CJK words (English, numbers, etc.)
  const nonCjkText = cleanText.replace(/[\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7a3]/g, ' ');
  const wordCount = nonCjkText.split(/\s+/).filter(Boolean).length;

  // Calculate minutes: CJK ~500 chars/min, Words ~200 words/min
  const minutesFromCjk = cjkChars / 500;
  const minutesFromWords = wordCount / 200;
  const totalMinutes = Math.max(1, Math.ceil(minutesFromCjk + minutesFromWords));

  return `読了目安 ${totalMinutes}分`;
}
