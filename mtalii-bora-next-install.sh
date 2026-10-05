#!/usr/bin/env bash
# Mtalii Bora (Next.js + Supabase) installer. Run it inside your repo folder.
#   bash mtalii-bora-next-install.sh                 # install only
#   bash mtalii-bora-next-install.sh --push "msg"    # install, commit and push to GitHub
set -e
REPO="${MB_REPO:-https://github.com/melitacaleb/mtalii-bora.git}"
PUSH=0; MSG="Mtalii Bora: Next.js + Supabase app (auth, search, availability, bookings); PHP prototype moved to legacy-php"
if [ "$1" = "--push" ]; then PUSH=1; [ -n "$2" ] && MSG="$2"; fi
echo "Installing into: $(pwd)"
# keep the PHP prototype: move it into legacy-php/ (only once)
if [ -f index.php ] && [ ! -d legacy-php ]; then
  mkdir legacy-php
  for x in index.php pages includes assets scripts README.md; do [ -e "$x" ] && mv "$x" legacy-php/; done
  echo "Moved the PHP prototype to legacy-php/"
fi
rm -rf app components lib supabase public
cat > ".env.local.example" <<'__MB_EOF__'
NEXT_PUBLIC_SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR-ANON-PUBLIC-KEY
__MB_EOF__
cat > ".gitignore" <<'__MB_EOF__'
node_modules
.next
.env*.local
*.tsbuildinfo
next-env.d.ts
Thumbs.db
.DS_Store
__MB_EOF__
cat > "README.md" <<'__MB_EOF__'
# Mtalii Bora — Next.js + Supabase
Verified tour guides and safari drivers in Kenya: search, availability, booking management. (PHP prototype lives in `legacy-php/`.)

## 1. Supabase (one time)
1. Create a project at supabase.com.
2. SQL Editor: paste and run `supabase/schema.sql` (tables, security rules, Kenya destinations).
3. Authentication > URL Configuration: Site URL `http://localhost:3000`, add redirect URL `http://localhost:3000/auth/callback`.
4. For quick local testing, Authentication > Providers > Email: turn off "Confirm email" (otherwise users must click the email link).
5. Google sign-in: Authentication > Providers > Google. Create an OAuth client in Google Cloud (Web application) with redirect URI `https://YOUR-REF.supabase.co/auth/v1/callback`, then paste the client ID and secret into Supabase.
6. Project Settings > API: copy the Project URL and the anon public key.

## 2. Run
    cp .env.local.example .env.local      # paste the URL and anon key
    npm install
    npm run dev                           # http://localhost:3000

## 3. First admin
Register an account, then in the SQL Editor:
`update profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL');`

Do not commit `.env.local`. Never put the Supabase service_role key in this app.
__MB_EOF__
mkdir -p "app/auth/callback"
cat > "app/auth/callback/route.ts" <<'__MB_EOF__'
import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { safeNext } from '@/lib/services';
export async function GET(req: NextRequest) {
  const url = new URL(req.url); const code = url.searchParams.get('code'); const next = safeNext(url.searchParams.get('next')) ?? '/dashboard';
  if (code) { const { error } = await createClient().auth.exchangeCodeForSession(code); if (!error) return NextResponse.redirect(new URL(next, url.origin)); }
  return NextResponse.redirect(new URL('/login?error=callback', url.origin));
}
__MB_EOF__
mkdir -p "app/auth/signout"
cat > "app/auth/signout/route.ts" <<'__MB_EOF__'
import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@/lib/supabase/server';
export async function POST(req: NextRequest) { await createClient().auth.signOut(); return NextResponse.redirect(new URL('/', req.url), { status: 303 }); }
__MB_EOF__
mkdir -p "app/bookings"
cat > "app/bookings/actions.ts" <<'__MB_EOF__'
'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function setStatus(fd: FormData) {
  const id = Number(fd.get('id')); const status = String(fd.get('status'));
  if (!id || !['accepted', 'rejected', 'completed', 'cancelled'].includes(status)) redirect('/bookings');
  const { error } = await createClient().from('bookings').update({ status }).eq('id', id);
  if (error) redirect(`/bookings?error=${encodeURIComponent(error.message.includes('exclusion') ? 'Those dates are already booked for this provider.' : error.message)}`);
  revalidatePath('/bookings'); redirect('/bookings');
}
__MB_EOF__
mkdir -p "app/bookings"
cat > "app/bookings/page.tsx" <<'__MB_EOF__'
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
      <div className="flex gap-2">{provider && b.status === 'pending' && <>{act(b.id, 'accepted', 'Accept', true)}{act(b.id, 'rejected', 'Decline')}</>}{provider && b.status === 'accepted' && act(b.id, 'completed', 'Mark completed', true)}
        {!provider && ['pending', 'accepted'].includes(b.status) && act(b.id, 'cancelled', 'Cancel')}</div></li>))}
      {!rows.length && <li className="p-6 text-muted">{history ? 'No past bookings yet.' : 'Nothing active right now.'}</li>}</ul></div>);
}
__MB_EOF__
mkdir -p "app/dashboard"
cat > "app/dashboard/page.tsx" <<'__MB_EOF__'
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { BadgeCheck, Star } from 'lucide-react';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import { SERVICES } from '@/lib/services';
import Icon from '@/components/Icon';
import DestCard from '@/components/DestCard';
export default async function Dashboard() {
  const { user, profile } = await getSession(); if (!user) redirect('/login'); if (profile?.role !== 'traveler') redirect('/bookings');
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
__MB_EOF__
mkdir -p "app/destinations"
cat > "app/destinations/page.tsx" <<'__MB_EOF__'
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
__MB_EOF__
mkdir -p "app"
cat > "app/globals.css" <<'__MB_EOF__'
@tailwind base; @tailwind components; @tailwind utilities;
:root{--bg:#d9e0d3;--surface:#f6f8f2;--soft:#e8ede2;--line:#9fad99;--ink:#0f1f18;--muted:#37493f;--forest:#1f4d3a;--clay:#a24419;--clay-ink:#ffffff;--side:#1f4d3a;--shadow:0 1px 3px rgba(15,31,24,.18)}
[data-theme=dark]{--bg:#0d1410;--surface:#16201b;--soft:#1e2b24;--line:#3a4e44;--ink:#edf2ed;--muted:#a6b8ad;--forest:#58b88a;--clay:#e8935f;--clay-ink:#1b110c;--side:#101c16;--shadow:0 1px 3px rgba(0,0,0,.5)}
@layer base{
  html{color-scheme:light}[data-theme=dark]{color-scheme:dark}
  body{background:var(--bg);color:var(--ink);font-family:Figtree,system-ui,sans-serif;line-height:1.55}
  h1,h2,h3{font-family:Fraunces,Georgia,serif;letter-spacing:-.01em;line-height:1.15}
  :focus-visible{outline:3px solid var(--clay);outline-offset:2px}
  @media (prefers-reduced-motion:reduce){*{transition:none!important}}
}
@layer components{
  .btn{display:inline-flex;align-items:center;justify-content:center;gap:.4rem;border-radius:.5rem;padding:.5rem 1rem;font-weight:600;font-size:.95rem;cursor:pointer;transition:background .15s;border:1px solid transparent}
  .btn-clay{background:var(--clay);color:var(--clay-ink)}.btn-clay:hover{filter:brightness(1.08)}
  .btn-line{background:var(--surface);border-color:var(--line);color:var(--ink)}.btn-line:hover{background:var(--soft)}
  .btn:disabled{opacity:.5;cursor:not-allowed}
  .panel{background:var(--surface);border:1px solid var(--line);border-radius:.75rem;box-shadow:var(--shadow)}
  .field{width:100%;border:1px solid var(--line);background:var(--surface);color:var(--ink);border-radius:.5rem;padding:.55rem .75rem}
  .label{display:block;font-size:.875rem;font-weight:600;margin-bottom:.25rem}
}
__MB_EOF__
mkdir -p "app/join/[role]"
cat > "app/join/[role]/page.tsx" <<'__MB_EOF__'
import Link from 'next/link';
import { notFound } from 'next/navigation';
import ProviderWizard from '@/components/ProviderWizard';
export default function JoinRole({ params }: { params: { role: string } }) {
  if (params.role !== 'guide' && params.role !== 'driver') notFound();
  return (<div className="mx-auto max-w-3xl space-y-4"><Link href="/join" className="text-sm font-semibold text-clay underline">Back to provider overview</Link>
    <h1 className="text-3xl">{params.role === 'guide' ? 'Tour guide application' : 'Safari driver application'}</h1><ProviderWizard role={params.role} /></div>);
}
__MB_EOF__
mkdir -p "app/join"
cat > "app/join/page.tsx" <<'__MB_EOF__'
import Link from 'next/link';
export default function Join() {
  return (<div className="space-y-5"><div><h1 className="text-3xl">Become a provider</h1><p className="mt-1 max-w-xl text-muted">Each role has its own short application. An administrator reviews your licence number before the Verified badge appears on your profile.</p></div>
    <div className="grid gap-4 md:grid-cols-2">{[['Tour guide', 'Share your knowledge of Kenya&apos;s destinations and culture with international visitors.', '/join/guide', 'Apply as a guide'], ['Safari driver', 'Offer safe, comfortable transport for safaris and transfers.', '/join/driver', 'Apply as a driver']].map(([t, d, h, b]) => (
      <div key={t} className="panel flex flex-col gap-3 p-6"><h2 className="text-2xl">{t}</h2><p className="text-muted" dangerouslySetInnerHTML={{ __html: d }} /><Link href={h} className="btn btn-clay self-start">{b}</Link></div>))}</div></div>);
}
__MB_EOF__
mkdir -p "app"
cat > "app/layout.tsx" <<'__MB_EOF__'
import './globals.css';
import type { Metadata } from 'next';
import Shell from '@/components/Shell';
export const metadata: Metadata = { title: 'Mtalii Bora — verified guides and safari drivers in Kenya', description: 'Book verified local tour guides and safari drivers across Kenya, chat with them and plan your itinerary together.' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (<html lang="en" suppressHydrationWarning><head>
    <link rel="preconnect" href="https://fonts.googleapis.com" /><link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
    <link href="https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,600;9..144,700&display=swap" rel="stylesheet" />
    <script dangerouslySetInnerHTML={{ __html: "try{var t=localStorage.getItem('theme')||(matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');document.documentElement.dataset.theme=t}catch(e){}" }} />
  </head><body><Shell>{children}</Shell></body></html>);
}
__MB_EOF__
mkdir -p "app/login"
cat > "app/login/page.tsx" <<'__MB_EOF__'
import Link from 'next/link';
import LoginForm from '@/components/LoginForm';
import { safeNext } from '@/lib/services';
export default function Login({ searchParams }: { searchParams: { next?: string; error?: string } }) {
  const next = safeNext(searchParams.next);
  return (<div className="mx-auto max-w-md"><div className="panel p-6"><h1 className="text-3xl">Log in</h1>
    <p className="mb-4 mt-1 text-muted">{next ? 'Log in or create a free traveler account to continue.' : 'Welcome back to Mtalii Bora.'}</p>
    <LoginForm next={next} notice={searchParams.error ? 'Sign-in did not finish. Please try again.' : undefined} />
    <p className="mt-5 text-sm">New traveler? <Link className="font-semibold text-clay underline" href="/signup">Create an account</Link>. Guide or driver? <Link className="font-semibold text-clay underline" href="/join">Apply here</Link>.</p></div></div>);
}
__MB_EOF__
mkdir -p "app"
cat > "app/page.tsx" <<'__MB_EOF__'
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
__MB_EOF__
mkdir -p "app/providers/[id]"
cat > "app/providers/[id]/page.tsx" <<'__MB_EOF__'
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
__MB_EOF__
mkdir -p "app/providers"
cat > "app/providers/actions.ts" <<'__MB_EOF__'
'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function requestBooking(fd: FormData) {
  const pid = String(fd.get('provider_id')); const s = String(fd.get('start')); const e = String(fd.get('end')); const n = Math.max(1, Number(fd.get('travelers')) || 1);
  const back = (m: string) => redirect(`/providers/${pid}?error=${encodeURIComponent(m)}`);
  const supabase = createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect(`/login?next=/providers/${pid}`);
  if (!/^\d{4}-\d\d-\d\d$/.test(s) || !/^\d{4}-\d\d-\d\d$/.test(e) || e < s || s < new Date().toISOString().slice(0, 10)) back('Choose valid dates that are not in the past.');
  const { data: busy } = await supabase.rpc('provider_busy', { pid });
  if ((busy ?? []).some((r: any) => s <= r.end_date && e >= r.start_date)) back('This provider is already booked for part of those dates.');
  const { error } = await supabase.from('bookings').insert({ traveler_id: user.id, provider_id: pid, start_date: s, end_date: e, travelers: n, note: String(fd.get('note') ?? '').slice(0, 500) });
  if (error) back(error.message);
  revalidatePath('/bookings'); redirect('/bookings?sent=1');
}
__MB_EOF__
mkdir -p "app/providers"
cat > "app/providers/page.tsx" <<'__MB_EOF__'
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
__MB_EOF__
mkdir -p "app/signup"
cat > "app/signup/page.tsx" <<'__MB_EOF__'
import Link from 'next/link';
import SignupForm from '@/components/SignupForm';
export default function Signup() {
  return (<div className="mx-auto max-w-md"><div className="panel p-6"><h1 className="text-3xl">Create a traveler account</h1><p className="mb-4 mt-1 text-muted">Free. You can book guides and drivers straight away.</p>
    <SignupForm /><p className="mt-5 text-sm">Already registered? <Link className="font-semibold text-clay underline" href="/login">Log in</Link>. Prefer Google? Use the button on the <Link className="font-semibold text-clay underline" href="/login">log in page</Link>.</p></div></div>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/DestCard.tsx" <<'__MB_EOF__'
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
__MB_EOF__
mkdir -p "components"
cat > "components/Icon.tsx" <<'__MB_EOF__'
import * as L from 'lucide-react'; // server-only: keeps icons out of the client bundle
export default function Icon({ name, ...p }: { name: string; size?: number; className?: string }) { const C = (L as any)[name]; return C ? <C {...p} /> : null; }
__MB_EOF__
mkdir -p "components"
cat > "components/LoginForm.tsx" <<'__MB_EOF__'
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { landing } from '@/lib/services';
export default function LoginForm({ next, notice }: { next: string | null; notice?: string }) {
  const router = useRouter(); const [err, setErr] = useState(notice ?? ''); const [busy, setBusy] = useState(false);
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setBusy(true); setErr('');
    const f = new FormData(e.currentTarget); const supabase = createClient();
    const { data, error } = await supabase.auth.signInWithPassword({ email: String(f.get('email')).trim(), password: String(f.get('password')) });
    if (error) { setErr(error.message === 'Invalid login credentials' ? 'That email and password do not match. Check them and try again.' : error.message); setBusy(false); return; }
    const { data: p } = await supabase.from('profiles').select('role').eq('id', data.user.id).single();
    router.replace(next ?? landing(p?.role)); router.refresh();
  }
  async function google() {
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: `${location.origin}/auth/callback?next=${encodeURIComponent(next ?? '/dashboard')}` } });
    if (error) setErr(error.message);
  }
  return (<div className="space-y-4">
    {err && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{err}</p>}
    <button type="button" onClick={google} className="btn btn-line w-full"><svg width="18" height="18" viewBox="0 0 48 48" aria-hidden><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z" /><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.6 5.9c4.4-4.1 7-10.1 7-17.6z" /><path fill="#FBBC05" d="M10.5 28.7c-.5-1.4-.8-3-.8-4.7s.3-3.2.8-4.7l-7.9-6.1C.9 16.4 0 20.1 0 24s.9 7.6 2.6 10.8l7.9-6.1z" /><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.6-5.9c-2.1 1.4-4.9 2.3-8.3 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z" /></svg>Continue with Google</button>
    <p className="text-center text-sm text-muted">or use your email</p>
    <form onSubmit={submit} className="space-y-3"><div><label className="label" htmlFor="email">Email</label><input id="email" name="email" type="email" required autoComplete="email" className="field" /></div>
      <div><label className="label" htmlFor="password">Password</label><input id="password" name="password" type="password" required autoComplete="current-password" className="field" /></div>
      <button className="btn btn-clay w-full" disabled={busy}>{busy ? 'Logging in' : 'Log in'}</button></form></div>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/ProviderWizard.tsx" <<'__MB_EOF__'
'use client';
import { useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { SERVICES } from '@/lib/services';
const F = ({ id, label, type = 'text', req = true, span = '', ...r }: any) => (<div className={span}><label className="label" htmlFor={id}>{label}</label><input id={id} name={id} type={type} required={req} className="field" {...r} /></div>);
export default function ProviderWizard({ role }: { role: 'guide' | 'driver' }) {
  const router = useRef(useRouter()).current; const form = useRef<HTMLFormElement>(null);
  const [step, setStep] = useState(0); const [err, setErr] = useState(''); const [done, setDone] = useState(false); const [busy, setBusy] = useState(false);
  const names = ['Account', role === 'guide' ? 'Professional details' : 'Vehicle and driving', 'Review'];
  const valid = () => { const box = form.current!.querySelectorAll('[data-step="' + step + '"] input, [data-step="' + step + '"] textarea'); for (const el of Array.from(box) as HTMLInputElement[]) if (!el.checkValidity()) { el.reportValidity(); return false; } return true; };
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); if (!valid()) return; setBusy(true); setErr(''); const f = new FormData(form.current!);
    const { data, error } = await createClient().auth.signUp({ email: String(f.get('email')).trim(), password: String(f.get('password')), options: { emailRedirectTo: `${location.origin}/auth/callback?next=/bookings`, data: {
      role, full_name: f.get('name'), county: f.get('county'), languages: f.get('languages'), rate: f.get('rate'), license_no: f.get('license_no'), vehicle: f.get('vehicle') ?? '', bio: f.get('bio') ?? '', services: f.getAll('services').join(',') } } });
    setBusy(false); if (error) return setErr(error.message);
    if (data.session) { router.replace('/bookings'); router.refresh(); } else setDone(true);
  }
  if (done) return <p role="status" className="panel p-5">Application received. Confirm your email using the link we sent, then log in. An administrator will review your licence number before the Verified badge appears.</p>;
  return (<form ref={form} onSubmit={submit} className="panel space-y-4 p-6">
    <ol className="flex flex-wrap gap-2">{names.map((n, i) => <li key={n} className={`rounded-full px-3 py-1 text-sm ${i <= step ? 'bg-[var(--clay)] text-[var(--clay-ink)] font-semibold' : 'bg-soft text-muted'}`}>{i + 1}. {n}</li>)}</ol>
    {err && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{err}</p>}
    <div data-step="0" hidden={step !== 0} className="grid gap-3 sm:grid-cols-2"><F id="name" label="Full name" /><F id="email" label="Email" type="email" /><F id="password" label="Password (8 characters or more)" type="password" minLength={8} /></div>
    <div data-step="1" hidden={step !== 1} className="grid gap-3 sm:grid-cols-2"><F id="county" label="County you are based in" /><F id="languages" label="Languages spoken" placeholder="English, Swahili" /><F id="rate" label="Daily rate (USD)" type="number" min={0} />
      <F id="license_no" label={role === 'guide' ? 'Tourism guide licence number' : 'PSV or driving licence number'} />
      {role === 'driver' && <F id="vehicle" label="Vehicle make, model and seats" span="sm:col-span-2" />}
      <fieldset className="sm:col-span-2"><legend className="label">Services you offer</legend><div className="flex flex-wrap gap-x-4 gap-y-1">{SERVICES.map((s) => <label key={s.key} className="flex items-center gap-2 text-sm"><input type="checkbox" name="services" value={s.key} />{s.label}</label>)}</div></fieldset>
      <div className="sm:col-span-2"><label className="label" htmlFor="bio">Short bio</label><textarea id="bio" name="bio" rows={3} className="field" /></div></div>
    <div data-step="2" hidden={step !== 2} className="space-y-2 text-sm"><p>Your licence number is checked by an administrator. Until then your profile shows as pending. Uploading licence and ID documents arrives in the next release.</p>
      <label className="flex items-start gap-2"><input type="checkbox" required className="mt-1" />I confirm these details are true and accept the terms of use.</label></div>
    <div className="flex justify-between pt-2"><button type="button" className="btn btn-line" disabled={step === 0} onClick={() => setStep(step - 1)}>Back</button>
      {step < 2 ? <button type="button" className="btn btn-clay" onClick={() => valid() && setStep(step + 1)}>Next</button> : <button className="btn btn-clay" disabled={busy}>{busy ? 'Sending' : 'Submit application'}</button>}</div></form>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/Shell.tsx" <<'__MB_EOF__'
import Link from 'next/link';
import { getSession } from '@/lib/auth';
import { hasEnv } from '@/lib/env';
import Sidebar from './Sidebar';
import ThemeToggle from './ThemeToggle';
export default async function Shell({ children }: { children: React.ReactNode }) {
  if (!hasEnv()) return (<main className="mx-auto max-w-xl p-8"><div className="panel p-6"><h1 className="text-2xl">Connect Supabase to start</h1>
    <p className="mt-2">Copy <code>.env.local.example</code> to <code>.env.local</code>, paste your project URL and anon key from Supabase (Project Settings, API), then restart <code>npm run dev</code>.</p></div></main>);
  const { user, profile } = await getSession();
  const role = profile?.role;
  const items = role === 'traveler'
    ? [{ href: '/dashboard', label: 'Explore home', icon: 'Compass' }, { href: '/destinations', label: 'Destinations', icon: 'Map' }, { href: '/providers', label: 'Guides and drivers', icon: 'Search' }, { href: '/bookings', label: 'My bookings', icon: 'CalendarCheck' }]
    : [{ href: '/bookings', label: 'Booking requests', icon: 'CalendarCheck' }, { href: '/destinations', label: 'Destinations', icon: 'Map' }];
  return (
    <div className="flex min-h-screen">
      {user && <Sidebar items={items} />}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b border-line bg-surface px-4">
          {!user && <Link href="/" className="font-display text-xl font-bold">Mtalii Bora</Link>}
          <div className="ml-auto flex items-center gap-2">
            {user ? (<><span className="hidden text-sm sm:block">{profile?.full_name} <span className="ml-1 rounded bg-soft px-2 py-0.5 text-xs">{role}</span></span>
              <form action="/auth/signout" method="post"><button className="btn btn-line">Sign out</button></form></>)
              : (<><Link className="btn btn-line" href="/login">Log in</Link><Link className="btn btn-clay" href="/signup">Sign up</Link></>)}
            <ThemeToggle />
          </div>
        </header>
        <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6 sm:px-6">{children}</main>
        <footer className="border-t border-line px-6 py-4 text-sm text-muted">Mtalii Bora. Destination photos come from each place&apos;s Wikipedia article.</footer>
      </div>
    </div>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/Sidebar.tsx" <<'__MB_EOF__'
'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { CalendarCheck, ChevronsLeft, Compass, Map, Search } from 'lucide-react';
const ICONS: Record<string, any> = { Compass, Map, Search, CalendarCheck };
export default function Sidebar({ items }: { items: { href: string; label: string; icon: string }[] }) {
  const path = usePathname(); const [open, setOpen] = useState(true);
  useEffect(() => setOpen(localStorage.getItem('side') !== 'collapsed'), []);
  const toggle = () => { localStorage.setItem('side', open ? 'collapsed' : 'open'); setOpen(!open); };
  return (
    <aside className={`sticky top-0 flex h-screen shrink-0 flex-col bg-[var(--side)] text-[#eef3ee] transition-[width] duration-200 ${open ? 'w-60 max-md:w-16' : 'w-16'}`}>
      <div className="flex h-14 items-center justify-between px-4">
        <Link href="/" className={`font-display text-xl font-bold ${open ? 'max-md:hidden' : 'hidden'}`}>Mtalii Bora</Link>
        <button onClick={toggle} className="rounded p-1 hover:bg-white/15 max-md:hidden" aria-label={open ? 'Collapse sidebar' : 'Expand sidebar'}><ChevronsLeft size={20} className={open ? '' : 'rotate-180'} /></button>
      </div>
      <nav className="flex-1 space-y-1 px-2 py-2">
        {items.map((i) => { const I = ICONS[i.icon]; const on = path === i.href || path.startsWith(i.href + '/');
          return (<Link key={i.href} href={i.href} title={i.label} aria-current={on ? 'page' : undefined} className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-[15px] ${on ? 'bg-[var(--clay)] text-[var(--clay-ink)] font-semibold' : 'hover:bg-white/15'}`}>
            <I size={19} className="shrink-0" /><span className={open ? 'max-md:hidden' : 'hidden'}>{i.label}</span></Link>); })}
      </nav>
    </aside>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/SignupForm.tsx" <<'__MB_EOF__'
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
export default function SignupForm() {
  const router = useRouter(); const [err, setErr] = useState(''); const [done, setDone] = useState(false); const [busy, setBusy] = useState(false);
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setBusy(true); setErr(''); const f = new FormData(e.currentTarget);
    const { data, error } = await createClient().auth.signUp({ email: String(f.get('email')).trim(), password: String(f.get('password')),
      options: { data: { full_name: String(f.get('name')).trim(), role: 'traveler' }, emailRedirectTo: `${location.origin}/auth/callback?next=/dashboard` } });
    setBusy(false);
    if (error) return setErr(error.message);
    if (data.session) { router.replace('/dashboard'); router.refresh(); } else setDone(true);
  }
  if (done) return <p role="status" className="rounded-lg border border-line bg-soft p-4">Check your inbox. We sent a confirmation link; open it to finish creating your account.</p>;
  return (<form onSubmit={submit} className="space-y-3">{err && <p role="alert" className="rounded-lg border border-[#b3261e] bg-[#b3261e]/10 px-3 py-2 text-sm">{err}</p>}
    <div><label className="label" htmlFor="name">Full name</label><input id="name" name="name" required className="field" autoComplete="name" /></div>
    <div><label className="label" htmlFor="email">Email</label><input id="email" name="email" type="email" required className="field" autoComplete="email" /></div>
    <div><label className="label" htmlFor="password">Password (8 characters or more)</label><input id="password" name="password" type="password" minLength={8} required className="field" autoComplete="new-password" /></div>
    <button className="btn btn-clay w-full" disabled={busy}>{busy ? 'Creating account' : 'Create account'}</button></form>);
}
__MB_EOF__
mkdir -p "components"
cat > "components/ThemeToggle.tsx" <<'__MB_EOF__'
'use client';
import { useEffect, useState } from 'react';
import { Moon, Sun } from 'lucide-react';
export default function ThemeToggle() {
  const [dark, setDark] = useState(false);
  useEffect(() => setDark(document.documentElement.dataset.theme === 'dark'), []);
  const toggle = () => { const t = dark ? 'light' : 'dark'; document.documentElement.dataset.theme = t; localStorage.setItem('theme', t); setDark(!dark); };
  return (<button onClick={toggle} className="btn btn-line !px-2.5" aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'} title={dark ? 'Light mode' : 'Dark mode'}>{dark ? <Sun size={18} /> : <Moon size={18} />}</button>);
}
__MB_EOF__
mkdir -p "lib"
cat > "lib/auth.ts" <<'__MB_EOF__'
import { createClient } from '@/lib/supabase/server';
export async function getSession() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { user: null, profile: null as any };
  const { data: profile } = await supabase.from('profiles').select('id, full_name, role').eq('id', user.id).single();
  return { user, profile: profile as any };
}
__MB_EOF__
mkdir -p "lib"
cat > "lib/env.ts" <<'__MB_EOF__'
export const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
export const SUPABASE_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '';
export const hasEnv = () => SUPABASE_URL.startsWith('http') && !SUPABASE_URL.includes('YOUR-PROJECT') && SUPABASE_KEY.length > 20 && !SUPABASE_KEY.startsWith('YOUR-');
__MB_EOF__
mkdir -p "lib"
cat > "lib/services.ts" <<'__MB_EOF__'
export const SERVICES = [
  { key: 'safari', label: 'Wildlife safaris', icon: 'Binoculars', blurb: 'Game drives and Big Five tracking' },
  { key: 'culture', label: 'Cultural and heritage', icon: 'Landmark', blurb: 'Villages, museums and Swahili heritage' },
  { key: 'coast', label: 'Coast and beach', icon: 'Umbrella', blurb: 'Dhow trips, snorkelling and beaches' },
  { key: 'hiking', label: 'Mountain and hiking', icon: 'Mountain', blurb: "Mt Kenya, Hell's Gate and forest walks" },
  { key: 'transfer', label: 'Airport and transfers', icon: 'Plane', blurb: 'Pickups, road transfers and safari vehicles' },
  { key: 'birding', label: 'Birding and photography', icon: 'Camera', blurb: 'Lakes, hides and photo safaris' },
];
export const COMING_SOON = ['Accommodation', 'Park and event tickets', 'Car hire', 'Travel insurance'];
export const CATEGORY_TINT: Record<string, string> = { Safari: '#a8461f', Beach: '#0b4f6c', Mountain: '#1b3a4b', Lake: '#14506b', Culture: '#4a2511', City: '#243b53', Forest: '#17402b' };
export const landing = (role?: string | null) => (role === 'traveler' ? '/dashboard' : '/bookings');
export const safeNext = (n?: string | null) => (n && n.startsWith('/') && !n.startsWith('//') ? n : null);
__MB_EOF__
mkdir -p "lib/supabase"
cat > "lib/supabase/client.ts" <<'__MB_EOF__'
import { createBrowserClient } from '@supabase/ssr';
import { SUPABASE_URL, SUPABASE_KEY } from '@/lib/env';
export const createClient = () => createBrowserClient(SUPABASE_URL, SUPABASE_KEY);
__MB_EOF__
mkdir -p "lib/supabase"
cat > "lib/supabase/middleware.ts" <<'__MB_EOF__'
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import { SUPABASE_URL, SUPABASE_KEY, hasEnv } from '@/lib/env';
const PROTECTED = ['/dashboard', '/providers', '/bookings'];
export async function updateSession(req: NextRequest) {
  let res = NextResponse.next({ request: req });
  if (!hasEnv()) return res;
  const supabase = createServerClient(SUPABASE_URL, SUPABASE_KEY, { cookies: {
    getAll: () => req.cookies.getAll(),
    setAll: (list: { name: string; value: string; options: any }[]) => { list.forEach(({ name, value }) => req.cookies.set(name, value)); res = NextResponse.next({ request: req }); list.forEach(({ name, value, options }) => res.cookies.set(name, value, options)); } } });
  const { data: { user } } = await supabase.auth.getUser();
  const path = req.nextUrl.pathname;
  if (!user && PROTECTED.some((p) => path.startsWith(p))) {
    const url = req.nextUrl.clone(); url.pathname = '/login'; url.search = `?next=${encodeURIComponent(path + req.nextUrl.search)}`;
    return NextResponse.redirect(url);
  }
  return res;
}
__MB_EOF__
mkdir -p "lib/supabase"
cat > "lib/supabase/server.ts" <<'__MB_EOF__'
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { SUPABASE_URL, SUPABASE_KEY } from '@/lib/env';
export function createClient() {
  const store = cookies();
  return createServerClient(SUPABASE_URL, SUPABASE_KEY, { cookies: {
    getAll: () => store.getAll(),
    setAll: (list: { name: string; value: string; options: any }[]) => { try { list.forEach(({ name, value, options }) => store.set(name, value, options)); } catch { /* called from a Server Component: middleware refreshes the session */ } } } });
}
__MB_EOF__
mkdir -p "lib"
cat > "lib/wiki.ts" <<'__MB_EOF__'
// Each destination's photo is the lead image of its own Wikipedia article (free to reuse, credited on Wikipedia). Returns null if none, and the UI falls back to a colour block.
export async function wikiImage(title?: string | null): Promise<string | null> {
  if (!title) return null;
  try {
    const r = await fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`, { headers: { 'User-Agent': 'MtaliiBora/0.2 (student project)', Accept: 'application/json' }, next: { revalidate: 604800 } });
    if (!r.ok) return null;
    const j = await r.json();
    const src: string | undefined = j?.thumbnail?.source;
    return src ? src.replace(/\/\d+px-/, '/960px-') : null;
  } catch { return null; }
}
__MB_EOF__
cat > "middleware.ts" <<'__MB_EOF__'
import type { NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';
export const middleware = (req: NextRequest) => updateSession(req);
export const config = { matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|webp)$).*)'] };
__MB_EOF__
cat > "next.config.mjs" <<'__MB_EOF__'
/** @type {import("next").NextConfig} */
const nextConfig = { optimizeFonts: false };
export default nextConfig;
__MB_EOF__
cat > "package.json" <<'__MB_EOF__'
{ "name": "mtalii-bora", "version": "0.2.0", "private": true,
  "scripts": { "dev": "next dev", "build": "next build", "start": "next start" },
  "dependencies": { "next": "^14.2.35", "react": "^18.3.1", "react-dom": "^18.3.1", "@supabase/ssr": "^0.5.2", "@supabase/supabase-js": "^2.45.4", "lucide-react": "^0.453.0" },
  "devDependencies": { "typescript": "^5.6.3", "@types/node": "^20", "@types/react": "^18", "@types/react-dom": "^18", "tailwindcss": "^3.4.14", "postcss": "^8.4.47", "autoprefixer": "^10.4.20" } }
__MB_EOF__
cat > "postcss.config.mjs" <<'__MB_EOF__'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } };
__MB_EOF__
mkdir -p "scripts"
cat > "scripts/update.sh" <<'__MB_EOF__'
#!/usr/bin/env bash
# Commit and push all changes:  bash scripts/update.sh "your message"
set -e; cd "$(dirname "$0")/.."
if [ -f .git/MERGE_HEAD ] || grep -rlE "^(<<<<<<<|>>>>>>>) " app components lib supabase scripts README.md 2>/dev/null; then
  echo "STOP: unresolved merge or conflict markers found. Fix them first."; exit 1
fi
MSG="${1:-Update Mtalii Bora ($(date '+%Y-%m-%d %H:%M'))}"
git add -A
if git diff --cached --quiet; then echo "No changes to commit."; else git commit -m "$MSG"; fi
git pull --rebase origin main || { echo "Pull had conflicts. Resolve them, then run again."; exit 1; }
git push -u origin main && echo "Pushed to GitHub ✔"
__MB_EOF__
mkdir -p "supabase"
cat > "supabase/schema.sql" <<'__MB_EOF__'
-- Mtalii Bora — Supabase schema. Run once in: Supabase Dashboard > SQL Editor > New query.
create extension if not exists btree_gist;
create type user_role as enum ('traveler','guide','driver','admin');
create type booking_status as enum ('pending','accepted','rejected','completed','cancelled');

create table profiles(id uuid primary key references auth.users(id) on delete cascade, full_name text not null, role user_role not null default 'traveler', created_at timestamptz default now());
create table provider_profiles(id uuid primary key references profiles(id) on delete cascade, type text not null check (type in ('guide','driver')),
  bio text default '', county text default '', languages text default '', rate_usd int default 0 check (rate_usd >= 0), vehicle text default '', license_no text default '',
  services text[] default '{}', verified boolean default false, rating_avg numeric(2,1) default 0, rating_count int default 0);
create table destinations(id serial primary key, name text not null, county text not null, category text not null, description text, activities text, wiki_title text);
create table bookings(id bigserial primary key, traveler_id uuid not null references profiles(id), provider_id uuid not null references provider_profiles(id),
  start_date date not null, end_date date not null, travelers int default 1 check (travelers > 0), note text default '', status booking_status default 'pending', created_at timestamptz default now(),
  check (end_date >= start_date),
  exclude using gist (provider_id with =, daterange(start_date, end_date, '[]') with &&) where (status = 'accepted'));
create table messages(id bigserial primary key, booking_id bigint references bookings(id) on delete cascade, sender_id uuid references profiles(id), body text not null check (length(body) <= 1000), created_at timestamptz default now());
create table itinerary_items(id bigserial primary key, booking_id bigint references bookings(id) on delete cascade, day int not null default 1, start_time time, title text not null, destination_id int references destinations(id), notes text default '');
create table reviews(id bigserial primary key, booking_id bigint unique references bookings(id), provider_id uuid references provider_profiles(id), rating int not null check (rating between 1 and 5), comment text default '', created_at timestamptz default now());
create table notifications(id bigserial primary key, user_id uuid references profiles(id) on delete cascade, body text not null, link text, read boolean default false, created_at timestamptz default now());
create table audit_log(id bigserial primary key, user_id uuid, action text not null, detail text, created_at timestamptz default now());

-- helpers
create function is_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from profiles where id = auth.uid() and role = 'admin') $$;
create function is_party(b bigint) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from bookings where id = b and (traveler_id = auth.uid() or provider_id = auth.uid())) $$;
create function provider_busy(pid uuid) returns table(start_date date, end_date date) language sql stable security definer set search_path = public as $$ select start_date, end_date from bookings where provider_id = pid and status = 'accepted' and end_date >= current_date $$;
create function providers_busy_on(d date) returns setof uuid language sql stable security definer set search_path = public as $$ select provider_id from bookings where status = 'accepted' and d between start_date and end_date $$;
create function set_verified(pid uuid, v boolean) returns void language plpgsql security definer set search_path = public as $$
begin if not is_admin() then raise exception 'Admin only'; end if;
  update provider_profiles set verified = v where id = pid; insert into audit_log(user_id, action, detail) values (auth.uid(), 'provider_verify', pid || '=' || v); end $$;
revoke execute on function provider_busy, providers_busy_on, set_verified from public, anon;
grant execute on function provider_busy, providers_busy_on, set_verified to authenticated;

-- new auth user -> profile (+ provider profile). Role comes from sign-up metadata; 'admin' can never be self-assigned.
create function handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
        r user_role := case when m->>'role' in ('guide','driver') then (m->>'role')::user_role else 'traveler' end;
begin
  insert into profiles(id, full_name, role) values (new.id, coalesce(nullif(m->>'full_name',''), split_part(new.email,'@',1)), r);
  if r in ('guide','driver') then
    insert into provider_profiles(id, type, bio, county, languages, rate_usd, vehicle, license_no, services)
    values (new.id, r::text, coalesce(m->>'bio',''), coalesce(m->>'county',''), coalesce(m->>'languages',''), coalesce(nullif(m->>'rate','')::int, 0),
            coalesce(m->>'vehicle',''), coalesce(m->>'license_no',''), string_to_array(nullif(m->>'services',''), ','));
  end if;
  insert into audit_log(user_id, action, detail) values (new.id, 'register', r::text);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- booking rules: who may change status, notifications and audit trail
create function check_booking() returns trigger language plpgsql as $$
begin
  if new.status <> old.status and auth.uid() is not null and not is_admin() then
    if auth.uid() = old.provider_id and ((old.status = 'pending' and new.status in ('accepted','rejected')) or (old.status = 'accepted' and new.status = 'completed')) then null;
    elsif auth.uid() = old.traveler_id and old.status in ('pending','accepted') and new.status = 'cancelled' then null;
    else raise exception 'This status change is not allowed'; end if;
  end if; return new;
end $$;
create trigger booking_guard before update on bookings for each row execute function check_booking();
create function on_booking_change() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    insert into notifications(user_id, body, link) values (new.provider_id, 'New booking request #' || new.id, '/bookings');
    insert into audit_log(user_id, action, detail) values (new.traveler_id, 'booking_create', '#' || new.id);
  elsif new.status <> old.status then
    insert into notifications(user_id, body, link) values (case when auth.uid() = new.provider_id then new.traveler_id else new.provider_id end, 'Booking #' || new.id || ' is now ' || new.status, '/bookings');
    insert into audit_log(user_id, action, detail) values (auth.uid(), 'booking_' || new.status, '#' || new.id);
  end if; return new;
end $$;
create trigger booking_after after insert or update on bookings for each row execute function on_booking_change();
create function reset_verified() returns trigger language plpgsql security definer set search_path = public as $$
begin if new.license_no is distinct from old.license_no and not is_admin() then new.verified := false; end if; return new; end $$;
create trigger provider_license before update on provider_profiles for each row execute function reset_verified();
create function update_rating() returns trigger language plpgsql security definer set search_path = public as $$
begin update provider_profiles set rating_avg = (select round(avg(rating), 1) from reviews where provider_id = new.provider_id), rating_count = (select count(*) from reviews where provider_id = new.provider_id) where id = new.provider_id; return new; end $$;
create trigger review_after after insert on reviews for each row execute function update_rating();

-- row level security
alter table profiles enable row level security; alter table provider_profiles enable row level security; alter table destinations enable row level security;
alter table bookings enable row level security; alter table messages enable row level security; alter table itinerary_items enable row level security;
alter table reviews enable row level security; alter table notifications enable row level security; alter table audit_log enable row level security;
create policy "profiles read" on profiles for select to authenticated using (true);
create policy "profiles update own" on profiles for update to authenticated using (id = auth.uid());
create policy "providers read" on provider_profiles for select to authenticated using (true);
create policy "providers update own" on provider_profiles for update to authenticated using (id = auth.uid());
create policy "destinations read" on destinations for select to anon, authenticated using (true);
create policy "destinations admin" on destinations for all to authenticated using (is_admin()) with check (is_admin());
create policy "bookings read" on bookings for select to authenticated using (traveler_id = auth.uid() or provider_id = auth.uid() or is_admin());
create policy "bookings insert" on bookings for insert to authenticated with check (traveler_id = auth.uid() and status = 'pending' and exists(select 1 from profiles where id = auth.uid() and role = 'traveler'));
create policy "bookings update" on bookings for update to authenticated using (traveler_id = auth.uid() or provider_id = auth.uid());
create policy "messages read" on messages for select to authenticated using (is_party(booking_id));
create policy "messages insert" on messages for insert to authenticated with check (sender_id = auth.uid() and is_party(booking_id));
create policy "itinerary all" on itinerary_items for all to authenticated using (is_party(booking_id)) with check (is_party(booking_id));
create policy "reviews read" on reviews for select to authenticated using (true);
create policy "reviews insert" on reviews for insert to authenticated with check (exists(select 1 from bookings b where b.id = booking_id and b.traveler_id = auth.uid() and b.status = 'completed' and b.provider_id = reviews.provider_id));
create policy "notifications own" on notifications for select to authenticated using (user_id = auth.uid());
create policy "notifications mark read" on notifications for update to authenticated using (user_id = auth.uid());
create policy "audit admin" on audit_log for select to authenticated using (is_admin());
-- column-level limits: users can only change what they should
revoke update on profiles, provider_profiles, bookings, notifications from authenticated, anon;
grant update(full_name) on profiles to authenticated;
grant update(bio, county, languages, rate_usd, vehicle, license_no, services) on provider_profiles to authenticated;
grant update(status) on bookings to authenticated;
grant update(read) on notifications to authenticated;

-- Kenya destinations (images are loaded from each place's Wikipedia article via wiki_title)
insert into destinations(name, county, category, description, activities, wiki_title) values
('Maasai Mara','Narok','Safari','Great Migration and the Big Five.','Game drives, balloon safari, Maasai village visit','Maasai_Mara'),
('Amboseli','Kajiado','Safari','Elephants beneath Mt Kilimanjaro.','Game drives, bird watching','Amboseli_National_Park'),
('Tsavo East & West','Taita Taveta','Safari','Red elephants and Mzima Springs.','Game drives, Mudanda Rock','Tsavo_East_National_Park'),
('Samburu Reserve','Samburu','Safari','Grevy''s zebra and northern species.','Game drives, cultural visits','Samburu_National_Reserve'),
('Ol Pejeta','Laikipia','Safari','Last northern white rhinos.','Rhino tracking, chimp sanctuary','Ol_Pejeta_Conservancy'),
('Nairobi National Park','Nairobi','City','Wildlife beside the skyline.','Game drives, giraffe centre','Nairobi_National_Park'),
('Giraffe Centre','Nairobi','City','Feed giraffes at eye level.','Giraffe feeding, nature trail','Giraffe_Centre'),
('Lake Nakuru','Nakuru','Lake','Rhinos and flamingo shores.','Game drives, Baboon Cliff','Lake_Nakuru_National_Park'),
('Lake Naivasha','Nakuru','Lake','Boat rides, hippos and Hell''s Gate cycling.','Boat rides, cycling','Lake_Naivasha'),
('Lake Bogoria','Baringo','Lake','Geysers, hot springs and flamingos.','Geyser viewing, bird watching','Lake_Bogoria'),
('Lake Turkana','Turkana','Lake','The Jade Sea, a UNESCO site.','Cultural tours, fossil sites','Lake_Turkana'),
('Mount Kenya','Nyeri','Mountain','Africa''s second-highest peak.','Trekking, camping','Mount_Kenya'),
('Aberdare Ranges','Nyandarua','Mountain','Waterfalls and moorland.','Hiking, Karuru Falls','Aberdare_National_Park'),
('Mount Elgon','Trans Nzoia','Mountain','Caves and volcano hikes.','Hiking, Kitum Cave','Mount_Elgon'),
('Kakamega Forest','Kakamega','Forest','Equatorial rainforest and primates.','Guided walks, bird watching','Kakamega_Forest'),
('Kisumu & Lake Victoria','Kisumu','Lake','Sunsets, fishing, Impala Sanctuary.','Boat trips, Dunga beach','Kisumu'),
('Tabaka Soapstone','Kisii','Culture','Home of Kisii soapstone carving.','Craft tours, carving workshops','Tabaka'),
('Diani Beach','Kwale','Beach','White sand, kitesurfing, dhows.','Snorkelling, kitesurfing','Diani_Beach'),
('Watamu & Malindi','Kilifi','Beach','Marine park, reefs and Gedi Ruins.','Snorkelling, Gedi Ruins','Watamu'),
('Lamu Old Town','Lamu','Culture','UNESCO Swahili settlement.','Dhow cruises, donkey tours','Lamu'),
('Fort Jesus','Mombasa','Culture','16th-century fort and spice markets.','Fort tour, old town walk','Fort_Jesus'),
('Shimba Hills','Kwale','Forest','Coastal rainforest, sable antelope.','Walks, Sheldrick Falls','Shimba_Hills_National_Reserve'),
('Chyulu Hills','Makueni','Mountain','Green volcanic hills.','Walking safaris, lava tubes','Chyulu_Hills');
-- After you register your own account, make it admin by running:
--   update profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL');
__MB_EOF__
cat > "tailwind.config.ts" <<'__MB_EOF__'
import type { Config } from 'tailwindcss';
const v = (n: string) => `var(--${n})`;
export default { content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'], theme: { extend: {
  colors: { bg: v('bg'), surface: v('surface'), soft: v('soft'), line: v('line'), ink: v('ink'), muted: v('muted'), forest: v('forest'), clay: v('clay'), 'clay-ink': v('clay-ink') },
  fontFamily: { display: ['Fraunces', 'Georgia', 'serif'], sans: ['Figtree', 'system-ui', 'sans-serif'] } } }, plugins: [] } satisfies Config;
__MB_EOF__
cat > "tsconfig.json" <<'__MB_EOF__'
{ "compilerOptions": { "target": "ES2020", "lib": ["dom", "dom.iterable", "esnext"], "allowJs": false, "skipLibCheck": true, "strict": true, "noEmit": true, "esModuleInterop": true, "module": "esnext",
  "moduleResolution": "bundler", "resolveJsonModule": true, "isolatedModules": true, "jsx": "preserve", "incremental": true, "plugins": [{ "name": "next" }], "paths": { "@/*": ["./*"] } },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"], "exclude": ["node_modules"] }
__MB_EOF__
echo "Wrote the Next.js project files."
if [ "$PUSH" = 1 ]; then
  [ -d .git ] || git init -q
  git symbolic-ref HEAD refs/heads/main
  git config core.autocrlf false
  if git remote get-url origin >/dev/null 2>&1; then git remote set-url origin "$REPO"; else git remote add origin "$REPO"; fi
  git fetch -q origin main 2>/dev/null || echo "(remote has no main branch yet)"
  if ! git rev-parse -q --verify HEAD >/dev/null 2>&1 && git rev-parse -q --verify origin/main >/dev/null 2>&1; then git reset -q --soft origin/main; fi
  git add -A
  if git diff --cached --quiet; then echo "Nothing new to commit."; else
    git commit -q -m "$MSG" || { echo "Git needs your identity. Run:"; echo '  git config --global user.name "Your Name"'; echo '  git config --global user.email "you@example.com"'; echo "then rerun this script with --push"; exit 1; }
  fi
  git push -u origin main && echo "Pushed to $REPO ✔" || { echo "Push failed. If it says 'fetch first', run: git pull --rebase origin main   then: git push"; exit 1; }
fi
cat <<'MSG2'

Next steps:
  1. Supabase: create a project and run supabase/schema.sql in the SQL Editor (see README.md).
  2. cp .env.local.example .env.local   and paste your Project URL and anon key.
  3. npm install
  4. npm run dev        ->  http://localhost:3000
MSG2
