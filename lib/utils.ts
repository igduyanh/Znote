// Utility functions for ObsiNote

/**
 * Generate a random 6-digit invite code
 * TODO: Check uniqueness in database (Phase 3)
 */
export function generateInviteCode(): string {
  return Math.random().toString(36).substring(2, 8).toUpperCase()
}

/**
 * Combine class names (simple version)
 */
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ')
}
