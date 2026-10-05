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
