'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
const back = (id: string, err?: string) => redirect(`/bookings/${id}${err ? `?error=${encodeURIComponent(err)}` : ''}`);
async function ctx() { const s = createClient(); const { data: { user } } = await s.auth.getUser(); if (!user) redirect('/login'); return { s, user }; }
export async function sendMessage(fd: FormData) {
  const id = String(fd.get('booking_id')); const body = String(fd.get('body') ?? '').trim().slice(0, 1000); if (!body) back(id);
  const { s, user } = await ctx(); const { error } = await s.from('messages').insert({ booking_id: Number(id), sender_id: user.id, body }); if (error) back(id, error.message);
  revalidatePath(`/bookings/${id}`); back(id);
}
export async function addItem(fd: FormData) {
  const id = String(fd.get('booking_id')); const title = String(fd.get('title') ?? '').trim().slice(0, 120); if (!title) back(id, 'Give the activity a title.');
  const { s } = await ctx(); const dest = Number(fd.get('destination_id')) || null; const time = String(fd.get('time') ?? '');
  const { error } = await s.from('itinerary_items').insert({ booking_id: Number(id), day: Math.max(1, Number(fd.get('day')) || 1), start_time: time || null, title, destination_id: dest, notes: String(fd.get('notes') ?? '').slice(0, 300) });
  if (error) back(id, error.message); revalidatePath(`/bookings/${id}`); back(id);
}
export async function deleteItem(fd: FormData) {
  const id = String(fd.get('booking_id')); const { s } = await ctx(); await s.from('itinerary_items').delete().eq('id', Number(fd.get('id'))); revalidatePath(`/bookings/${id}`); back(id);
}
export async function submitReview(fd: FormData) {
  const id = String(fd.get('booking_id')); const rating = Number(fd.get('rating')); if (!(rating >= 1 && rating <= 5)) back(id, 'Choose a rating from 1 to 5.');
  const { s } = await ctx(); const { error } = await s.from('reviews').insert({ booking_id: Number(id), provider_id: String(fd.get('provider_id')), rating, comment: String(fd.get('comment') ?? '').slice(0, 600) });
  if (error) back(id, error.message.includes('duplicate') ? 'You already reviewed this booking.' : error.message); revalidatePath(`/bookings/${id}`); back(id);
}
