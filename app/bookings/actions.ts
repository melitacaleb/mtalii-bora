'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function setStatus(fd: FormData) {
  const id = Number(fd.get('id')); const status = String(fd.get('status'));
  if (!id || !['accepted', 'rejected', 'completed', 'cancelled'].includes(status)) redirect('/bookings');
  const { error } = await createClient().from('bookings').update({ status }).eq('id', id);
  if (error) redirect(`/bookings?error=${encodeURIComponent(error.message.includes('exclusion') ? 'Those dates are already booked for this provider.' : error.message)}`);
  revalidatePath('/bookings'); redirect('/bookings');
}
