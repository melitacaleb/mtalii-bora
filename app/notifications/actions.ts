'use server';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
export async function markRead(fd: FormData) { const s = createClient(); const { data: { user } } = await s.auth.getUser(); if (!user) return; const id = Number(fd.get('id'));
  await (id ? s.from('notifications').update({ read: true }).eq('id', id) : s.from('notifications').update({ read: true }).eq('user_id', user.id).eq('read', false)); revalidatePath('/notifications'); }
