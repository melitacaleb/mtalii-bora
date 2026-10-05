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
