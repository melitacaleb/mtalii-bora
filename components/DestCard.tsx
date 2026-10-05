import Link from 'next/link';
import { wikiImage } from '@/lib/wiki';
import { CATEGORY_TINT } from '@/lib/services';
export default async function DestCard({ d }: { d: any }) {
  const img = await wikiImage(d.wiki_title);
  return (
    <article className="overflow-hidden rounded-xl border border-line bg-surface shadow-[var(--shadow)]">
      <div className="relative h-44" style={{ background: CATEGORY_TINT[d.category] ?? '#243b53' }}>
        {img && <img src={img} alt={d.name} loading="lazy" className="absolute inset-0 h-full w-full object-cover" />}
        <span className="absolute left-3 top-3 rounded bg-black/65 px-2 py-0.5 text-xs font-medium text-white">{d.category}</span>
      </div>
      <div className="p-4"><h3 className="text-lg font-semibold">{d.name}</h3><p className="text-sm text-muted">{d.county} County</p><p className="mt-2 text-sm">{d.description}</p>
        <Link href={`/providers?q=${encodeURIComponent(d.county)}`} className="mt-3 inline-block text-sm font-semibold text-clay underline underline-offset-4">Find a guide here</Link></div>
    </article>);
}
