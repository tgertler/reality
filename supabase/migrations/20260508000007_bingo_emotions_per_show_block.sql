-- Feed block: top 3 shows by bingo-session emotion reactions, with top 3 emotions per show.
CREATE OR REPLACE FUNCTION "public"."fn_feed_bingo_emotions_per_show_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH session_shows AS (
      SELECT
        bse.bingo_session_id,
        bse.emoji,
        bse.dimension,
        s.id                                AS show_id,
        COALESCE(s.short_title, s.title)    AS show_title
      FROM public.bingo_session_emotions bse
      JOIN public.bingo_sessions bs  ON bs.id  = bse.bingo_session_id
      JOIN public.bingos b            ON b.id   = bs.bingo_id
      JOIN public.show_events se      ON se.id  = b.show_event_id
      JOIN public.shows s             ON s.id   = se.show_id
    ),
    show_session_counts AS (
      SELECT
        show_id,
        show_title,
        COUNT(DISTINCT bingo_session_id)::int AS session_count
      FROM session_shows
      GROUP BY show_id, show_title
      ORDER BY session_count DESC
      LIMIT 3
    ),
    emotion_counts AS (
      SELECT
        ss.show_id,
        ss.emoji,
        ss.dimension,
        COUNT(*)::int AS emotion_count
      FROM session_shows ss
      WHERE ss.show_id IN (SELECT show_id FROM show_session_counts)
      GROUP BY ss.show_id, ss.emoji, ss.dimension
    ),
    ranked_emotions AS (
      SELECT
        ec.show_id,
        ec.emoji,
        ec.dimension,
        ec.emotion_count,
        ROW_NUMBER() OVER (PARTITION BY ec.show_id ORDER BY ec.emotion_count DESC) AS rn
      FROM emotion_counts ec
    )
    SELECT jsonb_build_object(
      'type', 'bingo_emotions_per_show_block',
      'shows', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'show_id',      ssc.show_id,
            'show_title',   ssc.show_title,
            'session_count', ssc.session_count,
            'top_emotions', (
              SELECT jsonb_agg(
                jsonb_build_object(
                  'emoji',     re.emoji,
                  'dimension', re.dimension,
                  'count',     re.emotion_count
                ) ORDER BY re.emotion_count DESC
              )
              FROM ranked_emotions re
              WHERE re.show_id = ssc.show_id AND re.rn <= 3
            )
          ) ORDER BY ssc.session_count DESC
        )
        FROM show_session_counts ssc
      ), '[]'::jsonb),
      'skip', NOT EXISTS (SELECT 1 FROM public.bingo_session_emotions)
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_bingo_emotions_per_show_block"() OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."fn_feed_bingo_emotions_per_show_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_bingo_emotions_per_show_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_bingo_emotions_per_show_block"() TO "service_role";
