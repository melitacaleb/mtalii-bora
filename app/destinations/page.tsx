import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import DestCard from '@/components/DestCard';
export default async function Destinations({ searchParams }: { searchParams: { cat?: string } }) {
  const { data } = await createClient().from('destinations').select('*').order('id'); const all: any[] = data ?? [];
  const cats = Array.from(new Set(all.map((d) => d.category))); const list = searchParams.cat ? all.filter((d) => d.category === searchParams.cat) : all;
  return (<div className="space-y-4"><div><h1 className="text-3xl">Destinations across Kenya</h1><p className="text-muted">{all.length} places in {new Set(all.map((d) => d.county)).size} counties.</p></div>
    <div className="flex flex-wrap gap-2">{['All', ...cats].map((c) => { const on = (searchParams.cat ?? 'All') === c; return <Link key={c} href={c === 'All' ? '/destinations' : `/destinations?cat=${c}`} className={`btn ${on ? 'btn-clay' : 'btn-line'}`}>{c}</Link>; })}</div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">{list.map((d) => <DestCard key={d.id} d={d} />)}</div></div>);
}
