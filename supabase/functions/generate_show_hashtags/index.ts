import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// --- SUPABASE ---
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
Deno.serve(async ()=>{
  try {
    // 1. Shows laden
    const { data: shows, error: showError } = await supabase.from("shows").select("id, title, short_title, genre, slug");
    if (showError) throw showError;
    const generated = [];
    for (const show of shows){
      // -------------------------------------------------
      // A) CHECK: Hat diese Show bereits existierende Tags?
      // -------------------------------------------------
      const { data: existingTags, error: tagError } = await supabase.from("show_social_tags").select("id").eq("show_id", show.id);
      if (tagError) throw tagError;
      // Wenn bereits Tags existieren → überspringen
      if (existingTags.length > 0) {
        generated.push({
          show_id: show.id,
          title: show.title,
          skipped: true,
          reason: "Tags already exist"
        });
        continue; // skip this show
      }
      // -------------------------------------------------
      // B) BASIS für Hashtags bestimmen
      // -------------------------------------------------
      // 1. Short Title (Wichtigster Wert)
      const shortBase = show.short_title ? show.short_title.toLowerCase() : null;
      // 3. Title fallback
      const titleBase = show.title ? show.title.replace(/[^a-zA-Z0-9]/g, "").toLowerCase() : null;
      // Finaler Basiswert
      const base = shortBase ?? titleBase;
      // genre
      const genreTag = show.genre ? show.genre.replace(/\s+/g, "").toLowerCase() : null;
      // -------------------------------------------------
      // C) Realistische TikTok Hashtags generieren
      // -------------------------------------------------
      const tags = [
        base,
        `${base}de`,
        `${base}tok`,
        `${base}drama`,
        `${base}moment`,
        `${base}chaos`,
        `${base}highlights`,
        `${base}reaction`,
        genreTag ? `${genreTag}tok` : null,
        "realitytok",
        "chaostok"
      ].filter(Boolean);
      // -------------------------------------------------
      // D) Tags speichern (NUR jetzt, da vorher keine existieren)
      // -------------------------------------------------
      for(let i = 0; i < tags.length; i++){
        await supabase.from("show_social_tags").insert({
          show_id: show.id,
          platform: "tiktok",
          tag: tags[i],
          display_tag: `#${tags[i]}`,
          is_primary: i === 0,
          priority: i + 1
        });
      }
      generated.push({
        show_id: show.id,
        title: show.title,
        base,
        created: tags
      });
    }
    return new Response(JSON.stringify({
      status: "ok",
      processed: generated
    }, null, 2), {
      status: 200
    });
  } catch (e) {
    return new Response(JSON.stringify({
      error: e.message
    }), {
      status: 500
    });
  }
});
