-- Feed block: latest social videos (TikTok / Reels) ranked by priority.
CREATE OR REPLACE FUNCTION "public"."fn_feed_viral_clips_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH videos AS (
      SELECT
        sv.id,
        sv.show_id,
        s.title          AS show_title,
        s.short_title    AS show_short_title,
        sv.platform,
        sv.video_url,
        sv.priority,
        sv.created_at
      FROM public.show_social_videos sv
      JOIN public.shows s ON s.id = sv.show_id
      ORDER BY sv.priority DESC, sv.created_at DESC
      LIMIT 5
    )
    SELECT jsonb_build_object(
      'type', 'viral_clips_block',
      'videos', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'show_id',          v.show_id,
            'show_title',       v.show_title,
            'show_short_title', v.show_short_title,
            'platform',         v.platform,
            'video_url',        v.video_url,
            'priority',         v.priority
          ) ORDER BY v.priority DESC, v.created_at DESC
        )
        FROM videos v
      ), '[]'::jsonb),
      'skip', NOT EXISTS (SELECT 1 FROM public.show_social_videos)
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_viral_clips_block"() OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."fn_feed_viral_clips_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_viral_clips_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_viral_clips_block"() TO "service_role";
