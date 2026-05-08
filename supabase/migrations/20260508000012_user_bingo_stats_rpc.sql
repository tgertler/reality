-- ─────────────────────────────────────────────────────────────────────────────
-- fn_get_user_bingo_stats
-- Aggregated personal bingo statistics for a single user.
-- Returns a jsonb object with totals, rates, best times, and top shows.
-- Only callable by the authenticated user themselves (or service_role).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_get_user_bingo_stats(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_service_role boolean :=
    coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role';
BEGIN
  IF p_user_id IS NULL THEN
    RETURN '{}'::jsonb;
  END IF;

  IF NOT v_is_service_role AND auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  RETURN (
    WITH user_sessions AS (
      SELECT bs.id AS session_id
      FROM   public.bingo_sessions bs
      WHERE  bs.created_by = p_user_id
        AND  bs.status = 'COMPLETED'
    ),
    stats AS (
      SELECT
        COUNT(*)::int                                                               AS total_sessions,
        COUNT(*) FILTER (WHERE bss.bingo_achieved)::int                            AS total_bingos,
        ROUND(
          COUNT(*) FILTER (WHERE bss.bingo_achieved)::numeric /
          NULLIF(COUNT(*), 0) * 100, 1
        )                                                                           AS bingo_rate,
        ROUND(
          MIN(bss.time_to_bingo_seconds)
            FILTER (WHERE bss.bingo_achieved AND bss.time_to_bingo_seconds IS NOT NULL)::numeric,
          0
        )                                                                           AS best_time_seconds,
        ROUND(AVG(bss.score) FILTER (WHERE bss.score IS NOT NULL)::numeric, 1)     AS avg_score,
        ROUND(
          AVG(bss.fields_at_bingo)
            FILTER (WHERE bss.bingo_achieved AND bss.fields_at_bingo IS NOT NULL)::numeric,
          1
        )                                                                           AS avg_fields_at_bingo,
        MAX(bss.score)                                                              AS top_score
      FROM   user_sessions us
      JOIN   public.bingo_session_stats bss ON bss.bingo_session_id = us.session_id
    ),
    by_show AS (
      SELECT
        COALESCE(sh.short_title, sh.title)          AS show_title,
        COUNT(*)::int                               AS session_count,
        COUNT(*) FILTER (WHERE bss.bingo_achieved)::int AS bingo_count
      FROM   user_sessions us
      JOIN   public.bingo_sessions   bsess ON bsess.id          = us.session_id
      JOIN   public.bingos           b     ON b.id              = bsess.bingo_id
      JOIN   public.show_events      se    ON se.id             = b.show_event_id
      JOIN   public.shows            sh    ON sh.id             = se.show_id
      LEFT JOIN public.bingo_session_stats bss ON bss.bingo_session_id = us.session_id
      GROUP  BY sh.id, sh.short_title, sh.title
      ORDER  BY session_count DESC
      LIMIT  5
    )
    SELECT jsonb_build_object(
      'total_sessions',      COALESCE((SELECT total_sessions      FROM stats), 0),
      'total_bingos',        COALESCE((SELECT total_bingos        FROM stats), 0),
      'bingo_rate',          COALESCE((SELECT bingo_rate          FROM stats), 0),
      'best_time_seconds',           (SELECT best_time_seconds    FROM stats),
      'avg_score',           COALESCE((SELECT avg_score           FROM stats), 0),
      'avg_fields_at_bingo', COALESCE((SELECT avg_fields_at_bingo FROM stats), 0),
      'top_score',           COALESCE((SELECT top_score           FROM stats), 0),
      'top_shows',           COALESCE(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'show_title',    show_title,
              'session_count', session_count,
              'bingo_count',   bingo_count
            )
            ORDER BY session_count DESC
          )
          FROM by_show
        ),
        '[]'::jsonb
      )
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_get_user_bingo_stats(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_get_user_bingo_stats(uuid) TO service_role;
