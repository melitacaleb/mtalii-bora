import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';
import AutoRefresh from '@/components/AutoRefresh';
import { markRead } from './actions';
export default async function Notifications() {
  const { user } = await getSession(); if (!user) redirect('/login?next=/notifications');
  const { data } = await createClient().from('notifications').select('*').order('created_at', { ascending: false }).limit(50); const list: any[] = data ?? []; const unread = list.filter((n) => !n.read).length;
  return (<div className="space-y-4"><AutoRefresh seconds={15} /><div className="flex flex-wrap items-center justify-between gap-2"><h1 className="text-3xl">Notifications</h1>{unread > 0 && <form action={markRead}><button className="btn btn-line">Mark all {unread} as read</button></form>}</div>
    <ul className="panel divide-y divide-line">{list.map((n) => (<li key={n.id} className={`flex items-center gap-3 p-4 ${n.read ? '' : 'bg-soft font-medium'}`}><span className={`h-2.5 w-2.5 shrink-0 rounded-full ${n.read ? 'bg-transparent' : 'bg-[var(--clay)]'}`} aria-label={n.read ? 'Read' : 'Unread'} />
      <span className="flex-1">{n.link ? <Link href={n.link} className="underline-offset-4 hover:underline">{n.body}</Link> : n.body}<span className="block text-xs font-normal text-muted">{new Date(n.created_at).toLocaleString('en-KE', { dateStyle: 'medium', timeStyle: 'short' })}</span></span>
      {!n.read && <form action={markRead}><input type="hidden" name="id" value={n.id} /><button className="text-sm underline">Mark read</button></form>}</li>))}
      {!list.length && <li className="p-6 text-muted">You are all caught up.</li>}</ul></div>);
}
