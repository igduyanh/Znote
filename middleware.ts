// TODO: Implement auth middleware with Supabase (Phase 2)
// Protect dashboard routes, redirect unauthenticated users to login

import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Placeholder - will implement Supabase auth check in Phase 2
  return NextResponse.next()
}

export const config = {
  matcher: ['/workspace/:path*'],
}
