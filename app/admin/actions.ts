'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function setVerified(fd: FormData) {
  const { error } = await createClient().rpc('set_verified', { pid: String(fd.get('id')), v: fd.get('v') === '1' });
  revalidatePath('/admin'); redirect(error ? `/admin?error=${encodeURIComponent(error.message)}` : '/admin');
}
