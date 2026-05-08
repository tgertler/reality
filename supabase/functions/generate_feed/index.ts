// supabase/functions/generate_feed/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async ()=>{
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  // 1) Highest priority — must be on top
  const HIGH = [
    {
      fn: "fn_feed_today_shows_block",
      type: "today_shows_block",
      priority: 2
    },
    {
      fn: "fn_feed_next_3_premieres_block",
      type: "next_3_premieres_block",
      priority: 3
    },
    {
      fn: "fn_feed_latest_releases_block",
      type: "latest_releases_block",
      priority: 4
    },
    {
      fn: "fn_feed_coming_this_week_block",
      type: "coming_this_week_block",
      priority: 5
    }
  ];
  // 2) Mid priority — relevant blocks
  const MID = [
    //{ fn: "fn_feed_monthly_overview_block", type: "monthly_overview_block", priority: 10 },
    {
      fn: "fn_feed_generic_bingo_stats_block",
      type: "generic_bingo_stats_block",
      priority: 10
    },
    {
      fn: "fn_feed_bingo_field_heatmap_block",
      type: "bingo_field_heatmap_block",
      priority: 12
    },
    {
      fn: "fn_feed_next_month_preview_block",
      type: "next_month_preview_block",
      priority: 11
    },
    // { fn: "fn_feed_seasonal_top_5_block", type: "seasonal_top_5_block", priority: 12 },
    {
      fn: "fn_feed_next_big_premiere_item",
      type: "next_big_premiere_item",
      priority: 13
    },
    //{ fn: "fn_feed_season_starts_soon_item", type: "season_starts_soon_item", priority: 14 },
    {
      fn: "fn_feed_season_finale_item",
      type: "season_finale_item",
      priority: 15
    },
    {
      fn: "fn_feed_trending_shows_block",
      type: "trending_shows_block",
      priority: 16
    },
    {
      fn: "fn_feed_bingo_emotions_per_show_block",
      type: "bingo_emotions_per_show_block",
      priority: 17
    },
    {
      fn: "fn_feed_trash_events_block",
      type: "trash_events_block",
      priority: 18
    }
  ];
  // 3) Low priority — random / drama / endless‑feed feel
  const LOW = [
    {
      fn: "fn_feed_featured_show_block",
      type: "featured_show_block",
      priority: 20
    },
    {
      fn: "fn_feed_show_tiktok_hashtags_block",
      type: "show_tiktok_hashtags_block",
      priority: 25
    },
    //  { fn: "fn_feed_drama_highlights_top5", type: "drama_highlights_top5", priority: 21 },
    //  { fn: "fn_feed_drama_random_pick", type: "drama_random_pick", priority: 22 },
    {
      fn: "fn_feed_random_show",
      type: "random_show",
      priority: 30
    }
  ];
  const all = [
    ...HIGH,
    ...MID,
    ...LOW
  ];
  // Optional: clear feed before regeneration
  await supabase.rpc("truncate_feed_items");
  async function insertFeedItem(type, data, priority) {
    if (!data || data.skip) return;
    await supabase.from("feed_items").insert({
      item_type: type,
      data,
      feed_timestamp: new Date().toISOString(),
      priority
    });
  }
  for (const f of all){
    const { data } = await supabase.rpc(f.fn);
    await insertFeedItem(f.type, data, f.priority);
  }
  return new Response("OK", {
    status: 200
  });
});
