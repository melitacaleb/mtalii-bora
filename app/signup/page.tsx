import Link from 'next/link';
import SignupForm from '@/components/SignupForm';
export default function Signup() {
  return (<div className="mx-auto max-w-md"><div className="panel p-6"><h1 className="text-3xl">Create a traveler account</h1><p className="mb-4 mt-1 text-muted">Free. You can book guides and drivers straight away.</p>
    <SignupForm /><p className="mt-5 text-sm">Already registered? <Link className="font-semibold text-clay underline" href="/login">Log in</Link>. Prefer Google? Use the button on the <Link className="font-semibold text-clay underline" href="/login">log in page</Link>.</p></div></div>);
}
