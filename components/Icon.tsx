import * as L from 'lucide-react'; // server-only: keeps icons out of the client bundle
export default function Icon({ name, ...p }: { name: string; size?: number; className?: string }) { const C = (L as any)[name]; return C ? <C {...p} /> : null; }
