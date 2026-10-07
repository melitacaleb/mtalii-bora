import { redirect } from 'next/navigation';
import { BadgeCheck } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { landing } from '@/lib/services';
import { setVerified } from './actions';
export default async function Admin({ searchParams }: { searchParams: { error?: string } }) {
  const { user, profile } = await getSession(); if (!user) redirect('/login?next=/admin'); if (profile?.role !== 'admin') redirect(landing(profile?.role));
  const s = createClient(); const count = async (t: string) => (await s.from(t).select('*', { count: 'exact', head: true })).count ?? 0;
  const [users, bookings, { data: provs }, { data: audit }] = await Promise.all([count('profiles'), count('bookings'), s.from('provider_profiles').select('id,type,county,license_no,verified,profiles(full_name)').order('verified').order('county'),
    s.from('audit_log').select('*').order('created_at', { ascending: false }).limit(40)]);
  const ids = Array.from(new Set((audit ?? []).map((a: any) => a.user_id).filter(Boolean))); const { data: who } = ids.length ? await s.from('profiles').select('id,full_name').in('id', ids) : { data: [] as any[] };
  const name = (id: string) => (who ?? []).find((w: any) => w.id === id)?.full_name ?? 'System'; const waiting = (provs ?? []).filter((p: any) => !p.verified).length;
  return (<div className="space-y-6"><h1 className="text-3xl">Administration</h1>
    {searchParams.error && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{searchParams.error}</p>}
    <div className="grid gap-4 sm:grid-cols-4">{[['Users', users], ['Providers', provs?.length ?? 0], ['Awaiting verification', waiting], ['Bookings', bookings]].map(([l, v]) => <div key={String(l)} className="panel p-4"><span className="text-sm text-muted">{l}</span><span className="block font-display text-3xl">{v}</span></div>)}</div>
    <section className="panel overflow-x-auto p-5"><h2 className="text-xl">Provider verification</h2><table className="mt-3 w-full text-left text-sm"><thead><tr className="border-b border-line"><th className="py-2">Provider</th><th>Type</th><th>County</th><th>Licence number</th><th>Status</th><th /></tr></thead>
      <tbody>{(provs ?? []).map((p: any) => (<tr key={p.id} className="border-b border-line last:border-0"><td className="py-2 font-medium">{p.profiles?.full_name}</td><td className="capitalize">{p.type}</td><td>{p.county}</td><td>{p.license_no || <span className="text-muted">not entered</span>}</td>
        <td>{p.verified ? <span className="inline-flex items-center gap-1 text-forest"><BadgeCheck size={15} />Verified</span> : 'Pending'}</td>
        <td className="text-right"><form action={setVerified}><input type="hidden" name="id" value={p.id} /><input type="hidden" name="v" value={p.verified ? '0' : '1'} /><button className={`btn ${p.verified ? 'btn-line' : 'btn-clay'} !py-1`}>{p.verified ? 'Revoke' : 'Verify'}</button></form></td></tr>))}
        {!provs?.length && <tr><td colSpan={6} className="py-4 text-muted">No providers registered yet.</td></tr>}</tbody></table></section>
    <section className="panel overflow-x-auto p-5"><h2 className="text-xl">Security and audit log</h2><table className="mt-3 w-full text-left text-sm"><thead><tr className="border-b border-line"><th className="py-2">Time</th><th>Who</th><th>Action</th><th>Detail</th></tr></thead>
      <tbody>{(audit ?? []).map((a: any) => <tr key={a.id} className="border-b border-line last:border-0"><td className="whitespace-nowrap py-1.5">{new Date(a.created_at).toLocaleString('en-KE', { dateStyle: 'short', timeStyle: 'short' })}</td><td>{name(a.user_id)}</td><td>{a.action}</td><td className="text-muted">{a.detail}</td></tr>)}</tbody></table></section></div>);
}
