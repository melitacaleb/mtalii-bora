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
    const { data, error } = await createClient().auth.signUp({ email: String(f.get('email')).trim(), password: String(f.get('password')), options: { emailRedirectTo: `${location.origin}/auth/callback?next=/provider`, data: {
      role, full_name: f.get('name'), county: f.get('county'), languages: f.get('languages'), rate: f.get('rate'), license_no: f.get('license_no'), vehicle: f.get('vehicle') ?? '', bio: f.get('bio') ?? '', services: f.getAll('services').join(',') } } });
    setBusy(false); if (error) return setErr(error.message);
    if (data.session) { router.replace('/provider'); router.refresh(); } else setDone(true);
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
