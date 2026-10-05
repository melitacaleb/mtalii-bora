export const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
export const SUPABASE_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '';
export const hasEnv = () => SUPABASE_URL.startsWith('http') && !SUPABASE_URL.includes('YOUR-PROJECT') && SUPABASE_KEY.length > 20 && !SUPABASE_KEY.startsWith('YOUR-');
