import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import { SUPABASE_URL, SUPABASE_KEY, hasEnv } from '@/lib/env';
const PROTECTED = ['/dashboard', '/providers', '/bookings'];
export async function updateSession(req: NextRequest) {
  let res = NextResponse.next({ request: req });
  if (!hasEnv()) return res;
  const supabase = createServerClient(SUPABASE_URL, SUPABASE_KEY, { cookies: {
    getAll: () => req.cookies.getAll(),
    setAll: (list: { name: string; value: string; options: any }[]) => { list.forEach(({ name, value }) => req.cookies.set(name, value)); res = NextResponse.next({ request: req }); list.forEach(({ name, value, options }) => res.cookies.set(name, value, options)); } } });
  const { data: { user } } = await supabase.auth.getUser();
  const path = req.nextUrl.pathname;
  if (!user && PROTECTED.some((p) => path.startsWith(p))) {
    const url = req.nextUrl.clone(); url.pathname = '/login'; url.search = `?next=${encodeURIComponent(path + req.nextUrl.search)}`;
    return NextResponse.redirect(url);
  }
  return res;
}
