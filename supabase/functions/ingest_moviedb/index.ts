import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const TMDB_API_KEY = "63b7767c7b8dd22eef101cc23a83c399";
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const TMDB_URL = "https://api.themoviedb.org/3/discover/tv";
function makeSlug(title, year) {
  return (title + (year ? "-" + year : "")).normalize("NFD") // trennt Umlaute
  .replace(/[\u0300-\u036f]/g, "") // entfernt Akzente
  .replace(/[^a-zA-Z0-9]+/g, "-") // ersetzt Sonderzeichen durch -
  .replace(/(^-|-$)/g, "") // entfernt führende/trailende -
  .toLowerCase();
}
async function fetchRealityShows() {
  const allResults = [];
  let page = 1;
  let totalPages = 1;
  do {
    const res = await fetch(`https://api.themoviedb.org/3/discover/tv?api_key=${TMDB_API_KEY}` + `&with_genres=10764` + // Reality-TV
    `&with_original_language=de` + // Nur deutschsprachige Shows
    `&with_original_language=en` + // Nur deutschsprachige Shows
    `&watch_region=DE` + // In Deutschland verfügbar
    `&language=de-DE` + // API-Antwort auf Deutsch
    `&sort_by=first_air_date.desc` + // Neueste zuerst
    `&first_air_date.gte=2000-01-01` + // ab Jahr 2024
    `&page=${page}`);
    if (!res.ok) throw new Error(`TMDb request failed: ${res.status}`);
    const data = await res.json();
    totalPages = data.total_pages;
    allResults.push(...data.results);
    console.log(`Seite ${page}/${totalPages} geladen (${data.results.length} Shows)`);
    page++;
  }while (page <= totalPages && page <= 1000) // optional: begrenzen, z. B. max 10 Seiten
  return allResults;
}
/**
 * Holt Details zu einer Show
 */ async function fetchShowDetails(tmdbId) {
  const res = await fetch(`https://api.themoviedb.org/3/tv/${tmdbId}?api_key=${TMDB_API_KEY}&language=de-DE`);
  return await res.json();
}
function estimateReleaseFrequency(episodes) {
  if (!episodes || episodes.length < 3) return null;
  const airDates = episodes.map((e)=>new Date(e.air_date)).filter((d)=>!isNaN(d.getTime())).sort((a, b)=>a.getTime() - b.getTime());
  if (airDates.length < 3) return null;
  const gaps = [];
  for(let i = 1; i < airDates.length; i++){
    const diffDays = (airDates[i].getTime() - airDates[i - 1].getTime()) / (1000 * 60 * 60 * 24);
    gaps.push(diffDays);
  }
  const avgGap = gaps.reduce((a, b)=>a + b, 0) / gaps.length;
  const variance = Math.sqrt(gaps.map((g)=>Math.pow(g - avgGap, 2)).reduce((a, b)=>a + b, 0) / gaps.length);
  // Wenn die Lücken zu inkonsistent sind → lieber null
  if (variance > 2) return null;
  if (avgGap <= 2) return "daily";
  if (avgGap <= 10) return "weekly";
  if (avgGap <= 35) return "monthly";
  return null;
}
async function fetchSeasonEpisodes(tmdbId, seasonNumber) {
  const res = await fetch(`https://api.themoviedb.org/3/tv/${tmdbId}/season/${seasonNumber}?api_key=${TMDB_API_KEY}&language=de-DE`);
  if (!res.ok) return [];
  const data = await res.json();
  return data.episodes || [];
}
async function fetchStreamingPlatform(tmdbId) {
  const res = await fetch(`https://api.themoviedb.org/3/tv/${tmdbId}/watch/providers?api_key=${TMDB_API_KEY}`);
  if (!res.ok) {
    console.error(`Fehler beim Abrufen der Streaming-Plattformen für TMDb-ID ${tmdbId}`);
    return null;
  }
  const data = await res.json();
  // Prüfe, ob es Anbieter für Deutschland gibt
  const providers = data.results?.DE?.flatrate || [];
  if (providers.length > 0) {
    // Nimm die erste Plattform (oder passe die Logik an, um eine bestimmte Plattform zu priorisieren)
    return providers[0].provider_name;
  }
  return null; // Keine Plattform gefunden
}
Deno.serve(async ()=>{
  console.log("Starte Import der Trash-TV-Daten...");
  const shows = await fetchRealityShows();
  console.log(`TMDb lieferte ${shows.length} Shows`);
  let totalSeasons = 0;
  let totalShows = 0;
  for (const s of shows){
    const { name, overview, first_air_date, id: tmdbId } = s;
    //if (!isTrashTv(name + " " + overview)) continue; // nur Trash-Inhalte
    const slug = makeSlug(name, first_air_date?.slice(0, 4));
    // Show speichern oder aktualisieren
    const { data: showData, error: showError } = await supabase.from("shows").upsert([
      {
        slug,
        title: name,
        description: overview,
        genre: "Reality",
        status: "active"
      }
    ], {
      onConflict: "slug"
    }).select("id").single();
    if (showError) {
      console.error("Fehler bei Show:", name, showError.message);
      continue;
    }
    totalShows++;
    const showId = showData.id;
    // Staffel-Details abrufen
    const details = await fetchShowDetails(tmdbId);
    const episodeLength = details.episode_run_time?.[0] || null;
    const seasons = [];
    for (const season of details.seasons || []){
      if (season.season_number <= 0) continue;
      // Prüfe, ob die Season bereits existiert und den Status "complete" hat
      const { data: existingSeason } = await supabase.from("seasons").select("id, status").eq("show_id", showId).eq("season_number", season.season_number).single();
      // Überspringe, wenn die Season bereits vollständig ist
      if (existingSeason && existingSeason.status === "complete") {
        console.log(`Überspringe Season ${season.season_number} (bereits vollständig)`);
        continue;
      }
      const episodes = await fetchSeasonEpisodes(tmdbId, season.season_number);
      const streamingPlatform = await fetchStreamingPlatform(tmdbId);
      const releaseFrequency = estimateReleaseFrequency(episodes);
      // Prüfe, ob die Season als "incomplete" markiert werden soll
      const isIncomplete = !releaseFrequency || !season.air_date || !season.episode_count;
      seasons.push({
        show_id: showId,
        season_number: season.season_number,
        total_episodes: season.episode_count || 0,
        streaming_release_date: season.air_date || null,
        streaming_release_time: "00:00:01",
        episode_length: episodeLength || 60,
        release_frequency: releaseFrequency || null,
        streaming_option: streamingPlatform || null,
        status: "incomplete"
      });
    }
    if (seasons.length > 0) {
      const { error: seasonError } = await supabase.from("seasons").upsert(seasons, {
        onConflict: "show_id,season_number"
      });
      if (seasonError) {
        console.error("Fehler bei Staffeln:", seasonError.message);
      } else {
        totalSeasons += seasons.length;
      }
    }
  }
  console.log(`Import abgeschlossen: ${totalShows} Shows, ${totalSeasons} Staffeln`);
  return new Response(JSON.stringify({
    success: true,
    shows: totalShows,
    seasons: totalSeasons
  }), {
    status: 200
  });
});
