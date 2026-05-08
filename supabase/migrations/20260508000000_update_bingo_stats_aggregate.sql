-- Rewrite fn_feed_generic_bingo_stats_block to return aggregate
-- stats across ALL users (no per-show breakdown).
CREATE OR REPLACE FUNCTION "public"."fn_feed_generic_bingo_stats_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH params AS (
      SELECT
        date_trunc('day', now() AT TIME ZONE 'Europe/Berlin') - INTERVAL '7 days' AS start_ts,
        date_trunc('day', now() AT TIME ZONE 'Europe/Berlin') + INTERVAL '1 day'  AS end_ts
    ),
    sessions_in_range AS (
      SELECT bs.id AS bingo_session_id
      FROM public.bingo_sessions bs
      CROSS JOIN params p
      WHERE bs.started_at >= p.start_ts
        AND bs.started_at <  p.end_ts
    ),
    stats AS (
      SELECT
        COUNT(*)                                                          AS total_sessions,
        COUNT(*) FILTER (WHERE bss.bingo_achieved)                       AS total_bingos,
        ROUND(AVG(bss.score)::numeric, 1)                                AS avg_score,
        ROUND(AVG(bss.time_to_bingo_seconds)
              FILTER (WHERE bss.time_to_bingo_seconds IS NOT NULL)::numeric, 0)
                                                                         AS avg_time_to_bingo_seconds,
        ROUND(AVG(bss.fields_at_bingo)
              FILTER (WHERE bss.fields_at_bingo IS NOT NULL)::numeric, 1)
                                                                         AS avg_fields_at_bingo
      FROM sessions_in_range sir
      JOIN public.bingo_session_stats bss ON bss.bingo_session_id = sir.bingo_session_id
    )
    SELECT jsonb_build_object(
      'type',                     'generic_bingo_stats_block',
      'total_sessions',           COALESCE((SELECT total_sessions            FROM stats), 0),
      'total_bingos',             COALESCE((SELECT total_bingos              FROM stats), 0),
      'bingo_rate',               CASE
                                    WHEN COALESCE((SELECT total_sessions FROM stats), 0) = 0 THEN 0
                                    ELSE ROUND(
                                      (SELECT total_bingos FROM stats)::numeric /
                                      NULLIF((SELECT total_sessions FROM stats), 0) * 100,
                                      1)
                                  END,
      'avg_score',                COALESCE((SELECT avg_score                 FROM stats), 0),
      'avg_time_to_bingo_seconds',COALESCE((SELECT avg_time_to_bingo_seconds FROM stats), 0),
      'avg_fields_at_bingo',      COALESCE((SELECT avg_fields_at_bingo       FROM stats), 0)
    )
  );
END;
$$;
