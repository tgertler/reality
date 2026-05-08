-- Feed block: TikTok hashtags for currently airing / trending shows.
-- Groups tags by show, prioritises shows with calendar events this week,
-- then fills up with remaining shows that have TikTok tags.
CREATE OR REPLACE FUNCTION "public"."fn_feed_show_tiktok_hashtags_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH current_show_ids AS (
      -- Shows with events in the next 14 days (airing / upcoming)
      SELECT DISTINCT se.show_id
      FROM public.calendar_events ce
      JOIN public.show_events se ON se.id = ce.show_event_id
      WHERE ce.start_datetime >= now()
        AND ce.start_datetime < now() + INTERVAL '14 days'
    ),
    shows_with_tags AS (
      SELECT
        s.id         AS show_id,
        COALESCE(s.short_title, s.title) AS show_title,
        -- boost shows that are currently airing
        CASE WHEN csi.show_id IS NOT NULL THEN 1 ELSE 0 END AS is_current,
        jsonb_agg(
          jsonb_build_object(
            'tag',         sst.tag,
            'display_tag', sst.display_tag,
            'is_primary',  sst.is_primary
          ) ORDER BY sst.is_primary DESC, sst.priority DESC
        ) AS tags
      FROM public.show_social_tags sst
      JOIN public.shows s ON s.id = sst.show_id
      LEFT JOIN current_show_ids csi ON csi.show_id = s.id
      WHERE sst.platform = 'tiktok'
      GROUP BY s.id, s.short_title, s.title, csi.show_id
    )
    SELECT jsonb_build_object(
      'type', 'show_tiktok_hashtags_block',
      'shows', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'show_id',    t.show_id,
            'show_title', t.show_title,
            'is_current', t.is_current = 1,
            'tags',       t.tags
          ) ORDER BY t.is_current DESC, t.show_title ASC
        )
        FROM shows_with_tags t
      ), '[]'::jsonb),
      'skip', NOT EXISTS (
        SELECT 1 FROM public.show_social_tags WHERE platform = 'tiktok'
      )
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_show_tiktok_hashtags_block"() OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."fn_feed_show_tiktok_hashtags_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_show_tiktok_hashtags_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_show_tiktok_hashtags_block"() TO "service_role";
