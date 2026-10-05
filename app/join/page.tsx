import Link from 'next/link';
export default function Join() {
  return (<div className="space-y-5"><div><h1 className="text-3xl">Become a provider</h1><p className="mt-1 max-w-xl text-muted">Each role has its own short application. An administrator reviews your licence number before the Verified badge appears on your profile.</p></div>
    <div className="grid gap-4 md:grid-cols-2">{[['Tour guide', 'Share your knowledge of Kenya&apos;s destinations and culture with international visitors.', '/join/guide', 'Apply as a guide'], ['Safari driver', 'Offer safe, comfortable transport for safaris and transfers.', '/join/driver', 'Apply as a driver']].map(([t, d, h, b]) => (
      <div key={t} className="panel flex flex-col gap-3 p-6"><h2 className="text-2xl">{t}</h2><p className="text-muted" dangerouslySetInnerHTML={{ __html: d }} /><Link href={h} className="btn btn-clay self-start">{b}</Link></div>))}</div></div>);
}
