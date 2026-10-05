// Each destination's photo is the lead image of its own Wikipedia article (free to reuse, credited on Wikipedia). Returns null if none, and the UI falls back to a colour block.
export async function wikiImage(title?: string | null): Promise<string | null> {
  if (!title) return null;
  try {
    const r = await fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`, { headers: { 'User-Agent': 'MtaliiBora/0.2 (student project)', Accept: 'application/json' }, next: { revalidate: 604800 } });
    if (!r.ok) return null;
    const j = await r.json();
    const src: string | undefined = j?.thumbnail?.source;
    return src ? src.replace(/\/\d+px-/, '/960px-') : null;
  } catch { return null; }
}
