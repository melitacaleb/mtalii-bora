import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { safeNext } from '@/lib/services';
export async function GET(req: NextRequest) {
  const url = new URL(req.url); const code = url.searchParams.get('code'); const next = safeNext(url.searchParams.get('next')) ?? '/dashboard';
  if (code) { const { error } = await createClient().auth.exchangeCodeForSession(code); if (!error) return NextResponse.redirect(new URL(next, url.origin)); }
  return NextResponse.redirect(new URL('/login?error=callback', url.origin));
}
