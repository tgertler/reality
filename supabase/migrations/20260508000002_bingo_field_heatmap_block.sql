-- Adds a user-wide bingo field heatmap feed block based on checked field frequency.
CREATE OR REPLACE FUNCTION "public"."fn_feed_bingo_field_heatmap_block"() RETURNS "jsonb"
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
    total_base AS (
      SELECT COUNT(*)::int AS total_sessions
      FROM sessions_in_range
    ),
    field_presence AS (
      SELECT
        lower(trim(bp.text)) AS field_key,
        MIN(bp.text) AS field_label,
        COUNT(*)::int AS appearances,
        COUNT(*) FILTER (WHERE bsi.checked_at IS NOT NULL)::int AS checks,
        COUNT(DISTINCT bsi.bingo_session_id)::int AS sessions_with_field,
        COUNT(DISTINCT bsi.bingo_session_id)
          FILTER (WHERE bsi.checked_at IS NOT NULL)::int AS sessions_checked
      FROM sessions_in_range sir
      JOIN public.bingo_session_items bsi ON bsi.bingo_session_id = sir.bingo_session_id
      JOIN public.bingo_items bi ON bi.id = bsi.bingo_item_id
      JOIN public.bingo_phrases bp ON bp.id = bi.phrase_id
      WHERE bp.text IS NOT NULL
        AND btrim(bp.text) <> ''
      GROUP BY lower(trim(bp.text))
    ),
    ranked AS (
      SELECT
        fp.field_label,
        fp.appearances,
        fp.checks,
        fp.sessions_with_field,
        fp.sessions_checked,
        CASE
          WHEN fp.sessions_with_field = 0 THEN 0
          ELSE ROUND((fp.sessions_checked::numeric / fp.sessions_with_field) * 100, 1)
        END AS checked_rate
      FROM field_presence fp
    ),
    top_fields AS (
      SELECT
        r.field_label,
        r.checked_rate,
        r.sessions_checked,
        r.sessions_with_field
      FROM ranked r
      WHERE r.sessions_with_field >= 3
      ORDER BY r.checked_rate DESC, r.sessions_checked DESC
      LIMIT 5
    ),
    cold_fields AS (
      SELECT
        r.field_label,
        r.checked_rate,
        r.sessions_checked,
        r.sessions_with_field
      FROM ranked r
      WHERE r.sessions_with_field >= 3
      ORDER BY r.checked_rate ASC, r.sessions_with_field DESC
      LIMIT 3
    )
    SELECT jsonb_build_object(
      'type', 'bingo_field_heatmap_block',
      'window_days', 7,
      'total_sessions', COALESCE((SELECT total_sessions FROM total_base), 0),
      'top_fields', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'label', tf.field_label,
            'checked_rate', tf.checked_rate,
            'sessions_checked', tf.sessions_checked,
            'sessions_with_field', tf.sessions_with_field
          ) ORDER BY tf.checked_rate DESC, tf.sessions_checked DESC
        )
        FROM top_fields tf
      ), '[]'::jsonb),
      'cold_fields', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'label', cf.field_label,
            'checked_rate', cf.checked_rate,
            'sessions_checked', cf.sessions_checked,
            'sessions_with_field', cf.sessions_with_field
          ) ORDER BY cf.checked_rate ASC, cf.sessions_with_field DESC
        )
        FROM cold_fields cf
      ), '[]'::jsonb),
      'skip', COALESCE((SELECT total_sessions FROM total_base), 0) = 0
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_bingo_field_heatmap_block"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."fn_feed_bingo_field_heatmap_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_bingo_field_heatmap_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_bingo_field_heatmap_block"() TO "service_role";
