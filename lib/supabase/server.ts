import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { SUPABASE_URL, SUPABASE_KEY } from '@/lib/env';
export function createClient() {
  const store = cookies();
  return createServerClient(SUPABASE_URL, SUPABASE_KEY, { cookies: {
    getAll: () => store.getAll(),
    setAll: (list: { name: string; value: string; options: any }[]) => { try { list.forEach(({ name, value, options }) => store.set(name, value, options)); } catch { /* called from a Server Component: middleware refreshes the session */ } } } });
}
