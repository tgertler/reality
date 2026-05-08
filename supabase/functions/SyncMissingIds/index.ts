// ============================================================================
// SYNC MISSING TMDB + TRAKT IDS FOR MANUALLY ADDED SHOWS (Optimized)
// ============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
// API Keys
const TMDB_API_KEY = Deno.env.get("TMDB_API_KEY");
const TRAKT_CLIENT_ID = Deno.env.get("TRAKT_CLIENT_ID");
const TMDB_URL = "https://api.themoviedb.org/3";
const TRAKT_URL = "https://api.trakt.tv";
// ============================================================================
// HELPERS
// ============================================================================
function traktHeaders() {
  return {
    "Content-Type": "application/json",
    "trakt-api-version": "2",
    "trakt-api-key": TRAKT_CLIENT_ID
  };
}
// Cache für TMDB-Suchresultate
const tmdbCache = new Map();
async function searchTmdb(title) {
  if (tmdbCache.has(title)) return tmdbCache.get(title);
  async function query(lang) {
    const url = `${TMDB_URL}/search/tv?api_key=${TMDB_API_KEY}&query=${encodeURIComponent(title)}&language=${lang}`;
    const r = await fetch(url);
    if (!r.ok) return [];
    const j = await r.json();
    return j?.results ?? [];
  }
  // 1. Deutsch priorisieren
  const deResults = await query("de-DE");
  // A: Zuerst deutsche Produktionen (origin_country == "DE")
  let germanProductions = deResults.filter((r)=>r.origin_country?.includes("DE"));
  if (germanProductions.length) {
    // Exakte deutsche Matches bevorzugen
    let exact = germanProductions.find((r)=>r.name?.toLowerCase() === title.toLowerCase() || r.original_name?.toLowerCase() === title.toLowerCase());
    tmdbCache.set(title, exact || germanProductions[0]);
    return exact || germanProductions[0];
  }
  // B: Falls keine DE-Produktion, aber deutscher Titel existiert
  let exactGermanTitle = deResults.find((r)=>r.name?.toLowerCase() === title.toLowerCase() || r.original_name?.toLowerCase() === title.toLowerCase());
  if (exactGermanTitle) {
    tmdbCache.set(title, exactGermanTitle);
    return exactGermanTitle;
  }
  // 2. Fallback Englisch
  const enResults = await query("en-US");
  let exactEnglish = enResults.find((r)=>r.name?.toLowerCase() === title.toLowerCase() || r.original_name?.toLowerCase() === title.toLowerCase());
  let result = exactEnglish || enResults[0] || null;
  tmdbCache.set(title, result);
  return result;
}
async function fetchTraktSlugByTmdbId(tmdbId) {
  const r = await fetch(`${TRAKT_URL}/search/tmdb/${tmdbId}?type=show`, {
    headers: traktHeaders()
  });
  if (!r.ok) return null;
  const j = await r.json();
  return j?.[0]?.show?.ids?.slug || null;
}
// ============================================================================
// MAIN
// ============================================================================
Deno.serve(async ()=>{
  console.log("🚀 Starte optimierten ID-Sync…");
  const { data: shows } = await supabase.from("shows").select("*").or("tmdb_id.is.null,trakt_slug.is.null");
  if (!shows?.length) {
    return new Response("Keine fehlenden IDs gefunden.");
  }
  console.log(`📌 ${shows.length} Shows benötigen Updates`);
  for (const s of shows){
    console.log(`\n➡️ ${s.title}`);
    let tmdbId = s.tmdb_id;
    // ---------------------------------------------------------------
    // TMDB ID finden
    // ---------------------------------------------------------------
    if (!tmdbId) {
      const tmdb = await searchTmdb(s.title);
      if (tmdb) {
        tmdbId = tmdb.id;
        console.log(`✔ TMDB gefunden: ${tmdbId}`);
        await supabase.from("shows").update({
          tmdb_id: String(tmdbId),
          updated_at: new Date().toISOString()
        }).eq("id", s.id);
      } else {
        console.log("❌ Keine TMDB ID gefunden");
      }
    }
    // ---------------------------------------------------------------
    // TRAKT Slug
    // ---------------------------------------------------------------
    if (tmdbId && !s.trakt_slug) {
      console.log("⏳ Hole TRAKT Slug…");
      const slug = await fetchTraktSlugByTmdbId(Number(tmdbId));
      if (slug) {
        console.log(`✔ TRAKT Slug: ${slug}`);
        await supabase.from("shows").update({
          trakt_slug: slug,
          updated_at: new Date().toISOString()
        }).eq("id", s.id);
      } else {
        console.log("❌ Kein TRAKT Slug gefunden");
      }
    }
  }
  console.log("\n🎉 Optimierter Sync abgeschlossen!");
  return new Response("OK");
});
