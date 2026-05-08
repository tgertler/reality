import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// --- SUPABASE ---
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
// --- API KEYS ---
const TMDB_API_KEY = "63b7767c7b8dd22eef101cc23a83c399";
const TRAKT_CLIENT_ID = "833c188f77b2a44efa078c4f2075e55af1e85d0786fd5d3809ac5036bb9adac9";
// --- CONSTANTS ---
const TMDB_URL = "https://api.themoviedb.org/3";
const TRAKT_BASE = "https://api.trakt.tv";
// ------------------------------------------
// HELPERS
// ------------------------------------------
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
// ------------------------------------------
// 1️⃣ TMDB: HOLE ALLE DEUTSCHEN SHOWS (Breit!)
// ------------------------------------------
async function fetchGermanShows() {
  const allResults = [];
  let page = 1;
  while(page <= 1000){
    const url = `${TMDB_URL}/discover/tv` + `?api_key=${TMDB_API_KEY}` + `&with_original_language=de` + // Deutsche Sprache
    `&with_origin_country=DE` + // Deutsche Produktion
    `&include_adult=false` + // Kein Erotik-Content
    `&sort_by=popularity.desc` + `&first_air_date.gte=1990-01-01` + `&page=${page}`;
    const res = await fetch(url);
    const data = await res.json();
    if (!data?.results?.length) break;
    console.log(`TMDb Seite ${page}/${data.total_pages} — ${data.results.length} Shows`);
    allResults.push(...data.results);
    if (page >= data.total_pages) break;
    page++;
  }
  return allResults;
}
// ------------------------------------------
// 2️⃣ TRASH FILTER ENGINE
// ------------------------------------------
// Genre-IDs, die typisch für Trash-TV sind:
const TRASH_GENRES = new Set([
  10764,
  99,
  10767,
  10766,
  35,
  18 // Drama (Scripted Reality)
]);
// Begriffe, die trashiges TV stark indizieren
const TRASH_KEYWORDS = [
  "reality",
  "dating",
  "couple",
  "villa",
  "insel",
  "island",
  "love",
  "ex",
  "singles",
  "paradies",
  "challenge",
  "trash",
  "sommerhaus",
  "promi",
  "celebrity",
  "match",
  "beauty",
  "model",
  "fake",
  "soap"
];
function isTrashShow(show) {
  const text = (show.name + " " + show.overview).toLowerCase();
  // 1) Keyword-Analyse
  if (TRASH_KEYWORDS.some((k)=>text.includes(k))) return true;
  // 2) Genre-Analyse
  if (show.genre_ids?.some((id)=>TRASH_GENRES.has(id))) return true;
  // 3) Format-Länge (Trash Shows: oft < 40 Min)
  if (show.episode_run_time?.[0] && show.episode_run_time[0] < 40) return true;
  return false;
}
// ------------------------------------------
// 3️⃣ TMDB DETAIL FETCHER
// ------------------------------------------
async function fetchShowDetails(tmdbId) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}?api_key=${TMDB_API_KEY}&language=de-DE`);
  return await res.json();
}
async function fetchSeasonEpisodes(tmdbId, seasonNum) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}/season/${seasonNum}?api_key=${TMDB_API_KEY}&language=de-DE`);
  if (!res.ok) return [];
  return (await res.json()).episodes || [];
}
async function fetchStreamingPlatform(tmdbId) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}/watch/providers?api_key=${TMDB_API_KEY}`);
  const data = await res.json();
  return data.results?.DE?.flatrate?.[0]?.provider_name || null;
}
// ------------------------------------------
// 4️⃣ TRAKT
// ------------------------------------------
async function fetchTraktSlugByTmdbId(tmdbId) {
  console.log(`🔎 [Trakt] Suche nach TMDb-ID: ${tmdbId}`);
  const res = await fetch(`${TRAKT_BASE}/search/tmdb/${tmdbId}?type=show`, {
    headers: traktHeaders()
  });
  if (!res.ok) return null;
  const json = await res.json();
  return json?.[0]?.show?.ids?.slug || null;
}
async function fetchTraktSeasonEpisodes(slug, seasonNum) {
  const res = await fetch(`${TRAKT_BASE}/shows/${slug}/seasons/${seasonNum}?extended=episodes`, {
    headers: traktHeaders()
  });
  if (!res.ok) return null;
  return await res.json();
}
// ------------------------------------------
// 5️⃣ EPISODE MERGE
// ------------------------------------------
function mergeEpisodeAirDates(tmdbEpisodes, traktEpisodes) {
  const map = new Map();
  tmdbEpisodes.forEach((e)=>{
    if (e.episode_number && e.air_date) {
      map.set(e.episode_number, e.air_date);
    }
  });
  if (traktEpisodes) {
    traktEpisodes.forEach((e)=>{
      const date = e.first_aired?.split("T")[0];
      if (e.number && date) map.set(e.number, date);
    });
  }
  return [
    ...map.entries()
  ].map(([episode_number, air_date])=>({
      episode_number,
      air_date
    }));
}
// ------------------------------------------
// 6️⃣ RELEASE FREQUENCY
// ------------------------------------------
function estimateReleaseFrequency(episodes) {
  if (episodes.length < 3) return null;
  const dates = episodes.map((e)=>new Date(e.air_date)).filter((d)=>!isNaN(d.getTime())).sort((a, b)=>a.getTime() - b.getTime());
  if (dates.length < 3) return null;
  const gaps = [];
  for(let i = 1; i < dates.length; i++){
    gaps.push((dates[i].getTime() - dates[i - 1].getTime()) / 86400000);
  }
  const avg = gaps.reduce((a, b)=>a + b, 0) / gaps.length;
  if (avg <= 2) return "daily";
  if (avg <= 10) return "weekly";
  if (avg <= 35) return "monthly";
  return null;
}
// ------------------------------------------
// 7️⃣ MAIN PIPELINE
// ------------------------------------------
Deno.serve(async ()=>{
  console.log("🚀 Starte Import...");
  // --- ALLE Deutschen Shows laden ---
  const rawShows = await fetchGermanShows();
  // --- Lokal auf Trash filtern ---
  const shows = rawShows.filter(isTrashShow);
  console.log(`📺 Trash Shows gefunden: ${shows.length}`);
  let totalShows = 0;
  let totalSeasons = 0;
  for (const s of shows){
    const { name, overview, first_air_date, id: tmdbId } = s;
    const slugLocal = makeSlug(name, first_air_date?.slice(0, 4));
    console.log(`\n📺 ${name} (${slugLocal})`);
    // Supabase: Show speichern
    const { data: showData } = await supabase.from("shows").upsert({
      slug: slugLocal,
      title: name,
      description: overview,
      genre: "Reality",
      status: "active"
    }, {
      onConflict: "slug"
    }).select().single();
    const showId = showData.id;
    totalShows++;
    // TMDb Details
    const details = await fetchShowDetails(tmdbId);
    const episodeLength = details.episode_run_time?.[0] || 60;
    // Trakt Slug
    const traktSlug = await fetchTraktSlugByTmdbId(tmdbId);
    for (const season of details.seasons || []){
      if (season.season_number <= 0) continue;
      const tmdbEpisodes = await fetchSeasonEpisodes(tmdbId, season.season_number);
      let traktEpisodes = [];
      if (traktSlug) {
        const t = await fetchTraktSeasonEpisodes(traktSlug, season.season_number);
        traktEpisodes = t?.[0]?.episodes || [];
      }
      const merged = mergeEpisodeAirDates(tmdbEpisodes, traktEpisodes);
      const frequency = estimateReleaseFrequency(merged);
      const platform = await fetchStreamingPlatform(tmdbId);
      await supabase.from("seasons").upsert({
        show_id: showId,
        season_number: season.season_number,
        total_episodes: season.episode_count || 0,
        streaming_release_date: season.air_date,
        streaming_release_time: "00:00:01",
        episode_length: episodeLength,
        release_frequency: frequency,
        streaming_option: platform,
        status: "incomplete"
      }, {
        onConflict: "show_id,season_number"
      });
      totalSeasons++;
    }
  }
  console.log(`\n🎉 Fertig: ${totalShows} Trash Shows, ${totalSeasons} Staffeln`);
  return new Response(JSON.stringify({
    success: true,
    shows: totalShows,
    seasons: totalSeasons
  }), {
    status: 200
  });
});
