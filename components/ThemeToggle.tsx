'use client';
import { useEffect, useState } from 'react';
import { Moon, Sun } from 'lucide-react';
export default function ThemeToggle() {
  const [dark, setDark] = useState(false);
  useEffect(() => setDark(document.documentElement.dataset.theme === 'dark'), []);
  const toggle = () => { const t = dark ? 'light' : 'dark'; document.documentElement.dataset.theme = t; localStorage.setItem('theme', t); setDark(!dark); };
  return (<button onClick={toggle} className="btn btn-line !px-2.5" aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'} title={dark ? 'Light mode' : 'Dark mode'}>{dark ? <Sun size={18} /> : <Moon size={18} />}</button>);
}
