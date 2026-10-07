import Link from 'next/link';
import { redirect } from 'next/navigation';
import { BadgeCheck, Star } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { SERVICES, landing } from '@/lib/services';
import Icon from '@/components/Icon';
import DestCard from '@/components/DestCard';
export default async function Dashboard() {
  const { user, profile } = await getSession(); if (!user) redirect('/login'); if (profile?.role !== 'traveler') redirect(landing(profile?.role));
  const supabase = createClient(); const today = new Date().toISOString().slice(0, 10);
  const [{ data: next }, { data: dests }, { data: top }] = await Promise.all([
    supabase.from('bookings').select('id,start_date,end_date,status,provider:provider_profiles(profiles(full_name))').in('status', ['pending', 'accepted']).gte('end_date', today).order('start_date').limit(1),
    supabase.from('destinations').select('*').in('id', [1, 18, 20, 12, 8, 17]),
    supabase.from('provider_profiles').select('id,type,county,rate_usd,verified,rating_avg,rating_count,profiles(full_name)').order('verified', { ascending: false }).order('rating_avg', { ascending: false }).limit(3)]);
  const nb: any = next?.[0];
  return (<div className="space-y-10">
    <div className="flex flex-wrap items-end justify-between gap-3"><h1 className="text-3xl">Karibu, {String(profile.full_name).split(' ')[0]}</h1>
      <div className="panel px-4 py-3 text-sm">{nb ? <><b>Next trip:</b> {nb.start_date} to {nb.end_date} with {nb.provider?.profiles?.full_name} ({nb.status}). <Link href="/bookings" className="font-semibold text-clay underline">Manage</Link></> : <>No upcoming trips yet. <Link href="/providers" className="font-semibold text-clay underline">Find a guide or driver</Link></>}</div></div>
    <section><h2 className="text-2xl">Explore by service</h2>
      <div className="panel mt-3 grid divide-y divide-line sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-3">{SERVICES.map((s, i) => (
        <Link key={s.key} href={`/providers?svc=${s.key}`} className={`flex gap-3 p-4 hover:bg-soft ${i >= 2 ? 'sm:border-t sm:border-line' : ''} ${i === 2 ? 'lg:border-t-0' : ''}`}><span className="text-clay"><Icon name={s.icon} size={24} /></span><span><span className="block font-semibold">{s.label}</span><span className="text-sm text-muted">{s.blurb}</span></span></Link>))}</div></section>
    <section><div className="flex items-end justify-between"><h2 className="text-2xl">Explore destinations</h2><Link href="/destinations" className="font-semibold text-clay underline underline-offset-4">All destinations</Link></div>
      <div className="mt-3 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">{(dests ?? []).map((d: any) => <DestCard key={d.id} d={d} />)}</div></section>
    <section><div className="flex items-end justify-between"><h2 className="text-2xl">Top-rated guides and drivers</h2><Link href="/providers" className="font-semibold text-clay underline underline-offset-4">Browse all</Link></div>
      <ul className="panel mt-3 divide-y divide-line">{(top ?? []).map((p: any) => (<li key={p.id}><Link href={`/providers/${p.id}`} className="flex items-center gap-3 p-4 hover:bg-soft"><span className="grid h-11 w-11 place-items-center rounded-full bg-[var(--side)] font-semibold text-white">{p.profiles?.full_name?.[0]}</span>
        <span className="flex-1"><b>{p.profiles?.full_name}</b> <span className="text-sm text-muted">{p.type}, {p.county}, ${p.rate_usd} a day</span></span>
        {p.verified && <BadgeCheck size={18} className="text-forest" aria-label="Verified" />}<span className="flex items-center gap-1 text-sm"><Star size={15} className="fill-current text-clay" />{p.rating_count ? p.rating_avg : 'New'}</span></Link></li>))}
        {!top?.length && <li className="p-4 text-muted">No providers yet. Register a guide or driver account to see them here.</li>}</ul></section></div>);
}
