-- Feed block: next 3 upcoming trash events from calendar_events.
CREATE OR REPLACE FUNCTION "public"."fn_feed_trash_events_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    WITH upcoming AS (
      SELECT
        te.id,
        te.title,
        te.description,
        te.location,
        te.organizer,
        te.price,
        te.external_url,
        te.image_url,
        ce.start_datetime,
        s.title AS related_show_title
      FROM public.calendar_events ce
      JOIN public.trash_events te ON te.id = ce.trash_event_id
      LEFT JOIN public.shows s ON s.id = te.related_show_id
      WHERE ce.start_datetime >= now()
      ORDER BY ce.start_datetime ASC
      LIMIT 3
    )
    SELECT jsonb_build_object(
      'type', 'trash_events_block',
      'events', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'id',                 u.id,
            'title',              u.title,
            'description',        u.description,
            'location',           u.location,
            'organizer',          u.organizer,
            'price',              u.price,
            'external_url',       u.external_url,
            'image_url',          u.image_url,
            'start_datetime',     u.start_datetime,
            'related_show_title', u.related_show_title
          ) ORDER BY u.start_datetime ASC
        )
        FROM upcoming u
      ), '[]'::jsonb),
      'skip', NOT EXISTS (
        SELECT 1 FROM public.calendar_events ce
        WHERE ce.trash_event_id IS NOT NULL AND ce.start_datetime >= now()
      )
    )
  );
END;
$$;

ALTER FUNCTION "public"."fn_feed_trash_events_block"() OWNER TO "postgres";
GRANT ALL ON FUNCTION "public"."fn_feed_trash_events_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_trash_events_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_trash_events_block"() TO "service_role";
