// ============================================================================
// WEEKLY DISCOVERY JOB (TMDB + TRAKT)
// Ultra-strenger Trash-TV Filter + TRAKT nur DEUTSCHE Shows
// ============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// --- SUPABASE ---
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
// --- API KEYS ---
const TMDB_API_KEY = Deno.env.get("TMDB_API_KEY");
const TRAKT_CLIENT_ID = Deno.env.get("TRAKT_CLIENT_ID");
const TMDB_URL = "https://api.themoviedb.org/3";
const TRAKT_BASE = "https://api.trakt.tv";
// ============================================================================
// HELPERS
// ============================================================================
function makeSlug(title, year) {
  return (title + (year ? "-" + year : "")).normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-zA-Z0-9]+/g, "-").replace(/(^-|-$)/g, "").toLowerCase();
}
function traktHeaders() {
  return {
    "Content-Type": "application/json",
    "trakt-api-version": "2",
    "trakt-api-key": TRAKT_CLIENT_ID
  };
}
// ============================================================================
// ULTRA-STRICT TRASH-TV FILTER
// ============================================================================
// ❌ 1. Harte Ausschlussliste (NIEMALS Trash)
const EXCLUDE = [
  "wissenschaft",
  "lexikon",
  "kosmos",
  "geschichte",
  "politik",
  "magazin",
  "nachrichten",
  "report",
  "reportage",
  "terra",
  "zdf",
  "ard",
  "tiere",
  "tier",
  "natur",
  "universum",
  "weltall",
  "technik",
  "medizin",
  "doku",
  "galileo",
  "planet",
  "bildung",
  "satire",
  "kabarett",
  "comedy",
  "talkshow",
  "schule",
  "lernen"
];
const HARD_TRASH = [
  // Dating & Flirt
  "love island",
  "are you the one",
  "are you the one vip",
  "temptation island",
  "temptation island vip",
  "make love fake love",
  "fboy island",
  "love is blind germany",
  "bachelor",
  "die bachelorette",
  "bachelor in paradise",
  // Promi‑ & Gruppenchallenges
  "the 50",
  "couple challenge",
  "promis unter palmen",
  "reality queens",
  "reality star academy",
  "reality backpackers",
  "forsthaus rampensau",
  "germany shore",
  "most wanted",
  // Klassiker & Dauerbrenner
  "dschungelcamp",
  "ich bin ein star holt mich hier raus",
  "sommerhaus der stars",
  // Wettbewerbe mit trashigem Charakter
  "germanys next topmodel",
  "let's dance",
  "das große promibacken",
  // Sonstige Trash‑Entertainment‑Formate
  "the race",
  "promihof",
  "bauer sucht frau",
  "bauer sucht frau international",
  // Reality‑Soaps / Doku‑Trash
  "die ochsenknechts"
];
``;
// ============================================================================
// TRASH DECISION LOGIC
// ============================================================================
function isTrashShow(show) {
  const text = (show.name + " " + (show.overview || "")).toLowerCase();
  if (EXCLUDE.some((w)=>text.includes(w))) return false;
  if (HARD_TRASH.some((w)=>text.includes(w))) return true;
  return false;
}
// ============================================================================
// TMDB DISCOVERY
// ============================================================================
async function fetchGermanShows() {
  const all = [];
  let page = 1;
  while(page <= 1000){
    const url = `${TMDB_URL}/discover/tv?api_key=${TMDB_API_KEY}` + `&with_original_language=de&with_origin_country=DE` + `&include_adult=false&sort_by=popularity.desc` + `&first_air_date.gte=2000-01-01&page=${page}`;
    const r = await fetch(url);
    const d = await r.json();
    if (!d?.results?.length) break;
    all.push(...d.results);
    if (page >= d.total_pages) break;
    page++;
  }
  return all;
}
// ============================================================================
// TRAKT DISCOVERY WITH DE FILTER
// ============================================================================
/**
async function fetchTraktDetails(slug: string) {
  const r = await fetch(`${TRAKT_BASE}/shows/${slug}?extended=full`, {
    headers: traktHeaders(),
  });
  if (!r.ok) return null;
  return await r.json();
}

async function fetchTraktTrashGerman() {
  const r = await fetch(
    `${TRAKT_BASE}/shows/popular?extended=full&limit=300`,
    { headers: traktHeaders() }
  );

  const raw = await r.json();
  const germanResults = [];

  for (const s of raw) {
    if (!isTrashShow({ name: s.title, overview: s.overview })) continue;

    const details = await fetchTraktDetails(s.ids.slug);
    if (!details) continue;

    const isGerman =
      details.country === "de" ||
      details.language === "de" ||
      (details.translations || []).some((t: any) => t.language === "de");

    if (!isGerman) continue;

    germanResults.push({
      title: s.title,
      overview: s.overview,
      year: s.year,
      slug: s.ids.slug,
    });
  }

  return germanResults;
}
*/ async function fetchTraktSlugByTmdbId(tmdbId) {
  const r = await fetch(`${TRAKT_BASE}/search/tmdb/${tmdbId}?type=show`, {
    headers: traktHeaders()
  });
  if (!r.ok) return null;
  const j = await r.json();
  return j?.[0]?.show?.ids?.slug || null;
}
// ============================================================================
// MAIN PIPELINE
// ============================================================================
Deno.serve(async ()=>{
  console.log("🚀 Ultra-strict Trash-TV Weekly Discovery gestartet…");
  // ========================================================================
  // 1. TMDB
  // ========================================================================
  const tmdbRaw = await fetchGermanShows();
  const tmdbTrash = tmdbRaw.filter(isTrashShow);
  console.log(`📺 TMDB TRASH (DE): ${tmdbTrash.length}`);
  const tmdbSlugs = new Set();
  for (const s of tmdbTrash){
    const slug = makeSlug(s.name, s.first_air_date?.slice(0, 4));
    tmdbSlugs.add(slug);
    const { data: row } = await supabase.from("shows").upsert({
      slug,
      title: s.name,
      description: s.overview || "",
      genre: "Reality",
      tmdb_id: String(s.id),
      trakt_slug: null,
      status: "active",
      updated_at: new Date().toISOString()
    }, {
      onConflict: "slug"
    }).select().single();
    const traktSlug = await fetchTraktSlugByTmdbId(s.id);
    await supabase.from("shows").update({
      trakt_slug: traktSlug,
      updated_at: new Date().toISOString()
    }).eq("id", row.id);
    console.log(`✔ TMDB → ${s.name}`);
  }
  // ========================================================================
  // 2. TRAKT — DE ONLY
  // ========================================================================
  /**
  const traktShows = await fetchTraktTrashGerman();
  console.log(`📺 TRAKT TRASH (DE): ${traktShows.length}`);

  for (const t of traktShows) {
    const slug = makeSlug(t.title, t.year?.toString());
    if (tmdbSlugs.has(slug)) continue;

    console.log(`➕ TRAKT ergänzt (DE): ${t.title}`);

    await supabase.from("shows").upsert(
      {
        slug,
        title: t.title,
        description: t.overview || "",
        genre: "Reality",
        tmdb_id: null,
        trakt_slug: t.slug,
        status: "active",
        updated_at: new Date().toISOString(),
      },
      { onConflict: "slug" }
    );
  }

  */ console.log("🎉 Discovery abgeschlossen (DE‑Trash‑TV ONLY)");
  return new Response("OK");
});
