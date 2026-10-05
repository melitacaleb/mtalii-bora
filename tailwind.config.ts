import type { Config } from 'tailwindcss';
const v = (n: string) => `var(--${n})`;
export default { content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'], theme: { extend: {
  colors: { bg: v('bg'), surface: v('surface'), soft: v('soft'), line: v('line'), ink: v('ink'), muted: v('muted'), forest: v('forest'), clay: v('clay'), 'clay-ink': v('clay-ink') },
  fontFamily: { display: ['Fraunces', 'Georgia', 'serif'], sans: ['Figtree', 'system-ui', 'sans-serif'] } } }, plugins: [] } satisfies Config;
