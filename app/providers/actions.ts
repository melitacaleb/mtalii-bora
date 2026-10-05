'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function requestBooking(fd: FormData) {
  const pid = String(fd.get('provider_id')); const s = String(fd.get('start')); const e = String(fd.get('end')); const n = Math.max(1, Number(fd.get('travelers')) || 1);
  const back = (m: string) => redirect(`/providers/${pid}?error=${encodeURIComponent(m)}`);
  const supabase = createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect(`/login?next=/providers/${pid}`);
  if (!/^\d{4}-\d\d-\d\d$/.test(s) || !/^\d{4}-\d\d-\d\d$/.test(e) || e < s || s < new Date().toISOString().slice(0, 10)) back('Choose valid dates that are not in the past.');
  const { data: busy } = await supabase.rpc('provider_busy', { pid });
  if ((busy ?? []).some((r: any) => s <= r.end_date && e >= r.start_date)) back('This provider is already booked for part of those dates.');
  const { error } = await supabase.from('bookings').insert({ traveler_id: user.id, provider_id: pid, start_date: s, end_date: e, travelers: n, note: String(fd.get('note') ?? '').slice(0, 500) });
  if (error) back(error.message);
  revalidatePath('/bookings'); redirect('/bookings?sent=1');
}
