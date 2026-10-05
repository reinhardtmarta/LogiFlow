/**
 * Security & Sanitization Utilities for LogiFlow
 * Prevents XSS, Script Injection, and validates financial / inventory bounds
 */

export function sanitizeText(input: string, maxLength: number = 500): string {
  if (!input) return '';
  // Strip dangerous html/script tags
  const clean = input
    .replace(/<[^>]*>?/gm, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+=/gi, '')
    .trim();
  return clean.slice(0, maxLength);
}

export function validateNumber(value: number, min: number = 0, max: number = 1000000): boolean {
  return typeof value === 'number' && !isNaN(value) && isFinite(value) && value >= min && value <= max;
}

export function validateSafeUrl(url: string): boolean {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    return ['http:', 'https:', 'data:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}
