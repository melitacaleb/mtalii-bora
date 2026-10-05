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
