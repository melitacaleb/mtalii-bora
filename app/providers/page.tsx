import Link from 'next/link';
import { BadgeCheck, Star } from 'lucide-react';
import { createClient } from '@/lib/supabase/server';
import { SERVICES } from '@/lib/services';
export default async function Providers({ searchParams: sp }: { searchParams: Record<string, string | undefined> }) {
  const supabase = createClient();
  let q = supabase.from('provider_profiles').select('*, profiles(full_name)');
  if (sp.type === 'guide' || sp.type === 'driver') q = q.eq('type', sp.type);
  if (sp.verified) q = q.eq('verified', true);
  if (sp.max && Number(sp.max) > 0) q = q.lte('rate_usd', Number(sp.max));
  if (sp.svc && SERVICES.some((s) => s.key === sp.svc)) q = q.contains('services', [sp.svc]);
  const { data } = await q.order('verified', { ascending: false }).order('rating_avg', { ascending: false });
  let list: any[] = data ?? [];
  if (sp.date) { const { data: busy } = await supabase.rpc('providers_busy_on', { d: sp.date }); const set = new Set(busy ?? []); list = list.filter((p) => !set.has(p.id)); }
  const term = (sp.q ?? '').trim().toLowerCase();
  if (term) list = list.filter((p) => `${p.profiles?.full_name} ${p.county} ${p.languages}`.toLowerCase().includes(term));
  return (<div className="space-y-5"><h1 className="text-3xl">Guides and safari drivers</h1>
    <form className="panel grid gap-3 p-4 sm:grid-cols-2 lg:grid-cols-6">
      <div className="lg:col-span-2"><label className="label" htmlFor="q">Name, county or language</label><input id="q" name="q" defaultValue={sp.q} className="field" /></div>
      <div><label className="label" htmlFor="type">Type</label><select id="type" name="type" defaultValue={sp.type ?? ''} className="field"><option value="">Guides and drivers</option><option value="guide">Guides</option><option value="driver">Drivers</option></select></div>
      <div><label className="label" htmlFor="svc">Service</label><select id="svc" name="svc" defaultValue={sp.svc ?? ''} className="field"><option value="">Any</option>{SERVICES.map((s) => <option key={s.key} value={s.key}>{s.label}</option>)}</select></div>
      <div><label className="label" htmlFor="date">Available on</label><input id="date" name="date" type="date" defaultValue={sp.date} className="field" /></div>
      <div><label className="label" htmlFor="max">Max USD a day</label><input id="max" name="max" type="number" min={0} defaultValue={sp.max} className="field" /></div>
      <label className="flex items-center gap-2 text-sm"><input type="checkbox" name="verified" value="1" defaultChecked={!!sp.verified} />Verified only</label>
      <div className="flex gap-2 lg:col-span-5 lg:justify-end"><Link href="/providers" className="btn btn-line">Clear</Link><button className="btn btn-clay">Search</button></div></form>
    <p className="text-sm text-muted">{list.length} {list.length === 1 ? 'result' : 'results'}</p>
    <ul className="panel divide-y divide-line">{list.map((p) => (<li key={p.id}><Link href={`/providers/${p.id}`} className="flex flex-wrap items-center gap-4 p-4 hover:bg-soft">
      <span className="grid h-12 w-12 place-items-center rounded-full bg-[var(--side)] text-lg font-semibold text-white">{p.profiles?.full_name?.[0]}</span>
      <span className="min-w-0 flex-1"><b>{p.profiles?.full_name}</b> {p.verified ? <span className="ml-1 inline-flex items-center gap-1 text-sm font-semibold text-forest"><BadgeCheck size={16} />Verified</span> : <span className="ml-1 text-sm text-muted">Pending verification</span>}
        <span className="block text-sm text-muted">{p.type === 'guide' ? 'Tour guide' : 'Safari driver'}, {p.county}. {p.languages}</span>
        <span className="mt-1 flex flex-wrap gap-1">{(p.services ?? []).map((k: string) => <span key={k} className="rounded bg-soft px-2 py-0.5 text-xs">{SERVICES.find((s) => s.key === k)?.label ?? k}</span>)}</span></span>
      <span className="text-right"><b>${p.rate_usd}</b><span className="text-sm text-muted"> a day</span><span className="flex items-center justify-end gap-1 text-sm"><Star size={14} className="fill-current text-clay" />{p.rating_count ? `${p.rating_avg} (${p.rating_count})` : 'New'}</span></span></Link></li>))}
      {!list.length && <li className="p-6 text-muted">No providers match those filters yet.</li>}</ul></div>);
}
