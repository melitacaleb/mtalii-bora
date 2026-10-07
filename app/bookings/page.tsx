import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { setStatus } from './actions';
const TONE: Record<string, string> = { pending: 'bg-[#e0a800]/25', accepted: 'bg-forest/20', completed: 'bg-soft', cancelled: 'bg-soft', rejected: 'bg-[#b3261e]/20' };
export default async function Bookings({ searchParams: sp }: { searchParams: { tab?: string; error?: string; sent?: string } }) {
  const { user, profile } = await getSession(); if (!user) redirect('/login?next=/bookings');
  const history = sp.tab === 'history'; const provider = profile?.role === 'guide' || profile?.role === 'driver';
  const { data } = await createClient().from('bookings').select('*, provider:provider_profiles(type, profiles(full_name)), traveler:profiles!traveler_id(full_name)').order('start_date', { ascending: false });
  const rows = (data ?? []).filter((b: any) => (history ? ['completed', 'cancelled', 'rejected'] : ['pending', 'accepted']).includes(b.status));
  const act = (id: number, status: string, label: string, clay = false) => <form action={setStatus} key={status}><input type="hidden" name="id" value={id} /><button name="status" value={status} className={`btn ${clay ? 'btn-clay' : 'btn-line'} !py-1.5`}>{label}</button></form>;
  return (<div className="space-y-4"><h1 className="text-3xl">{provider ? 'Booking requests' : 'My bookings'}</h1>
    {sp.sent && <p role="status" className="rounded-lg border border-forest bg-forest/10 px-3 py-2 text-sm">Request sent. You will be notified when the provider responds.</p>}
    {sp.error && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{sp.error}</p>}
    <div className="flex gap-2"><Link href="/bookings" className={`btn ${!history ? 'btn-clay' : 'btn-line'}`}>Active</Link><Link href="/bookings?tab=history" className={`btn ${history ? 'btn-clay' : 'btn-line'}`}>History</Link></div>
    <ul className="panel divide-y divide-line">{rows.map((b: any) => (<li key={b.id} className="flex flex-wrap items-center gap-3 p-4">
      <div className="min-w-0 flex-1"><b>{provider ? b.traveler?.full_name : b.provider?.profiles?.full_name}</b><span className="ml-2 text-sm text-muted">{provider ? `${b.travelers} traveler${b.travelers > 1 ? 's' : ''}` : b.provider?.type}</span>
        <p className="text-sm">{b.start_date} to {b.end_date}</p>{b.note && <p className="text-sm text-muted">{b.note}</p>}</div>
      <span className={`rounded-full px-3 py-1 text-xs font-semibold capitalize ${TONE[b.status]}`}>{b.status}</span>
      <div className="flex gap-2"><Link href={`/bookings/${b.id}`} className="btn btn-line !py-1.5">Open</Link>{provider && b.status === 'pending' && <>{act(b.id, 'accepted', 'Accept', true)}{act(b.id, 'rejected', 'Decline')}</>}{provider && b.status === 'accepted' && act(b.id, 'completed', 'Mark completed', true)}
        {!provider && ['pending', 'accepted'].includes(b.status) && act(b.id, 'cancelled', 'Cancel')}</div></li>))}
      {!rows.length && <li className="p-6 text-muted">{history ? 'No past bookings yet.' : 'Nothing active right now.'}</li>}</ul></div>);
}
