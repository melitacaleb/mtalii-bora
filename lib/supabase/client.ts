import { createBrowserClient } from '@supabase/ssr';
import { SUPABASE_URL, SUPABASE_KEY } from '@/lib/env';
export const createClient = () => createBrowserClient(SUPABASE_URL, SUPABASE_KEY);
