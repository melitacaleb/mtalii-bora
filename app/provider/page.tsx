import Link from 'next/link';
import { redirect } from 'next/navigation';
import { BadgeCheck } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { SERVICES, landing } from '@/lib/services';
import { saveProfile, addBlock, removeBlock } from './actions';
export default async function ProviderHome({ searchParams: sp }: { searchParams: { saved?: string; error?: string } }) {
  const { user, profile } = await getSession(); if (!user) redirect('/login?next=/provider'); if (profile?.role !== 'guide' && profile?.role !== 'driver') redirect(landing(profile?.role));
  const supabase = createClient(); const today = new Date().toISOString().slice(0, 10);
  const [{ data: p }, { data: bookings }, { data: blocks }] = await Promise.all([supabase.from('provider_profiles').select('*').eq('id', user.id).single(),
    supabase.from('bookings').select('status,end_date').eq('provider_id', user.id), supabase.from('availability_blocks').select('*').eq('provider_id', user.id).gte('end_date', today).order('start_date')]);
  const pending = (bookings ?? []).filter((b: any) => b.status === 'pending').length; const upcoming = (bookings ?? []).filter((b: any) => b.status === 'accepted' && b.end_date >= today).length;
  return (<div className="space-y-6"><h1 className="text-3xl">Welcome, {String(profile.full_name).split(' ')[0]}</h1>
    {sp.saved && <p role="status" className="rounded-lg border border-forest bg-forest/10 px-3 py-2 text-sm">Profile saved.</p>}{sp.error && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{sp.error}</p>}
    <div className="grid gap-4 sm:grid-cols-3">{[['Pending requests', pending, '/bookings'], ['Upcoming trips', upcoming, '/bookings'], ['Rating', p?.rating_count ? `${p.rating_avg} (${p.rating_count})` : 'No reviews yet', `/providers/${user.id}`]].map(([l, v, h]) => (
      <Link key={String(l)} href={String(h)} className="panel p-4 hover:bg-soft"><span className="text-sm text-muted">{l}</span><span className="block font-display text-3xl">{v}</span></Link>))}</div>
    <section className={`panel flex items-center gap-3 p-4 ${p?.verified ? 'border-forest' : ''}`}>{p?.verified ? <><BadgeCheck className="text-forest" />Your profile is verified.</> : <>Verification pending. An administrator will check licence number <b>{p?.license_no || '(not entered)'}</b>. Changing it later resets verification.</>}</section>
    <div className="grid gap-6 lg:grid-cols-3">
      <form action={saveProfile} className="panel space-y-3 p-5 lg:col-span-2"><h2 className="text-xl">Your public profile</h2>
        <div className="grid gap-3 sm:grid-cols-2"><div><label className="label" htmlFor="county">County</label><input id="county" name="county" defaultValue={p?.county} className="field" /></div><div><label className="label" htmlFor="languages">Languages</label><input id="languages" name="languages" defaultValue={p?.languages} className="field" /></div>
          <div><label className="label" htmlFor="rate">Daily rate (USD)</label><input id="rate" name="rate" type="number" min={0} defaultValue={p?.rate_usd} className="field" /></div><div><label className="label" htmlFor="license_no">Licence number</label><input id="license_no" name="license_no" defaultValue={p?.license_no} className="field" /></div>
          {p?.type === 'driver' && <div className="sm:col-span-2"><label className="label" htmlFor="vehicle">Vehicle</label><input id="vehicle" name="vehicle" defaultValue={p?.vehicle} className="field" /></div>}</div>
        <fieldset><legend className="label">Services</legend><div className="flex flex-wrap gap-x-4 gap-y-1">{SERVICES.map((s) => <label key={s.key} className="flex items-center gap-2 text-sm"><input type="checkbox" name="services" value={s.key} defaultChecked={(p?.services ?? []).includes(s.key)} />{s.label}</label>)}</div></fieldset>
        <div><label className="label" htmlFor="bio">Bio</label><textarea id="bio" name="bio" rows={4} defaultValue={p?.bio} className="field" /></div><button className="btn btn-clay">Save profile</button></form>
      <section className="panel space-y-3 p-5"><h2 className="text-xl">Days you are unavailable</h2>
        <ul className="divide-y divide-line">{(blocks ?? []).map((b: any) => (<li key={b.id} className="flex items-center justify-between gap-2 py-2 text-sm"><span>{b.start_date} to {b.end_date}{b.reason && <span className="block text-muted">{b.reason}</span>}</span>
          <form action={removeBlock}><input type="hidden" name="id" value={b.id} /><button className="underline">Remove</button></form></li>))}{!blocks?.length && <li className="py-2 text-sm text-muted">No blocked dates. Travelers can request any day that is not already booked.</li>}</ul>
        <form action={addBlock} className="space-y-2 border-t border-line pt-3"><div className="grid grid-cols-2 gap-2"><div><label className="label" htmlFor="start">From</label><input id="start" name="start" type="date" min={today} required className="field" /></div><div><label className="label" htmlFor="end">To</label><input id="end" name="end" type="date" min={today} required className="field" /></div></div>
          <input name="reason" placeholder="Reason (optional)" className="field" /><button className="btn btn-line w-full">Block these dates</button></form></section></div></div>);
}
