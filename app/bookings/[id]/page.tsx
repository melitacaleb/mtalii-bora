import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { Star } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import AutoRefresh from '@/components/AutoRefresh';
import { setStatus } from '../actions';
import { addItem, deleteItem, sendMessage, submitReview } from './actions';
export default async function Booking({ params, searchParams }: { params: { id: string }; searchParams: { error?: string } }) {
  const { user } = await getSession(); if (!user) redirect(`/login?next=/bookings/${params.id}`);
  const supabase = createClient(); const id = Number(params.id); if (!id) notFound();
  const { data: b } = await supabase.from('bookings').select('*, provider:provider_profiles(type, profiles(full_name)), traveler:profiles!traveler_id(full_name)').eq('id', id).maybeSingle(); if (!b) notFound();
  const [{ data: msgs }, { data: items }, { data: review }, { data: dests }] = await Promise.all([
    supabase.from('messages').select('*').eq('booking_id', id).order('created_at'), supabase.from('itinerary_items').select('*, destination:destinations(name)').eq('booking_id', id).order('day').order('start_time'),
    supabase.from('reviews').select('rating,comment').eq('booking_id', id).maybeSingle(), supabase.from('destinations').select('id,name').order('name')]);
  const isProvider = user.id === b.provider_id; const other = isProvider ? b.traveler?.full_name : b.provider?.profiles?.full_name; const open = ['pending', 'accepted', 'completed'].includes(b.status);
  const byDay: Record<number, any[]> = {}; (items ?? []).forEach((i: any) => (byDay[i.day] ??= []).push(i));
  const btn = (status: string, label: string, clay = false) => <form action={setStatus} key={status}><input type="hidden" name="id" value={b.id} /><button name="status" value={status} className={`btn ${clay ? 'btn-clay' : 'btn-line'}`}>{label}</button></form>;
  return (<div className="space-y-5"><AutoRefresh seconds={10} /><Link href="/bookings" className="text-sm font-semibold text-clay underline">Back to bookings</Link>
    <header className="panel flex flex-wrap items-center gap-4 p-5"><div className="flex-1"><h1 className="text-2xl">Trip with {other}</h1><p className="text-muted">{b.start_date} to {b.end_date}, {b.travelers} traveler{b.travelers > 1 ? 's' : ''}. Status: <b className="capitalize">{b.status}</b></p>{b.note && <p className="mt-1 text-sm">{b.note}</p>}</div>
      <div className="flex gap-2">{isProvider && b.status === 'pending' && <>{btn('accepted', 'Accept', true)}{btn('rejected', 'Decline')}</>}{isProvider && b.status === 'accepted' && btn('completed', 'Mark completed', true)}{!isProvider && ['pending', 'accepted'].includes(b.status) && btn('cancelled', 'Cancel booking')}</div></header>
    {searchParams.error && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{searchParams.error}</p>}
    <div className="grid gap-5 lg:grid-cols-2">
      <section className="panel p-5"><h2 className="text-xl">Itinerary</h2>
        {Object.keys(byDay).length ? Object.entries(byDay).map(([day, list]) => (<div key={day} className="mt-4"><h3 className="text-base font-semibold">Day {day}</h3><ul className="mt-1 divide-y divide-line">{list.map((i) => (<li key={i.id} className="flex items-start gap-3 py-2"><span className="w-12 shrink-0 text-sm text-muted">{i.start_time?.slice(0, 5)}</span>
          <span className="flex-1"><b>{i.title}</b>{i.destination?.name && <span className="text-sm text-muted"> at {i.destination.name}</span>}{i.notes && <span className="block text-sm text-muted">{i.notes}</span>}</span>
          <form action={deleteItem}><input type="hidden" name="id" value={i.id} /><input type="hidden" name="booking_id" value={b.id} /><button className="text-sm text-muted underline" aria-label={`Remove ${i.title}`}>Remove</button></form></li>))}</ul></div>)) : <p className="mt-2 text-muted">Nothing planned yet. Add the first activity below.</p>}
        {open && <form action={addItem} className="mt-5 grid gap-2 border-t border-line pt-4 sm:grid-cols-6"><input type="hidden" name="booking_id" value={b.id} />
          <div><label className="label" htmlFor="day">Day</label><input id="day" name="day" type="number" min={1} defaultValue={1} className="field" /></div><div className="sm:col-span-2"><label className="label" htmlFor="time">Time</label><input id="time" name="time" type="time" className="field" /></div>
          <div className="sm:col-span-3"><label className="label" htmlFor="title">Activity</label><input id="title" name="title" required className="field" /></div>
          <div className="sm:col-span-3"><label className="label" htmlFor="destination_id">Destination</label><select id="destination_id" name="destination_id" className="field"><option value="">None</option>{(dests ?? []).map((d: any) => <option key={d.id} value={d.id}>{d.name}</option>)}</select></div>
          <div className="sm:col-span-3"><label className="label" htmlFor="notes">Notes</label><input id="notes" name="notes" className="field" /></div><button className="btn btn-clay sm:col-span-6">Add to itinerary</button></form>}</section>
      <section className="panel flex flex-col p-5"><h2 className="text-xl">Messages</h2>
        <ul className="my-3 flex max-h-96 flex-1 flex-col gap-2 overflow-y-auto">{(msgs ?? []).map((m: any) => (<li key={m.id} className={`max-w-[80%] rounded-xl px-3 py-2 ${m.sender_id === user.id ? 'self-end bg-[var(--clay)] text-[var(--clay-ink)]' : 'self-start bg-soft'}`}><span className="block text-xs opacity-80">{m.sender_id === user.id ? 'You' : other}, {new Date(m.created_at).toLocaleString('en-KE', { dateStyle: 'medium', timeStyle: 'short' })}</span>{m.body}</li>))}
          {!msgs?.length && <li className="text-muted">No messages yet. Say hello to {other}.</li>}</ul>
        <form action={sendMessage} className="flex gap-2"><input type="hidden" name="booking_id" value={b.id} /><label className="sr-only" htmlFor="body">Message</label><input id="body" name="body" required maxLength={1000} placeholder="Write a message" className="field" /><button className="btn btn-clay">Send</button></form></section></div>
    {!isProvider && b.status === 'completed' && (<section className="panel p-5"><h2 className="text-xl">Your review</h2>{review ? <p className="mt-2 flex items-center gap-1"><Star size={16} className="fill-current text-clay" />{review.rating} <span className="ml-2">{review.comment}</span></p> :
      <form action={submitReview} className="mt-2 grid gap-2 sm:grid-cols-4"><input type="hidden" name="booking_id" value={b.id} /><input type="hidden" name="provider_id" value={b.provider_id} />
        <div><label className="label" htmlFor="rating">Rating</label><select id="rating" name="rating" className="field">{[5, 4, 3, 2, 1].map((n) => <option key={n} value={n}>{n} stars</option>)}</select></div>
        <div className="sm:col-span-3"><label className="label" htmlFor="comment">Comment</label><input id="comment" name="comment" className="field" /></div><button className="btn btn-clay sm:col-span-4 sm:justify-self-start">Submit review</button></form>}</section>)}</div>);
}
