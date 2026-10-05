import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { wikiImage } from '@/lib/wiki';
import { landing, SERVICES, COMING_SOON } from '@/lib/services';
import Icon from '@/components/Icon';
import DestCard from '@/components/DestCard';
export default async function Home() {
  const { user, profile } = await getSession();
  if (user) redirect(landing(profile?.role));
  const { data: dests } = await createClient().from('destinations').select('*').order('id').limit(4);
  const hero = await wikiImage('Maasai_Mara');
  return (<div className="space-y-14">
    <section className="relative isolate overflow-hidden rounded-2xl bg-[#3b2a24] text-white">
      {hero && <img src={hero} alt="Savanna in the Maasai Mara" className="absolute inset-0 -z-10 h-full w-full object-cover" />}
      <div className="absolute inset-0 -z-10 bg-gradient-to-r from-black/80 via-black/55 to-black/10" />
      <div className="max-w-xl px-6 py-20 sm:px-10 sm:py-28"><h1 className="text-4xl font-bold sm:text-5xl">Book a verified guide or safari driver in Kenya</h1>
        <p className="mt-4 text-lg text-white/90">Compare local professionals, check who has been verified, agree dates and plan every day of the trip together.</p>
        <div className="mt-7 flex flex-wrap gap-3"><Link href="/signup" className="btn btn-clay">Create traveler account</Link><Link href="/login" className="btn border-white/70 text-white hover:bg-white/15">Log in</Link></div></div>
    </section>
    <section><h2 className="text-3xl">Who it is for</h2>
      <div className="panel mt-4 grid divide-y divide-line md:grid-cols-3 md:divide-x md:divide-y-0">
        {[['Travelers', 'Search by service, county, language and availability. Book, message and plan each day in one place.', '/signup', 'Create an account'],
          ['Tour guides', 'Show your licence, languages and specialities. Receive booking requests and manage your calendar.', '/join/guide', 'Apply as a guide'],
          ['Safari drivers', 'List your vehicle, service areas and rates. Get requests from travelers who need a driver.', '/join/driver', 'Apply as a driver']].map(([t, d, h, b]) => (
          <div key={t} className="flex flex-col gap-2 p-6"><h3 className="text-xl font-semibold">{t}</h3><p className="text-muted">{d}</p><Link href={h} className="btn btn-line mt-auto self-start">{b}</Link></div>))}</div></section>
    <section><h2 className="text-3xl">Services</h2><p className="mt-1 text-muted">Pick a category. You will be asked to log in or sign up first.</p>
      <div className="panel mt-4 grid divide-y divide-line sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-3">{SERVICES.map((s, i) => (
        <Link key={s.key} href={`/providers?svc=${s.key}`} className={`flex gap-3 p-5 hover:bg-soft ${i >= 2 ? 'sm:border-t sm:border-line' : ''} ${i === 2 ? 'lg:border-t-0' : ''}`}>
          <span className="text-clay"><Icon name={s.icon} size={26} /></span><span><span className="block font-semibold">{s.label}</span><span className="text-sm text-muted">{s.blurb}</span></span></Link>))}</div>
      <p className="mt-3 text-sm text-muted">Planned next: {COMING_SOON.join(', ')}.</p></section>
    <section><h2 className="text-3xl">How booking works</h2>
      <ol className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{['Create a free traveler account.', 'Filter guides and drivers and open their profiles.', 'Send a request for your dates. The provider accepts or declines.', 'Chat and build the day-by-day itinerary together.'].map((t, i) => (
        <li key={i} className="panel p-4"><span className="font-display text-2xl text-clay">{i + 1}</span><p className="mt-1">{t}</p></li>))}</ol></section>
    <section><div className="flex items-end justify-between"><h2 className="text-3xl">Places to go</h2><Link href="/destinations" className="font-semibold text-clay underline underline-offset-4">See all destinations</Link></div>
      <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{(dests ?? []).map((d: any) => <DestCard key={d.id} d={d} />)}</div></section>
  </div>);
}
