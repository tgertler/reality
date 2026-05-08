-- Feed block: top 5 shows by user interactions in the last 7 days.
CREATE OR REPLACE FUNCTION "public"."fn_feed_trending_shows_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH interactions AS (
      SELECT
        usr.show_id,
        COUNT(*)::int AS interaction_count
      FROM public.user_show_relations usr
      WHERE usr.created_at >= (now() - INTERVAL '7 days')::timestamp
      GROUP BY usr.show_id
    ),
    ranked AS (
      SELECT
        ROW_NUMBER() OVER (ORDER BY i.interaction_count DESC)::int AS rank,
        s.id   AS show_id,
        s.title,
        s.short_title,
        s.main_color,
        i.interaction_count
      FROM interactions i
      JOIN public.shows s ON s.id = i.show_id
      ORDER BY i.interaction_count DESC
      LIMIT 5
    ),
    total AS (
      SELECT SUM(interaction_count)::int AS total_interactions FROM ranked
    )
    SELECT jsonb_build_object(
      'type',               'trending_shows_block',
      'window_days',        7,
      'total_interactions', COALESCE((SELECT total_interactions FROM total), 0),
      'shows', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'rank',              r.rank,
            'show_id',           r.show_id,
            'title',             r.title,
            'short_title',       r.short_title,
            'main_color',        r.main_color,
            'interaction_count', r.interaction_count
          ) ORDER BY r.rank
        )
        FROM ranked r
      ), '[]'::jsonb),
      'skip', NOT EXISTS (SELECT 1 FROM interactions)
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_trending_shows_block"() OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."fn_feed_trending_shows_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_trending_shows_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_trending_shows_block"() TO "service_role";
