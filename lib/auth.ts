import { createClient } from '@/lib/supabase/server';
export async function getSession() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { user: null, profile: null as any };
  const { data: profile } = await supabase.from('profiles').select('id, full_name, role').eq('id', user.id).single();
  return { user, profile: profile as any };
}
