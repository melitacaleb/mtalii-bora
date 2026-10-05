import './globals.css';
import type { Metadata } from 'next';
import Shell from '@/components/Shell';
export const metadata: Metadata = { title: 'Mtalii Bora — verified guides and safari drivers in Kenya', description: 'Book verified local tour guides and safari drivers across Kenya, chat with them and plan your itinerary together.' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (<html lang="en" suppressHydrationWarning><head>
    <link rel="preconnect" href="https://fonts.googleapis.com" /><link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
    <link href="https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,600;9..144,700&display=swap" rel="stylesheet" />
    <script dangerouslySetInnerHTML={{ __html: "try{var t=localStorage.getItem('theme')||(matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');document.documentElement.dataset.theme=t}catch(e){}" }} />
  </head><body><Shell>{children}</Shell></body></html>);
}
