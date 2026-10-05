import Link from 'next/link';
import { notFound } from 'next/navigation';
import { BadgeCheck, Star } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { SERVICES } from '@/lib/services';
import { requestBooking } from '../actions';
export default async function Provider({ params, searchParams }: { params: { id: string }; searchParams: { error?: string } }) {
  const supabase = createClient(); const { user, profile } = await getSession();
  const { data: p } = await supabase.from('provider_profiles').select('*, profiles(full_name)').eq('id', params.id).maybeSingle(); if (!p) notFound();
  const [{ data: busy }, { data: reviews }] = await Promise.all([supabase.rpc('provider_busy', { pid: p.id }), supabase.from('reviews').select('rating,comment,created_at').eq('provider_id', p.id).order('created_at', { ascending: false }).limit(10)]);
  const now = new Date(); const y = now.getFullYear(), m = now.getMonth(); const lead = (new Date(y, m, 1).getDay() + 6) % 7; const days = new Date(y, m + 1, 0).getDate();
  const isBusy = (d: number) => { const s = `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`; return (busy ?? []).some((r: any) => s >= r.start_date && s <= r.end_date); };
  const today = now.toISOString().slice(0, 10);
  return (<div className="grid gap-5 lg:grid-cols-3"><div className="space-y-5 lg:col-span-2">
    <section className="panel p-6"><div className="flex items-center gap-4"><span className="grid h-16 w-16 place-items-center rounded-full bg-[var(--side)] text-2xl font-semibold text-white">{p.profiles?.full_name?.[0]}</span>
      <div><h1 className="text-3xl">{p.profiles?.full_name}</h1><p className="text-muted">{p.type === 'guide' ? 'Tour guide' : 'Safari driver'} based in {p.county}</p></div></div>
      <p className="mt-4">{p.bio || 'This provider has not added a bio yet.'}</p>
      <dl className="mt-4 grid gap-2 text-sm sm:grid-cols-2"><div><dt className="font-semibold">Languages</dt><dd>{p.languages || 'Not listed'}</dd></div><div><dt className="font-semibold">Rate</dt><dd>${p.rate_usd} a day</dd></div>
        {p.vehicle && <div><dt className="font-semibold">Vehicle</dt><dd>{p.vehicle}</dd></div>}<div><dt className="font-semibold">Rating</dt><dd className="flex items-center gap-1"><Star size={14} className="fill-current text-clay" />{p.rating_count ? `${p.rating_avg} from ${p.rating_count} reviews` : 'No reviews yet'}</dd></div></dl>
      <div className="mt-4 flex flex-wrap gap-1">{(p.services ?? []).map((k: string) => <span key={k} className="rounded bg-soft px-2 py-0.5 text-xs">{SERVICES.find((s) => s.key === k)?.label ?? k}</span>)}</div>
      <p className={`mt-4 flex items-center gap-2 rounded-lg border p-3 text-sm ${p.verified ? 'border-forest' : 'border-line'}`}>{p.verified ? <><BadgeCheck className="text-forest" size={18} />Verified by a Mtalii Bora administrator.</> : 'Verification pending. An administrator has not yet confirmed this provider&apos;s licence.'}</p></section>
    <section className="panel p-6" id="availability"><h2 className="text-xl">Availability for {now.toLocaleString('en', { month: 'long', year: 'numeric' })}</h2>
      <div className="mt-3 grid grid-cols-7 gap-1 text-center text-sm">{['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => <b key={i}>{d}</b>)}{Array.from({ length: lead }).map((_, i) => <span key={'e' + i} />)}
        {Array.from({ length: days }).map((_, i) => <span key={i} className={`rounded py-1.5 ${isBusy(i + 1) ? 'bg-[#b3261e]/25 font-semibold line-through' : 'bg-soft'}`}>{i + 1}</span>)}</div>
      <p className="mt-2 text-sm text-muted">Struck-through days are already booked.</p></section>
    <section className="panel p-6"><h2 className="text-xl">Reviews</h2><ul className="mt-2 space-y-3">{(reviews ?? []).map((r: any, i: number) => <li key={i}><span className="flex items-center gap-1 font-semibold"><Star size={14} className="fill-current text-clay" />{r.rating}</span><p>{r.comment}</p></li>)}
      {!reviews?.length && <li className="text-muted">No reviews yet.</li>}</ul></section></div>
    <aside><div className="panel sticky top-20 p-5"><h2 className="text-xl">Request a booking</h2>
      {profile?.role === 'traveler' ? (<form action={requestBooking} className="mt-3 space-y-3"><input type="hidden" name="provider_id" value={p.id} />
        {searchParams.error && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{searchParams.error}</p>}
        <div><label className="label" htmlFor="start">From</label><input id="start" name="start" type="date" min={today} required className="field" /></div>
        <div><label className="label" htmlFor="end">To</label><input id="end" name="end" type="date" min={today} required className="field" /></div>
        <div><label className="label" htmlFor="travelers">Travelers</label><input id="travelers" name="travelers" type="number" min={1} defaultValue={2} className="field" /></div>
        <div><label className="label" htmlFor="note">Where would you like to go?</label><textarea id="note" name="note" rows={3} className="field" /></div>
        <button className="btn btn-clay w-full">Send request</button></form>)
        : <p className="mt-2 text-sm text-muted">{user ? 'Only traveler accounts can book.' : <>Please <Link href={`/login?next=/providers/${p.id}`} className="font-semibold text-clay underline">log in</Link> to book.</>}</p>}</div></aside></div>);
}
