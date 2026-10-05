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
