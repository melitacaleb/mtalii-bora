import Link from 'next/link';
import { notFound } from 'next/navigation';
import ProviderWizard from '@/components/ProviderWizard';
export default function JoinRole({ params }: { params: { role: string } }) {
  if (params.role !== 'guide' && params.role !== 'driver') notFound();
  return (<div className="mx-auto max-w-3xl space-y-4"><Link href="/join" className="text-sm font-semibold text-clay underline">Back to provider overview</Link>
    <h1 className="text-3xl">{params.role === 'guide' ? 'Tour guide application' : 'Safari driver application'}</h1><ProviderWizard role={params.role} /></div>);
}
