// ============================================================================
// DAILY UPDATE JOB (TMDB + TRAKT) — FIXED VERSION
// - Staffeln werden jetzt IMMER erkannt
// - Episode_count wird korrekt rekonstruiert
// - TMDB edge-cases sauber behandelt
// - Air Dates merged
// - Frequency Detection
// - Streaming Provider
// ============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// --- SUPABASE ---
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
// --- API KEYS ---
const TMDB_API_KEY = Deno.env.get("TMDB_API_KEY");
const TRAKT_CLIENT_ID = Deno.env.get("TRAKT_CLIENT_ID");
// --- CONSTANTS ---
const TMDB_URL = "https://api.themoviedb.org/3";
const TRAKT_BASE = "https://api.trakt.tv";
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
// TMDB SHOW DETAILS
async function fetchShowDetails(tmdbId) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}?api_key=${TMDB_API_KEY}&language=de-DE`);
  return await res.json();
}
// TMDB EPISODES
async function fetchSeasonEpisodes(tmdbId, seasonNum) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}/season/${seasonNum}?api_key=${TMDB_API_KEY}&language=de-DE`);
  if (!res.ok) return [];
  const data = await res.json();
  return data.episodes || [];
}
// TRAKT EPISODES
async function fetchTraktSeasonEpisodes(slug, seasonNum) {
  const res = await fetch(`${TRAKT_BASE}/shows/${slug}/seasons/${seasonNum}?extended=episodes`, {
    headers: traktHeaders()
  });
  if (!res.ok) return null;
  return await res.json();
}
// STREAMING PROVIDERS
async function fetchStreamingPlatform(tmdbId) {
  const res = await fetch(`${TMDB_URL}/tv/${tmdbId}/watch/providers?api_key=${TMDB_API_KEY}`);
  const data = await res.json();
  const de = data.results?.DE;
  if (!de) return null;
  return de?.flatrate?.[0]?.provider_name || de?.buy?.[0]?.provider_name || de?.rent?.[0]?.provider_name || null;
}
// ============================================================================
// MERGE AIR DATES
// ============================================================================
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
// ============================================================================
// RELEASE FREQUENCY
// ============================================================================
function estimateReleaseFrequency(episodes) {
  if (!episodes || episodes.length === 0) return null;
  // Sortieren
  const sorted = episodes.filter((e)=>e.air_date).sort((a, b)=>new Date(a.air_date).getTime() - new Date(b.air_date).getTime());
  if (sorted.length === 1) return "onetime";
  // Zeitdifferenzen (in Tagen)
  const diffs = [];
  for(let i = 1; i < sorted.length; i++){
    const d1 = new Date(sorted[i - 1].air_date).getTime();
    const d2 = new Date(sorted[i].air_date).getTime();
    diffs.push((d2 - d1) / 86400000);
  }
  const avg = diffs.reduce((a, b)=>a + b, 0) / diffs.length;
  // --- RULES ----------------------------------------------------------
  // daily
  if (avg <= 2) return "daily";
  // weekly
  if (avg >= 5 && avg <= 9) return "weekly";
  // biweekly
  if (avg >= 12 && avg <= 16) return "biweekly";
  // monthly
  if (avg >= 25 && avg <= 40) return "monthly";
  // premiere2_then_weekly
  if (sorted.length >= 3 && sorted[0].air_date === sorted[1].air_date && new Date(sorted[2].air_date).getTime() - new Date(sorted[1].air_date).getTime() >= 5) {
    return "premiere2_then_weekly";
  }
  // premiere3_then_weekly
  if (sorted.length >= 4 && sorted[0].air_date === sorted[1].air_date && sorted[1].air_date === sorted[2].air_date && new Date(sorted[3].air_date).getTime() - new Date(sorted[2].air_date).getTime() >= 5) {
    return "premiere3_then_weekly";
  }
  // weekly2 (two eps per week)
  if (sorted.length >= 4) {
    const firstTwo = sorted[1].air_date === sorted[0].air_date;
    const nextTwo = sorted[3].air_date === sorted[2].air_date;
    if (firstTwo && nextTwo) return "weekly2";
  }
  // weekly3 (three eps per week)
  if (sorted.length >= 6) {
    const a = sorted[0].air_date === sorted[1].air_date && sorted[1].air_date === sorted[2].air_date;
    const b = sorted[3].air_date === sorted[4].air_date && sorted[4].air_date === sorted[5].air_date;
    if (a && b) return "weekly3";
  }
  // fallback
  return "weekly"; // safest default
}
// ============================================================================
// DAILY UPDATE
// ============================================================================
Deno.serve(async ()=>{
  console.log("🔄 Daily Update gestartet…");
  const { data: shows } = await supabase.from("shows").select("*").eq("status", "active");
  if (!shows?.length) {
    console.log("⚠️ Keine aktiven Shows.");
    return new Response("NO_SHOWS");
  }
  let updatedSeasons = 0;
  for (const show of shows){
    const tmdbId = show.tmdb_id ? Number(show.tmdb_id) : null;
    if (!tmdbId) continue;
    console.log(`\n📺 UPDATE → ${show.title}`);
    const details = await fetchShowDetails(tmdbId);
    // CRITICAL FIX: details.seasons sometimes missing or incomplete
    if (!Array.isArray(details?.seasons)) {
      console.log(`⚠️ TMDB liefert keine Staffeln für ${show.title}`);
      continue;
    }
    const episodeLength = details.episode_run_time?.[0] || 60;
    for (const season of details.seasons){
      if (season.season_number <= 0) continue;
      console.log(`➡️ Staffel ${season.season_number}`);
      // TMDB episodes
      const tmdbEpisodes = await fetchSeasonEpisodes(tmdbId, season.season_number);
      // FIX: derive total_episode_count from length
      const totalEpisodes = season.episode_count || tmdbEpisodes?.length || 0;
      // TRAKT episodes (optional)
      let traktEpisodes = [];
      if (show.trakt_slug) {
        const t = await fetchTraktSeasonEpisodes(show.trakt_slug, season.season_number);
        traktEpisodes = t?.[0]?.episodes || [];
      }
      const merged = mergeEpisodeAirDates(tmdbEpisodes, traktEpisodes);
      const frequency = estimateReleaseFrequency(merged);
      const platform = await fetchStreamingPlatform(tmdbId);
      await supabase.from("seasons").upsert({
        show_id: show.id,
        season_number: season.season_number,
        total_episodes: totalEpisodes,
        streaming_release_date: season.air_date || null,
        streaming_release_time: "00:00:01",
        episode_length: episodeLength,
        release_frequency: frequency,
        streaming_option: platform,
        status: totalEpisodes > 0 ? "complete" : "incomplete",
        updated_at: new Date().toISOString()
      }, {
        onConflict: "show_id,season_number"
      });
      console.log(`✔ Staffel ${season.season_number} gespeichert (Episodes: ${totalEpisodes})`);
      updatedSeasons++;
    }
  }
  console.log(`\n🎉 DAILY DONE — ${updatedSeasons} Staffeln aktualisiert.`);
  return new Response("DAILY_UPDATE_OK");
});
