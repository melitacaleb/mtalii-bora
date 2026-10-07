'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { SERVICES } from '@/lib/services';
async function ctx() { const s = createClient(); const { data: { user } } = await s.auth.getUser(); if (!user) redirect('/login'); return { s, user }; }
export async function saveProfile(fd: FormData) {
  const { s, user } = await ctx(); const keys = SERVICES.map((x) => x.key);
  const { error } = await s.from('provider_profiles').update({ bio: String(fd.get('bio') ?? '').slice(0, 600), county: String(fd.get('county') ?? '').slice(0, 60), languages: String(fd.get('languages') ?? '').slice(0, 120),
    rate_usd: Math.max(0, Number(fd.get('rate')) || 0), vehicle: String(fd.get('vehicle') ?? '').slice(0, 120), license_no: String(fd.get('license_no') ?? '').slice(0, 60), services: fd.getAll('services').map(String).filter((k) => keys.includes(k)) }).eq('id', user.id);
  revalidatePath('/provider'); redirect(error ? `/provider?error=${encodeURIComponent(error.message)}` : '/provider?saved=1');
}
export async function addBlock(fd: FormData) {
  const { s, user } = await ctx(); const a = String(fd.get('start')); const b = String(fd.get('end'));
  if (!a || !b || b < a) redirect('/provider?error=' + encodeURIComponent('Choose a start date and an end date that is not earlier.'));
  const { error } = await s.from('availability_blocks').insert({ provider_id: user.id, start_date: a, end_date: b, reason: String(fd.get('reason') ?? '').slice(0, 100) });
  revalidatePath('/provider'); redirect(error ? `/provider?error=${encodeURIComponent(error.message)}` : '/provider');
}
export async function removeBlock(fd: FormData) { const { s } = await ctx(); await s.from('availability_blocks').delete().eq('id', Number(fd.get('id'))); revalidatePath('/provider'); redirect('/provider'); }
