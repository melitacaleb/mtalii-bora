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
