


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";








ALTER SCHEMA "public" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






CREATE SCHEMA IF NOT EXISTS "show_management";


ALTER SCHEMA "show_management" OWNER TO "postgres";


COMMENT ON SCHEMA "show_management" IS 'standard show_management schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."bingo_session_stats" (
    "bingo_session_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "bingo_achieved" boolean NOT NULL,
    "time_to_bingo_seconds" numeric,
    "fields_at_bingo" integer,
    "score" numeric,
    "calculated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bingo_session_stats" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_bingo_session_stats"("p_bingo_session_id" "uuid") RETURNS "public"."bingo_session_stats"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  -- Basis
  v_started_at timestamptz;
  v_user_id uuid;
  v_bingo_at timestamptz;

  -- Aktivität
  v_fields_at_bingo integer := 0;
  v_fast_clicks integer := 0;

  -- Score
  v_time_to_bingo numeric;
  v_score numeric;
  v_result public.bingo_session_stats;
BEGIN
  /* ------------------------------------------------------------
   * 1. Session-Basisdaten
   * ------------------------------------------------------------ */
  SELECT started_at, created_by
  INTO v_started_at, v_user_id
  FROM bingo_sessions
  WHERE id = p_bingo_session_id;

  /* ------------------------------------------------------------
   * 2. Gesamtanzahl angeklickter Felder (immer vollständig)
   * ------------------------------------------------------------ */
  SELECT COUNT(*)
  INTO v_fields_at_bingo
  FROM bingo_session_items
  WHERE bingo_session_id = p_bingo_session_id
    AND checked_at IS NOT NULL;

  /* ------------------------------------------------------------
   * 3. Klick-Burst-Anti-Cheat
   *    (z.B. Script klickt alles direkt)
   * ------------------------------------------------------------ */
  SELECT COUNT(*)
  INTO v_fast_clicks
  FROM bingo_session_items
  WHERE bingo_session_id = p_bingo_session_id
    AND checked_at IS NOT NULL
    AND checked_at <= v_started_at + INTERVAL '1 second';

  /* ------------------------------------------------------------
   * 4. Echtes Bingo ermitteln (Linien / Spalten / Diagonalen)
   * ------------------------------------------------------------ */
  WITH checked_positions AS (
    SELECT DISTINCT ON (bi.position_index)
      bi.position_index,
      bsi.checked_at
    FROM bingo_session_items bsi
    JOIN bingo_items bi ON bi.id = bsi.bingo_item_id
    WHERE bsi.bingo_session_id = p_bingo_session_id
      AND bsi.checked_at IS NOT NULL
    ORDER BY bi.position_index, bsi.checked_at
  ),
  bingo_lines AS (
    SELECT ARRAY[0,1,2,3]  AS line UNION ALL
    SELECT ARRAY[4,5,6,7]  UNION ALL
    SELECT ARRAY[8,9,10,11] UNION ALL
    SELECT ARRAY[12,13,14,15] UNION ALL
    SELECT ARRAY[0,4,8,12] UNION ALL
    SELECT ARRAY[1,5,9,13] UNION ALL
    SELECT ARRAY[2,6,10,14] UNION ALL
    SELECT ARRAY[3,7,11,15] UNION ALL
    SELECT ARRAY[0,5,10,15] UNION ALL
    SELECT ARRAY[3,6,9,12]
  ),
  completed_lines AS (
    SELECT
      MAX(cp.checked_at) AS bingo_at
    FROM bingo_lines bl
    JOIN checked_positions cp
      ON cp.position_index = ANY (bl.line)
    GROUP BY bl.line
    HAVING COUNT(*) = 4
  )
  SELECT MIN(bingo_at)
  INTO v_bingo_at
  FROM completed_lines;

  /* ------------------------------------------------------------
   * 5. Score berechnen + Anti-Cheat anwenden
   * ------------------------------------------------------------ */
  IF v_bingo_at IS NOT NULL THEN
    v_time_to_bingo :=
      EXTRACT(EPOCH FROM (v_bingo_at - v_started_at));

    -- 🛑 Anti-Cheat 1: Unmöglich schnelles Bingo
    IF v_time_to_bingo < 3 THEN
      v_score := 1;
    ELSE
      v_score := (1000 / v_time_to_bingo) + (v_fields_at_bingo * 5);
    END IF;
  ELSE
    v_score := v_fields_at_bingo * 2;
  END IF;

  -- 🛑 Anti-Cheat 2: Klick-Burst
  IF v_fast_clicks >= 6 THEN
    v_score := LEAST(v_score, 5);
  END IF;

  -- 🛑 Anti-Cheat 3: Spielrealitäts-Cap (4×4 Grid)
  IF v_fields_at_bingo > 16 THEN
    v_score := v_score * 0.5;
  END IF;

  /* ------------------------------------------------------------
   * 6. Persistieren
   * ------------------------------------------------------------ */
  INSERT INTO bingo_session_stats (
    bingo_session_id,
    user_id,
    bingo_achieved,
    time_to_bingo_seconds,
    fields_at_bingo,
    score
  )
  VALUES (
    p_bingo_session_id,
    v_user_id,
    v_bingo_at IS NOT NULL,
    v_time_to_bingo,
    v_fields_at_bingo,
    v_score
  )
  ON CONFLICT (bingo_session_id)
  DO UPDATE SET
    bingo_achieved = EXCLUDED.bingo_achieved,
    time_to_bingo_seconds = EXCLUDED.time_to_bingo_seconds,
    fields_at_bingo = EXCLUDED.fields_at_bingo,
    score = EXCLUDED.score,
    calculated_at = now();

  /* ------------------------------------------------------------
   * 7. Return
   * ------------------------------------------------------------ */
  SELECT *
  INTO v_result
  FROM bingo_session_stats
  WHERE bingo_session_id = p_bingo_session_id;

  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."calculate_bingo_session_stats"("p_bingo_session_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_account"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  -- optional: einfache Absicherung
  if p_user_id is null then
    raise exception 'p_user_id must not be null';
  end if;

  -- Transaktional ok: plpgsql läuft innerhalb einer Transaktion
  -- Reihenfolge wichtig: erst abhängige public-Tabellen, dann auth.users.

  delete from public.notification_outbox
  where user_id = p_user_id;

  delete from public.user_devices
  where user_id = p_user_id;

  delete from public.user_preferences
  where user_id = p_user_id;

  delete from public.user_creator_relations
  where user_id = p_user_id;

  delete from public.user_show_relations
  where user_id = p_user_id;

  delete from public.profiles
  where id = p_user_id;

  -- Lösche Auth-User zuletzt
  delete from auth.users
  where id = p_user_id;

exception
  when others then
    -- Optional: Fehler weiterreichen (damit du im Client den Grund siehst)
    raise;
end;
$$;


ALTER FUNCTION "public"."delete_account"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enqueue_calendar_event_live"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO notification_outbox (user_id, type, payload)
  SELECT DISTINCT
    usr.user_id,
    'CALENDAR_EVENT_LIVE',
    jsonb_build_object(
      'calendar_event_id', ce.id,
      'show_id', s.id,
      'show_title', s.title,
      'started_at', ce.start_datetime
    )
  FROM calendar_events ce
  JOIN show_events se ON se.id = ce.show_event_id
  JOIN shows s ON s.id = se.show_id
  JOIN user_show_relations usr ON usr.show_id = s.id
  WHERE
    ce.start_datetime BETWEEN now() - interval '2 minutes'
                          AND now() + interval '2 minutes'
    AND usr.interaction_type IN ('follow', 'favorite');
END;
$$;


ALTER FUNCTION "public"."enqueue_calendar_event_live"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enqueue_calendar_event_reminders"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  t timestamptz := now();
BEGIN
  INSERT INTO public.notification_outbox (user_id, type, payload)
  SELECT
    usr.user_id,
    'CALENDAR_EVENT_REMINDER',
    jsonb_build_object(
      'calendar_event_id', ce.id,
      'show_id', se.show_id,
      'show_title', s.title,
      'start_datetime', ce.start_datetime
    )
  FROM public.calendar_events ce
  JOIN public.show_events se
    ON se.id = ce.show_event_id
  JOIN public.shows s
    ON s.id = se.show_id
  JOIN public.user_show_relations usr
    ON usr.show_id = se.show_id
  JOIN public.profiles p
    ON p.id = usr.user_id
  WHERE
    ce.start_datetime BETWEEN (t + INTERVAL '55 minutes')
                          AND (t + INTERVAL '65 minutes')
    AND usr.interaction_type = 'favorite';
END;
$$;


ALTER FUNCTION "public"."enqueue_calendar_event_reminders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enqueue_daily_digest"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  u RECORD;
  events_payload jsonb;
BEGIN
  /* Nur show-Events: pro show.id genau einmal */
  WITH daily_events AS (
    SELECT DISTINCT ON (s.id)
      jsonb_build_object(
        'calendar_event_id', ce.id,
        'type', 'show_event',
        'event_id', se.id,
        'title', s.title,
        'start_datetime', ce.start_datetime,
        'end_datetime', ce.end_datetime
      ) AS event_obj
    FROM public.calendar_events ce
    JOIN public.show_events se ON se.id = ce.show_event_id
    JOIN public.shows s ON s.id = se.show_id
    WHERE ce.start_datetime::date = current_date
    ORDER BY s.id, ce.start_datetime ASC
  )
  SELECT jsonb_agg(event_obj)
  INTO events_payload
  FROM daily_events;

  -- ✅ ABORT: nichts schreiben, wenn keine Events
  IF events_payload IS NULL OR jsonb_array_length(events_payload) = 0 THEN
    RETURN;
  END IF;

  /* Insert pro User */
  FOR u IN
    SELECT id FROM auth.users
  LOOP
    INSERT INTO public.notification_outbox (user_id, type, payload)
    VALUES (
      u.id,
      'DAILY_DIGEST',
      jsonb_build_object(
        'date', current_date,
        'events', events_payload
      )
    );
  END LOOP;
END;$$;


ALTER FUNCTION "public"."enqueue_daily_digest"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enqueue_daily_digest_favorite"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  u RECORD;
  show_event_count INT;
  trash_event_count INT;
  creator_event_count INT;
  total_event_count INT;

  start_ts TIMESTAMPTZ;
  end_ts   TIMESTAMPTZ;
BEGIN
  start_ts := date_trunc('day', now());
  end_ts := start_ts + interval '1 day';

  FOR u IN
    SELECT id FROM auth.users
  LOOP
    -- 1. Show Events (heute, nur favorisierte Shows)
    SELECT COUNT(*) INTO show_event_count
    FROM show_events se
    JOIN user_show_relations usr ON usr.show_id = se.show_id
    WHERE
      usr.user_id = u.id
      AND usr.interaction_type = 'favorite'
      AND se.created_at >= start_ts
      AND se.created_at < end_ts;

    -- 2. Community / Trash Events (global, heute)
    SELECT COUNT(*) INTO trash_event_count
    FROM trash_events te
    WHERE
      te.created_at >= start_ts
      AND te.created_at < end_ts;

    -- 3. Creator Events (nur favorisierte Creator)
    SELECT COUNT(*) INTO creator_event_count
    FROM creator_events ce
    JOIN user_creator_relations ucr ON ucr.creator_id = ce.creator_id
    WHERE
      ucr.user_id = u.id
      AND ucr.interaction_type = 'favorite'
      AND ce.created_at >= start_ts
      AND ce.created_at < end_ts;

    total_event_count := show_event_count + trash_event_count + creator_event_count;

    INSERT INTO notification_outbox (user_id, type, payload)
    VALUES (
      u.id,
      'DAILY_DIGEST_FAVORITE',
      CASE
        WHEN total_event_count = 0 THEN
          jsonb_build_object(
            'date', current_date,
            'message', 'Heute nichts los',
            'show_events', show_event_count,
            'trash_events', trash_event_count,
            'creator_events', creator_event_count
          )
        ELSE
          jsonb_build_object(
            'date', current_date,
            'show_events', show_event_count,
            'trash_events', trash_event_count,
            'creator_events', creator_event_count
          )
      END
    );
  END LOOP;
END;$$;


ALTER FUNCTION "public"."enqueue_daily_digest_favorite"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enqueue_premiere_one_day_before_live"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  u RECORD;
BEGIN
  /*
    Sends: for each show_event (event_subtype='premiere') whose live start_datetime is tomorrow,
    enqueue a message for users who favorite the show.

    Assumption: this function is executed daily around midnight (or any time you prefer);
    we select by date (tomorrow) to match the “one day before they are live” requirement.
  */

  -- One message per user per live show_event
  INSERT INTO public.notification_outbox (user_id, type, payload)
  SELECT
    usr.user_id,
    'PREMIERE_ONE_DAY_BEFORE',
    jsonb_build_object(
      'show_event_id', se.id,
      'show_id', s.id,
      'show_title', s.title,
      'premiere_subtype', se.event_subtype,
      'episode_number', se.episode_number,
      'description', se.description,
      'live_start_datetime', ce.start_datetime,
      'sent_for_date', (ce.start_datetime::date - INTERVAL '1 day')::date
    )
  FROM public.shows s
  JOIN public.show_events se
    ON se.show_id = s.id
  JOIN public.calendar_events ce
    ON ce.show_event_id = se.id
  JOIN public.user_show_relations usr
    ON usr.show_id = s.id
  WHERE
    se.event_subtype = 'premiere'
    AND ce.start_datetime::date = (current_date + INTERVAL '1 day')::date
  ON CONFLICT DO NOTHING;
END;$$;


ALTER FUNCTION "public"."enqueue_premiere_one_day_before_live"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_almost_complete_season_item"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type',            'almost_complete_season_item',
      'title',           sh.title,
      'season',          se.season_number::text,
      'episode_current', se.released::int,
      'episode_total',   se.total_episodes::int
    )
    FROM (
      SELECT
        s.*,
        COUNT(ce.id) FILTER (WHERE ce.start_datetime < now()) AS released
      FROM seasons s
      LEFT JOIN show_events sevt ON sevt.season_id = s.id
      LEFT JOIN calendar_events ce ON ce.show_event_id = sevt.id
      GROUP BY s.id
    ) se
    JOIN shows sh ON sh.id = se.show_id
    WHERE se.total_episodes IS NOT NULL
      AND se.total_episodes > 0
      AND (se.total_episodes - se.released) = 2
      AND se.released > 0
    ORDER BY (se.total_episodes - se.released) DESC, se.released DESC
    LIMIT 1
  );
END;$$;


ALTER FUNCTION "public"."fn_feed_almost_complete_season_item"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_coming_this_week_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type', 'coming_this_week_block',
      'items', COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb)
    )
    FROM (
      SELECT DISTINCT ON (s.id, date_trunc('day', ce.start_datetime))
        s.id AS show_id,
        s.title,
        sevt.event_subtype AS event_type,
        ce.start_datetime AS datetime
      FROM calendar_events ce
      JOIN show_events sevt ON sevt.id = ce.show_event_id
      JOIN seasons se ON se.id = sevt.season_id
      JOIN shows s ON s.id = sevt.show_id
      WHERE ce.start_datetime >= date_trunc('day', now()) - INTERVAL '1 day'
        AND ce.start_datetime <  date_trunc('day', now()) + INTERVAL '8 days'
      ORDER BY
        s.id,
        date_trunc('day', ce.start_datetime),
        ce.start_datetime ASC
      LIMIT 50
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_coming_this_week_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_creator_spotlight_card"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
  v_last_sent timestamptz;
  v_now_week date;
  v_event record;
  v_key text := 'creator_spotlight_last_sent';
BEGIN
  v_now_week := date_trunc('week', now())::date;

  SELECT (value->>'last_sent')::timestamptz
  INTO v_last_sent
  FROM show_management.ingest_state
  WHERE key = v_key;

  IF v_last_sent IS NOT NULL AND date_trunc('week', v_last_sent)::date = v_now_week THEN
    RETURN jsonb_build_object('skip', true);
  END IF;

  -- "REIN Creator-Content": keine weitere Einschränkung vorhanden, daher nehmen wir Creator-Events mit reaction_upload.
  SELECT ce.*
  INTO v_event
  FROM public.creator_events ce
  WHERE ce.event_kind = 'reaction_upload'
    AND ce.creator_id IS NOT NULL
  ORDER BY ce.created_at DESC
  LIMIT 1;

  IF v_event.id IS NULL THEN
    RETURN jsonb_build_object('skip', true);
  END IF;

  -- Speichere Send-Zeit (wird nur einmal pro Woche ausgegeben)
  INSERT INTO show_management.ingest_state(key, value, updated_at)
  VALUES (v_key, jsonb_build_object('last_sent', now()), now())
  ON CONFLICT (key)
  DO UPDATE SET value = jsonb_build_object('last_sent', EXCLUDED.value->>'last_sent')::jsonb,
                updated_at = now();

  RETURN (
    SELECT jsonb_build_object(
      'type', 'creator_spotlight_card',
      'creator', jsonb_build_object(
        'name', cr.name,
        'avatar_url', cr.avatar_url
      ),
      'headline', CONCAT(cr.name, ' – der größte Reality-Reactor'),
      'description',
        COALESCE(cr.description, 'Bekannt für seine legendären Love Island Reactions'),
      'cta', jsonb_build_object(
        'label', '▶️ Zum Kanal',
        'action', 'creator_channel',
        'creator_id', cr.id
      )
    )
    FROM public.creators cr
    WHERE cr.id = v_event.creator_id
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_creator_spotlight_card"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_featured_show_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT row_to_json(t)
    FROM (
      SELECT 
        'featured_show_block' AS type,
        id AS show_id,
        title,
        description,
        genre
      FROM shows
      ORDER BY random()
      LIMIT 1
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_featured_show_block"() OWNER TO "postgres";


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
      SELECT
        bs.id AS bingo_session_id,
        b.show_event_id
      FROM public.bingo_sessions bs
      JOIN public.bingos b ON b.id = bs.bingo_id
      CROSS JOIN params p
      WHERE bs.started_at >= p.start_ts
        AND bs.started_at <  p.end_ts
    ),
    per_show_stats AS (
      SELECT
        sir.show_event_id,
        COUNT(*) AS participants,
        COUNT(*) FILTER (WHERE bss.bingo_achieved) AS achieved_participants,
        AVG(bss.score) AS avg_score,
        MIN(bss.time_to_bingo_seconds) FILTER (WHERE bss.time_to_bingo_seconds IS NOT NULL) AS best_time_seconds
      FROM sessions_in_range sir
      JOIN public.bingo_session_stats bss ON bss.bingo_session_id = sir.bingo_session_id
      GROUP BY sir.show_event_id
    ),
    global_avgs AS (
      SELECT
        AVG(participants)::numeric AS avg_participants,
        AVG(achieved_participants)::numeric AS avg_achieved_participants,
        AVG(avg_score)::numeric AS avg_score,
        AVG(best_time_seconds)::numeric AS avg_best_time_seconds
      FROM per_show_stats
    ),
    top_shows AS (
      SELECT
        pss.show_event_id,
        pss.participants,
        pss.achieved_participants,
        pss.avg_score,
        pss.best_time_seconds
      FROM per_show_stats pss
      ORDER BY pss.achieved_participants DESC NULLS LAST, pss.participants DESC
      LIMIT 5
    )
    SELECT jsonb_build_object(
      'type', 'generic_bingo_stats_block',
      'averages', jsonb_build_object(
        'avg_participants', COALESCE((SELECT avg_participants FROM global_avgs), 0),
        'avg_achieved_participants', COALESCE((SELECT avg_achieved_participants FROM global_avgs), 0),
        'avg_score', COALESCE((SELECT avg_score FROM global_avgs), 0),
        'avg_best_time_seconds', COALESCE((SELECT avg_best_time_seconds FROM global_avgs), 0)
      ),
      'top_shows', COALESCE((SELECT jsonb_agg(row_to_json(ts)) FROM top_shows ts), '[]'::jsonb)
    )
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_generic_bingo_stats_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_latest_releases_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type','latest_releases_block',
      'items', jsonb_agg(row_to_json(t))
    )
    FROM (
       SELECT 
        s.id AS show_id,
        s.title,
        se.id AS season_id,
        ce.id AS event_id,
        ce.event_type,
        ce.start_datetime AS datetime,
        se.streaming_option
      FROM calendar_events ce
      JOIN show_events sevt ON sevt.id = ce.show_event_id
      JOIN seasons se ON se.id = sevt.season_id
      JOIN shows s ON s.id = sevt.show_id
      WHERE ce.event_type = 'premiere' AND ce.start_datetime < now()
      ORDER BY ce.start_datetime DESC
      LIMIT 3
    ) t
  );
END;$$;


ALTER FUNCTION "public"."fn_feed_latest_releases_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_monthly_overview_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type','monthly_overview_block',
      'items', jsonb_agg(row_to_json(t))
    )
    FROM (
      WITH m AS (
        SELECT date_trunc('month', now()) AS start_m,
               date_trunc('month', now()) + INTERVAL '1 month' AS end_m
      )
      SELECT 
        ce.id AS event_id,
        ce.event_type,
        ce.start_datetime AS datetime,
        s.id AS show_id,
        s.title,
        se.id AS season_id
      FROM m
      LEFT JOIN calendar_events ce ON ce.start_datetime BETWEEN m.start_m AND m.end_m
      LEFT JOIN show_events sevt ON sevt.id = ce.show_event_id
      LEFT JOIN seasons se ON se.id = sevt.season_id
      LEFT JOIN shows s ON s.id = sevt.show_id
      ORDER BY ce.start_datetime
      LIMIT 4
    ) t
  );
END;$$;


ALTER FUNCTION "public"."fn_feed_monthly_overview_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_next_3_premieres_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type','next_3_premieres_block',
      'items', jsonb_agg(
        jsonb_build_object(
          'show_id', s.id,
          'title', s.title,
          'season_id', se.id,
          'event_id', ce.id,
          'datetime', ce.start_datetime
        )
      )
    )
    FROM (
      SELECT ce.id, ce.show_event_id, ce.start_datetime
      FROM calendar_events ce
      WHERE ce.event_type = 'premiere'
        AND ce.start_datetime > now()
      ORDER BY ce.start_datetime ASC
      LIMIT 3
    ) ce
    JOIN show_events sevt ON sevt.id = ce.show_event_id
    JOIN seasons se ON se.id = sevt.season_id
    JOIN shows s ON s.id = sevt.show_id
  );
END;$$;


ALTER FUNCTION "public"."fn_feed_next_3_premieres_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_next_month_preview_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type', 'next_month_preview_block',
      'items', jsonb_agg(t)
    )
    FROM (
      WITH nm AS (
        SELECT
          date_trunc('month', now()) + INTERVAL '1 month' AS start_m,
          date_trunc('month', now()) + INTERVAL '2 months' AS end_m
      )
      SELECT DISTINCT ON (s.id, se.id)
        ce.id AS event_id,
        ce.event_type,
        ce.start_datetime AS datetime,
        s.id AS show_id,
        s.title,
        se.id AS season_id
      FROM nm
      JOIN calendar_events ce
        ON ce.start_datetime >= nm.start_m
       AND ce.start_datetime <  nm.end_m
      LEFT JOIN show_events sevt
        ON sevt.id = ce.show_event_id
      LEFT JOIN seasons se
        ON se.id = sevt.season_id
      LEFT JOIN shows s
        ON s.id = sevt.show_id
      ORDER BY s.id, se.id, ce.start_datetime
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_next_month_preview_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_random_show"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT row_to_json(t)
    FROM (
      SELECT
        'random_show' AS type,
        id AS show_id,
        title,
        description,
        genre
      FROM shows
      ORDER BY random()
      LIMIT 1
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_random_show"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_season_finale_item"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT row_to_json(t)
    FROM (
      SELECT 
        'season_finale_item' AS type,
        s.id AS show_id,
        s.title,
        se.id AS season_id,
        ce.id AS event_id,
        ce.start_datetime AS datetime
      FROM calendar_events ce
      JOIN show_events sevt ON sevt.id = ce.show_event_id
      JOIN seasons se ON se.id = sevt.season_id
      JOIN shows s ON s.id = sevt.show_id
      WHERE ce.event_type = 'finale'
        AND ce.start_datetime > now()
      ORDER BY ce.start_datetime
      LIMIT 1
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_season_finale_item"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_season_starts_soon_item"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN (
    SELECT row_to_json(t)
    FROM (
      SELECT 
        'season_starts_soon_item' AS type,
        s.id AS show_id,
        s.title,
        se.id AS season_id,
        ce.id AS event_id,
        floor(EXTRACT(epoch FROM (ce.start_datetime - now())) / 86400) AS days_until,
        ce.start_datetime AS datetime
      FROM calendar_events ce
      JOIN show_events sevt ON sevt.id = ce.show_event_id
      JOIN seasons se ON se.id = sevt.season_id
      JOIN shows s ON s.id = sevt.show_id
      WHERE ce.event_type = 'premiere'
        AND ce.start_datetime BETWEEN now() AND now() + INTERVAL '7 days'
      ORDER BY ce.start_datetime
      LIMIT 1
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_season_starts_soon_item"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_today_shows_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'type', 'today_shows_block',
      'items', COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb)
    )
    FROM (
      SELECT DISTINCT ON (s.id, se.id)
        s.id AS show_id,
        s.title,
        se.id AS season_id,
        cev.id AS event_id,
        cev.event_type,
        cev.start_datetime AS datetime, -- UTC
        se.streaming_option
      FROM public.calendar_events cev
      JOIN public.show_events sevt ON sevt.id = cev.show_event_id
      JOIN public.seasons se ON se.id = sevt.season_id
      JOIN public.shows s ON s.id = sevt.show_id
      -- Kalenderereignis überlappt den heutigen Tag (Deutschland)
      WHERE
        cev.start_datetime <
          (
            date_trunc('day', now() AT TIME ZONE 'Europe/Berlin')
            + INTERVAL '1 day'
          ) AT TIME ZONE 'Europe/Berlin'
        AND cev.end_datetime >=
          date_trunc('day', now() AT TIME ZONE 'Europe/Berlin')
          AT TIME ZONE 'Europe/Berlin'
      ORDER BY s.id, se.id, cev.start_datetime
    ) t
  );
END;$$;


ALTER FUNCTION "public"."fn_feed_today_shows_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_feed_weekend_binge_block"() RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  IF EXTRACT(dow FROM now()) NOT IN (5,6,0) THEN
    RETURN jsonb_build_object('skip',true);
  END IF;

  RETURN (
    SELECT jsonb_build_object(
      'type','weekend_binge_block',
      'recommendations', jsonb_agg(row_to_json(t))
    )
    FROM (
      SELECT 
        id AS show_id,
        title,
        genre
      FROM shows
      ORDER BY random()
      LIMIT 5
    ) t
  );
END;
$$;


ALTER FUNCTION "public"."fn_feed_weekend_binge_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_bingo_for_show_event"("p_show_event_id" "uuid", "p_grid_size" integer DEFAULT 20) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  v_bingo_id uuid;
  v_event_type_id uuid;
  v_phrase_id uuid;
  v_pos integer;

  v_genre text;
  v_event_subtype text;

  used_event_types uuid[] := '{}';

  meta_count int := 0;
  emotion_count int := 0;
  conflict_count int := 0;
  cringe_count int := 0;
BEGIN
  -- Prevent duplicate bingo
  IF EXISTS (
    SELECT 1 FROM public.bingos
    WHERE show_event_id = p_show_event_id
  ) THEN
    RETURN (SELECT id FROM public.bingos WHERE show_event_id = p_show_event_id);
  END IF;

  -- Context
  SELECT s.genre, se.event_subtype
  INTO v_genre, v_event_subtype
  FROM public.show_events se
  JOIN public.shows s ON s.id = se.show_id
  WHERE se.id = p_show_event_id;

  -- Create bingo
  INSERT INTO public.bingos (show_event_id)
  VALUES (p_show_event_id)
  RETURNING id INTO v_bingo_id;

  -- Generate grid
  FOR v_pos IN 0..(p_grid_size - 1) LOOP

    SELECT bet.id
    INTO v_event_type_id
    FROM public.bingo_event_types bet
    WHERE bet.id <> ALL(used_event_types)

      -- ✅ EPISODE PHASE FILTER
      AND (
        bet.key LIKE 'GLOBAL_%'
        OR (v_event_subtype = 'premiere' AND bet.key LIKE 'PREMIERE_%')
        OR (v_event_subtype = 'finale' AND bet.key LIKE 'FINALE_%')
        OR (v_event_subtype = 'regular')
      )


  -- ✅ MUSIC-SPECIFIC FILTER
        AND (
          v_genre ILIKE '%music%'
          OR bet.key NOT LIKE 'GLOBAL_MUSIC_%'
        )


      -- ✅ CATEGORY LIMITS
      AND NOT (bet.category = 'META' AND meta_count >= 4)
      AND NOT (bet.category = 'EMOTION' AND emotion_count >= 6)
      AND NOT (bet.category = 'CONFLICT' AND conflict_count >= 5)
      AND NOT (bet.category = 'CRINGE' AND cringe_count >= 4)

    ORDER BY
      -- Genre weighting
      CASE
        -- Dating & Romance
        WHEN v_genre ILIKE '%dating%'
            AND bet.category IN ('LOVE','EMOTION') THEN 0

        -- Competition / Strategy
        WHEN v_genre ILIKE '%competition%'
            AND bet.category IN ('CONFLICT','META') THEN 0

        
        WHEN v_genre ILIKE '%competition%'
            AND bet.key LIKE 'GLOBAL_GAME_%'
        THEN 0


        -- 🎤 MUSIC / TALENT SHOWS
        WHEN v_genre ILIKE '%music%'
            AND bet.category IN ('EMOTION','VANITY','META') THEN 0

        ELSE 1
      END,
      random()
    LIMIT 1;

    IF v_event_type_id IS NULL THEN
      RAISE EXCEPTION 'No valid bingo event type left';
    END IF;

    -- Phrase
    SELECT id INTO v_phrase_id
    FROM public.bingo_phrases
    WHERE event_type_id = v_event_type_id
      AND show_id IS NULL
    ORDER BY random()
    LIMIT 1;

    INSERT INTO public.bingo_items (
      bingo_id, event_type_id, phrase_id, position_index, specificity_level
    )
    VALUES (
      v_bingo_id, v_event_type_id, v_phrase_id, v_pos, 'GENERIC'
    );

    used_event_types := array_append(used_event_types, v_event_type_id);

    -- Track category counts

CASE (SELECT category FROM public.bingo_event_types WHERE id = v_event_type_id)
  WHEN 'META' THEN meta_count := meta_count + 1;
  WHEN 'EMOTION' THEN emotion_count := emotion_count + 1;
  WHEN 'CONFLICT' THEN conflict_count := conflict_count + 1;
  WHEN 'CRINGE' THEN cringe_count := cringe_count + 1;
  ELSE
    -- categories like LOVE, VANITY etc. are intentionally ignored
    NULL;
END CASE;


  END LOOP;

  RETURN v_bingo_id;
END;$$;


ALTER FUNCTION "public"."generate_bingo_for_show_event"("p_show_event_id" "uuid", "p_grid_size" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_calendar_events"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  event_date TIMESTAMP;  
  event_type TEXT;
  event_id UUID;
  episode_index INT := 0;
BEGIN
  -- Überprüfen, ob total_episodes größer als 0 ist
  IF NEW.total_episodes <= 0 THEN
    RAISE EXCEPTION 'Total episodes must be greater than 0';
  END IF;

  -- Startdatum + Zeit kombinieren
  event_date := NEW.streaming_release_date + NEW.streaming_release_time;

  FOR i IN 0..NEW.total_episodes - 1 LOOP
    -- Event-Typ bestimmen
    event_type := CASE 
                    WHEN i = 0 THEN 'premiere'
                    WHEN i = NEW.total_episodes - 1 THEN 'finale'
                    ELSE 'regular'
                  END;

    event_id := extensions.uuid_generate_v4();

    -- Eintrag für Episode erstellen
    INSERT INTO calendar_events (id, show_id, season_id, start_datetime, end_datetime, event_type)
    VALUES (
      event_id,
      NEW.show_id,
      NEW.id,
      event_date,
      event_date + (NEW.episode_length * INTERVAL '1 minute'),
      event_type
    );

    -- Nächste Episode berechnen
    episode_index := episode_index + 1;

    -- Release-Rhythmus berücksichtigen
    IF NEW.release_frequency = 'daily' THEN
        event_date := event_date + INTERVAL '1 day';

    ELSIF NEW.release_frequency = 'weekly' THEN
        event_date := event_date + INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'monthly' THEN
        event_date := event_date + INTERVAL '1 month';

    ELSIF NEW.release_frequency = 'weekly3' THEN
        -- Alle 3 Folgen: eine Woche weiter
        IF episode_index % 3 = 0 THEN
            event_date := event_date + INTERVAL '1 week';
        END IF;

    ELSE
        -- onetime / fallback: kein automatischer Verschub
        NULL;
    END IF;

  END LOOP;

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."generate_calendar_events"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_editor_policies"("tables" "text"[]) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
declare
  tbl text;
begin
  foreach tbl in array tables loop

    -- INSERT
    execute format($fp$
      create policy "editor_insert_%1$s"
      on %1$s for insert to authenticated
      with check (
        current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles' ? 'editor'
      );
    $fp$, tbl);

    -- UPDATE
    execute format($fp$
      create policy "editor_update_%1$s"
      on %1$s for update to authenticated
      using (
        current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles' ? 'editor'
      )
      with check (
        current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles' ? 'editor'
      );
    $fp$, tbl);

    -- DELETE
    execute format($fp$
      create policy "editor_delete_%1$s"
      on %1$s for delete to authenticated
      using (
        current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles' ? 'editor'
      );
    $fp$, tbl);

  end loop;
end;
$_$;


ALTER FUNCTION "public"."generate_editor_policies"("tables" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_calendar_events_with_shows_by_date"("event_date" timestamp with time zone, "show_ids" "uuid"[], "attendee_ids" "uuid"[]) RETURNS TABLE("calendar_event_id" "uuid", "show_id" "uuid", "season_id" "uuid", "start_datetime" timestamp with time zone, "end_datetime" timestamp with time zone, "drama_level" smallint, "show_title" "text", "streaming_option" "text", "season_number" integer, "total_episodes" integer)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id               AS calendar_event_id,
    ce.show_id,
    ce.season_id,
    ce.start_datetime::timestamptz,
    ce.end_datetime::timestamptz,
    ce.drama_level::smallint,
    s.title::text       AS show_title,
    se.streaming_option::text,
    se.season_number::int,
    se.total_episodes::int
  FROM calendar_events ce
  JOIN shows s ON ce.show_id = s.id
  JOIN seasons se ON ce.season_id = se.id
  WHERE DATE(ce.start_datetime) = DATE(event_date)
    AND (array_length(show_ids, 1) IS NULL OR ce.show_id = ANY(show_ids))
    AND (
      array_length(attendee_ids, 1) IS NULL
      OR EXISTS (
        SELECT 1
        FROM attendees a
        WHERE a.show_id = ce.show_id
          AND a.id = ANY(attendee_ids)
      )
    );
END;
$$;


ALTER FUNCTION "public"."get_calendar_events_with_shows_by_date"("event_date" timestamp with time zone, "show_ids" "uuid"[], "attendee_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  derived_name text;
begin
  derived_name :=
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(split_part(new.email, '@', 1)), ''),
      'Nutzer'
    );

  insert into public.profiles (
    id,
    display_name,
    created_at,
    updated_at
  )
  values (
    new.id,
    derived_name,
    now(),
    now()
  )
  on conflict (id) do nothing;

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."manage_calendar_events"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  event_date TIMESTAMPTZ;
  base_date  TIMESTAMPTZ;
  event_type TEXT;

  calendar_event_id UUID;
  show_event_id UUID;

  episode_len   INTERVAL;
  episode_start TIMESTAMPTZ;

  per_week INT;
  week_no  INT;

  drama_level INT;

  next_day INT;
  i INT;
BEGIN
  IF NEW.total_episodes IS NULL OR NEW.total_episodes <= 0 THEN
    RAISE EXCEPTION 'Total episodes must be greater than 0';
  END IF;

  -- =====================================================
  -- Bei UPDATE: Events der Season komplett neu aufbauen
  -- =====================================================

DELETE FROM public.calendar_events ce
USING public.show_events se
WHERE ce.show_event_id = se.id AND se.season_id = NEW.id;

DELETE FROM public.show_events
WHERE season_id = NEW.id;


event_date :=
  (NEW.streaming_release_date::timestamp
   + NEW.streaming_release_time)
  AT TIME ZONE 'UTC';

  base_date := event_date;

  episode_len := NEW.episode_length * INTERVAL '1 minute';

  -- =====================================================
  -- Episoden-Loop
  -- =====================================================
  FOR i IN 0 .. (NEW.total_episodes - 1) LOOP

    event_type := CASE
      WHEN i = 0 THEN 'premiere'
      WHEN i = NEW.total_episodes - 1 THEN 'finale'
      ELSE 'regular'
    END;

    drama_level := CASE
      WHEN event_type IN ('premiere', 'finale')
        THEN floor(random() * 2 + 9)
      ELSE floor(random() * 5 + 6)
    END;

    -- =====================================================
    -- RELEASE-LOGIK
    -- =====================================================
    IF NEW.release_frequency = 'weekly2' THEN
      per_week := 2;
      week_no := i / per_week;
      episode_start := base_date + week_no * INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'weekly3' THEN
      per_week := 3;
      week_no := i / per_week;
      episode_start := base_date + week_no * INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'daily' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 day';

    ELSIF NEW.release_frequency = 'weekly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'biweekly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '2 weeks';

    ELSIF NEW.release_frequency = 'monthly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 month';

    -- =====================================================
    -- ✅ KORRIGIERT: MULTI WEEKLY
    -- =====================================================
    ELSIF NEW.release_frequency = 'multi_weekly' THEN
  IF NEW.release_days IS NULL OR array_length(NEW.release_days, 1) = 0 THEN
    RAISE EXCEPTION 'release_days[] must be provided when using multi_weekly';
  END IF;

  per_week := array_length(NEW.release_days, 1);

  -- Wir arbeiten nur mit dem Datumsteil von base_date (Zeit bleibt erhalten)
  base_date := base_date; -- nur Lesbarkeit
  episode_len := NEW.episode_length * INTERVAL '1 minute'; -- bleibt bei dir eh oben

  -- Wochentag des Anchors (Postgres: 0=Sonntag ... 6=Samstag)
  -- Wir nutzen dafür day-Teil, damit die Offsetrechnung konsistent ist.
  next_day := NULL; -- nur um Warnungen zu vermeiden
  DECLARE
    start_dow INT;
    k INT;
    prev_off INT;
    raw_off INT;
    off INT[];
  BEGIN
    start_dow := EXTRACT(DOW FROM date_trunc('day', base_date))::int;

    -- Offsets für release_days[k] innerhalb EINER "multi_weekly"-Sequenz aufbauen,
    -- sodass sie monoton steigen (Wrap = +7 Tage).
    off := ARRAY[]::INT[];
    prev_off := -1;

    FOR k IN 1..per_week LOOP
      raw_off := ((NEW.release_days[k]::int - start_dow + 7) % 7); -- 0..6
      IF prev_off = -1 THEN
        off := off || raw_off;
        prev_off := raw_off;
      ELSE
        IF raw_off < prev_off THEN
          raw_off := raw_off + 7; -- Wrap in nächste Woche innerhalb des Durchlaufs
        END IF;
        off := off || raw_off;
        prev_off := raw_off;
      END IF;
    END LOOP;

    week_no := i / per_week;           -- 0-basiert
    next_day := (i % per_week) + 1;   -- Index in off[]

    episode_start :=
      date_trunc('day', base_date)
      + make_interval(secs => 0) + (off[next_day] * INTERVAL '1 day')
      + (week_no * INTERVAL '1 week')
      + (base_date - date_trunc('day', base_date)); -- Uhrzeit beibehalten
  END;

    ELSIF NEW.release_frequency = 'premiere3_then_weekly' THEN
      episode_start := event_date;

      IF (i + 1) = 3 THEN
        event_date := event_date + INTERVAL '1 week';
      ELSIF (i + 1) > 3 THEN
        event_date := event_date + INTERVAL '1 week';
      END IF;

    ELSIF NEW.release_frequency = 'premiere2_then_weekly' THEN
      episode_start := event_date;

      IF (i + 1) = 2 THEN
        event_date := event_date + INTERVAL '1 week';
      ELSIF (i + 1) > 2 THEN
        event_date := event_date + INTERVAL '1 week';
      END IF;

    ELSE
      episode_start := event_date;
    END IF;

    -- =====================================================
    -- INSERT: show_events
    -- =====================================================
    show_event_id := extensions.uuid_generate_v4();
    calendar_event_id := extensions.uuid_generate_v4();

    INSERT INTO public.show_events (
      id,
      show_id,
      season_id,
      event_subtype,
      episode_number,
      description
    ) VALUES (
      show_event_id,
      NEW.show_id,
      NEW.id,
      event_type,
      i + 1,
      NULL
    );

    -- =====================================================
    -- INSERT: calendar_events
    -- =====================================================
    INSERT INTO public.calendar_events (
      id,
      start_datetime,
      end_datetime,
      event_type,
      drama_level,
      event_entity_type,
      show_event_id,
      creator_event_id,
      trash_event_id
    ) VALUES (
      calendar_event_id,
      episode_start,
      episode_start + episode_len,
      event_type,
      drama_level,
      'show_event',
      show_event_id,
      NULL,
      NULL
    );

  END LOOP;

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."manage_calendar_events"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_season_start"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.episode_number = 1 THEN
    INSERT INTO notification_outbox (user_id, type, payload)
    SELECT
      usr.user_id,
      'SEASON_START',
      jsonb_build_object(
        'show_id', s.id,
        'show_title', s.title,
        'season_id', NEW.season_id
      )
    FROM user_show_relations usr
    JOIN shows s ON s.id = NEW.show_id
    WHERE usr.interaction_type IN ('follow', 'favorite');
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_season_start"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_shows_and_attendees"("query" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  result JSONB;
BEGIN
  -- JSON-Objekt mit den Ergebnissen der beiden Tabellen erstellen
  SELECT JSONB_BUILD_OBJECT(
    'shows', (
      SELECT COALESCE(
        JSONB_AGG(
          JSONB_BUILD_OBJECT(
            'id', s.id,
            'title', s.title
          )
        ),
        '[]'::JSONB
      )
      FROM shows s
      WHERE s.title ILIKE '%' || query || '%'
    ),
    'attendees', (
      SELECT COALESCE(
        JSONB_AGG(
          JSONB_BUILD_OBJECT(
            'id', a.id,
            'name', a.name
          )
        ),
        '[]'::JSONB
      )
      FROM attendees a
      WHERE a.name ILIKE '%' || query || '%'
    )
  )
  INTO result;

  RETURN result;
END;$$;


ALTER FUNCTION "public"."search_shows_and_attendees"("query" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_priority_news_ticker_items"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  max_priority integer;
begin
  if new.priority is null then
    select coalesce(max(priority), 0) into max_priority
    from public.news_ticker_items;
    new.priority := max_priority + 1;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."set_priority_news_ticker_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at_news_ticker_items"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at_news_ticker_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_calculate_bingo_on_check"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_session_status text;
BEGIN
  -- Nur wenn wirklich ein Feld gesetzt wurde
  IF NEW.checked_at IS NULL THEN
    RETURN NEW;
  END IF;

  -- Session-Status prüfen
  SELECT status
  INTO v_session_status
  FROM bingo_sessions
  WHERE id = NEW.bingo_session_id;

  -- Keine Neuberechnung, wenn Session beendet
  IF v_session_status <> 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  -- ✅ Zentrale Berechnung aufrufen (echte Bingo-Logik)
  PERFORM calculate_bingo_session_stats(NEW.bingo_session_id);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_calculate_bingo_on_check"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_calculate_bingo_session_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_session_id uuid;
BEGIN
  -- ✅ KORREKTES FELD benutzen (anpassen falls nötig!)
  v_session_id := NEW.bingo_session_id;

  -- ✅ Defensive Absicherung
  IF v_session_id IS NULL THEN
    RAISE NOTICE 'trigger_calculate_bingo_session_stats: bingo_session_id is NULL, skipping';
    RETURN NEW;
  END IF;

  -- ✅ Business-Logik
  PERFORM public.calculate_bingo_session_stats(v_session_id);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_calculate_bingo_session_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."truncate_feed_items"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$DELETE FROM public.feed_items
  WHERE "item_type" NOT IN ('quote_of_the_week', 'throwback_moment', 'bingo_feature_promo');$$;


ALTER FUNCTION "public"."truncate_feed_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "show_management"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "show_management"."set_updated_at"() OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."attendees" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying,
    "bio" character varying,
    "instagram_url" character varying,
    "tiktok_url" character varying,
    "twitter_url" character varying,
    "updated_at" timestamp with time zone,
    "role" character varying,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid",
    "season_id" "uuid"
);


ALTER TABLE "public"."attendees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_event_types" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "category" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bingo_event_types" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bingo_id" "uuid" NOT NULL,
    "event_type_id" "uuid" NOT NULL,
    "phrase_id" "uuid" NOT NULL,
    "position_index" integer NOT NULL,
    "specificity_level" "text" DEFAULT 'GENERIC'::"text" NOT NULL,
    "ref_entity_type" "text",
    "ref_entity_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bingo_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_phrases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_type_id" "uuid" NOT NULL,
    "text" "text" NOT NULL,
    "locale" "text" DEFAULT 'de-DE'::"text" NOT NULL,
    "show_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bingo_phrases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_session_emotions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bingo_session_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "phase" "text" NOT NULL,
    "dimension" "text" NOT NULL,
    "emoji" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "bingo_session_emotions_phase_check" CHECK (("phase" = ANY (ARRAY['EXPECTATION'::"text", 'AFTERGLOW'::"text"])))
);


ALTER TABLE "public"."bingo_session_emotions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_session_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bingo_session_id" "uuid" NOT NULL,
    "bingo_item_id" "uuid" NOT NULL,
    "checked_at" timestamp with time zone,
    "checked_by" "uuid"
);


ALTER TABLE "public"."bingo_session_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingo_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bingo_id" "uuid" NOT NULL,
    "mode" "text" DEFAULT 'WATCHPARTY'::"text" NOT NULL,
    "status" "text" DEFAULT 'ACTIVE'::"text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone,
    "created_by" "uuid"
);


ALTER TABLE "public"."bingo_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bingos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_event_id" "uuid" NOT NULL,
    "scope_type" "text" DEFAULT 'EPISODE'::"text" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."bingos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."calendar_events" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "start_datetime" timestamp with time zone,
    "end_datetime" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_type" character varying,
    "drama_level" smallint,
    "event_entity_type" "text",
    "show_event_id" "uuid",
    "creator_event_id" "uuid",
    "trash_event_id" "uuid"
);


ALTER TABLE "public"."calendar_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creator_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "related_show_id" "uuid",
    "related_season_id" "uuid",
    "event_kind" "text" NOT NULL,
    "youtube_url" "text",
    "thumbnail_url" "text",
    "episode_number" integer,
    "title" "text",
    "description" "text"
);


ALTER TABLE "public"."creator_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."creators" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "avatar_url" "text",
    "youtube_channel_url" "text",
    "instagram_url" "text",
    "tiktok_url" "text"
);


ALTER TABLE "public"."creators" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."seasons" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "season_number" bigint,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid",
    "total_episodes" bigint,
    "release_frequency" character varying,
    "streaming_release_time" time without time zone,
    "streaming_release_date" "date",
    "episode_length" bigint,
    "streaming_option" character varying,
    "status" character varying(20) DEFAULT ''::character varying,
    "release_days" bigint[]
);


ALTER TABLE "public"."seasons" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."show_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "show_id" "uuid" NOT NULL,
    "season_id" "uuid",
    "event_subtype" "text" NOT NULL,
    "episode_number" integer,
    "description" "text"
);


ALTER TABLE "public"."show_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shows" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" character varying DEFAULT ''::character varying,
    "description" character varying,
    "genre" character varying,
    "status" character varying,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text",
    "tmdb_id" "text",
    "trakt_slug" "text",
    "short_title" character varying,
    "release_window" character varying,
    "header_image" "text",
    "main_color" "text"
);


ALTER TABLE "public"."shows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trash_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "image_url" "text",
    "location" "text",
    "address" "text",
    "organizer" "text",
    "price" "text",
    "external_url" "text",
    "related_show_id" "uuid",
    "related_season_id" "uuid"
);


ALTER TABLE "public"."trash_events" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."calendar_event_resolved" WITH ("security_invoker"='on') AS
 SELECT "ce"."id" AS "calendar_event_id",
    "ce"."start_datetime",
    "ce"."end_datetime",
    "ce"."event_entity_type",
    ("ce"."show_event_id" IS NOT NULL) AS "is_show_event",
    ("ce"."creator_event_id" IS NOT NULL) AS "is_creator_event",
    ("ce"."trash_event_id" IS NOT NULL) AS "is_trash_event",
    "se"."id" AS "show_event_id",
    "se"."created_at" AS "show_event_created_at",
    "se"."show_id" AS "show_event_show_id",
    "se"."season_id" AS "show_event_season_id",
    "se"."event_subtype" AS "show_event_subtype",
    "se"."episode_number" AS "show_event_episode_number",
    "se"."description" AS "show_event_description",
    "sh"."title" AS "show_event_show_title",
    "sh"."description" AS "show_event_show_description",
    "sh"."short_title" AS "show_event_show_short_title",
    "sh"."genre" AS "show_event_genre",
    "seas"."season_number" AS "show_event_season_number",
    "seas"."streaming_option" AS "show_event_streaming_option",
    "cee"."id" AS "creator_event_id",
    "cee"."created_at" AS "creator_event_created_at",
    "cee"."creator_id" AS "creator_event_creator_id",
    "cee"."related_show_id" AS "creator_related_show_id",
    "cee"."related_season_id" AS "creator_related_season_id",
    "cee"."event_kind" AS "creator_event_kind",
    "cee"."youtube_url" AS "creator_event_youtube_url",
    "cee"."thumbnail_url" AS "creator_event_thumbnail_url",
    "cee"."episode_number" AS "creator_event_episode_number",
    "cee"."title" AS "creator_event_title",
    "cee"."description" AS "creator_event_description",
    "c"."name" AS "creator_name",
    "c"."avatar_url" AS "creator_avatar_url",
    "c"."youtube_channel_url" AS "creator_youtube_channel_url",
    "c"."instagram_url" AS "creator_instagram_url",
    "c"."tiktok_url" AS "creator_tiktok_url",
    "te"."id" AS "trash_event_id",
    "te"."created_at" AS "trash_event_created_at",
    "te"."title" AS "trash_event_title",
    "te"."description" AS "trash_event_description",
    "te"."image_url" AS "trash_event_image_url",
    "te"."location" AS "trash_event_location",
    "te"."address" AS "trash_event_address",
    "te"."organizer" AS "trash_event_organizer",
    "te"."price" AS "trash_event_price",
    "te"."external_url" AS "trash_event_external_url",
    "te"."related_show_id" AS "trash_related_show_id",
    "te"."related_season_id" AS "trash_related_season_id"
   FROM (((((("public"."calendar_events" "ce"
     LEFT JOIN "public"."show_events" "se" ON (("se"."id" = "ce"."show_event_id")))
     LEFT JOIN "public"."shows" "sh" ON (("sh"."id" = "se"."show_id")))
     LEFT JOIN "public"."seasons" "seas" ON (("seas"."id" = "se"."season_id")))
     LEFT JOIN "public"."creator_events" "cee" ON (("cee"."id" = "ce"."creator_event_id")))
     LEFT JOIN "public"."creators" "c" ON (("c"."id" = "cee"."creator_id")))
     LEFT JOIN "public"."trash_events" "te" ON (("te"."id" = "ce"."trash_event_id")));


ALTER VIEW "public"."calendar_event_resolved" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feed_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "item_type" "text" NOT NULL,
    "data" "jsonb" NOT NULL,
    "feed_timestamp" timestamp with time zone DEFAULT "now"() NOT NULL,
    "priority" bigint
);


ALTER TABLE "public"."feed_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."news_ticker_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "headline" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "priority" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "news_ticker_items_headline_not_blank" CHECK (("length"(TRIM(BOTH FROM "headline")) > 0))
);


ALTER TABLE "public"."news_ticker_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."news_ticker_items" IS 'Headlines fuer den oberen Newsticker. Sortierung ueber priority.';



COMMENT ON COLUMN "public"."news_ticker_items"."is_active" IS 'Nur aktive Eintraege werden im Ticker ausgespielt.';



CREATE TABLE IF NOT EXISTS "public"."notification_outbox" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "sent_at" timestamp with time zone
);


ALTER TABLE "public"."notification_outbox" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."premium_waitlist" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "note" "text"
);


ALTER TABLE "public"."premium_waitlist" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    "bio" "text",
    "avatar_url" "text",
    "favorite_genres" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "preferred_streaming_services" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "notify_new_episodes" boolean DEFAULT true NOT NULL,
    "timezone" "text" DEFAULT 'Europe/Berlin'::"text" NOT NULL,
    "onboarding_completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_premium" boolean DEFAULT false NOT NULL,
    "premium_until" timestamp with time zone,
    CONSTRAINT "profiles_bio_len_chk" CHECK ((("bio" IS NULL) OR ("char_length"("bio") <= 240))),
    CONSTRAINT "profiles_display_name_len_chk" CHECK ((("char_length"(TRIM(BOTH FROM "display_name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "display_name")) <= 40)))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."show_social_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "show_id" "uuid" NOT NULL,
    "platform" "text" DEFAULT 'tiktok'::"text" NOT NULL,
    "tag" "text" NOT NULL,
    "display_tag" "text" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "priority" integer DEFAULT 10
);


ALTER TABLE "public"."show_social_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."show_social_videos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "show_id" "uuid" NOT NULL,
    "platform" "text" DEFAULT 'tiktok'::"text" NOT NULL,
    "video_url" "text" NOT NULL,
    "embed_html" "text",
    "priority" integer DEFAULT 10
);


ALTER TABLE "public"."show_social_videos" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."show_tiktok_data" WITH ("security_invoker"='on') AS
 SELECT "s"."id" AS "show_id",
    "s"."title",
    "t"."tag",
    "t"."display_tag",
    "t"."is_primary",
    "v"."video_url",
    "v"."embed_html"
   FROM (("public"."shows" "s"
     LEFT JOIN "public"."show_social_tags" "t" ON (("s"."id" = "t"."show_id")))
     LEFT JOIN "public"."show_social_videos" "v" ON (("s"."id" = "v"."show_id")));


ALTER VIEW "public"."show_tiktok_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."streaming_options" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "platform" character varying,
    "url" character varying,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid"
);


ALTER TABLE "public"."streaming_options" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_creator_relations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "interaction_type" "text" DEFAULT 'favorite'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_creator_relations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "fcm_token" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_devices_platform_check" CHECK (("platform" = ANY (ARRAY['ios'::"text", 'android'::"text", 'web'::"text"])))
);


ALTER TABLE "public"."user_devices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_preferences" (
    "user_id" "uuid" NOT NULL,
    "preference_key" "text" NOT NULL,
    "preference_value" "jsonb" DEFAULT 'null'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_show_relations" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "show_id" "uuid" NOT NULL,
    "interaction_type" character varying(50) NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_show_relations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."attendees" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying,
    "bio" character varying,
    "instagram_url" character varying,
    "tiktok_url" character varying,
    "twitter_url" character varying,
    "updated_at" timestamp with time zone,
    "role" character varying,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid",
    "season_id" "uuid"
);


ALTER TABLE "show_management"."attendees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."calendar_events" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "start_datetime" timestamp with time zone,
    "end_datetime" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid",
    "season_id" "uuid",
    "event_type" character varying
);


ALTER TABLE "show_management"."calendar_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."episodes" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" character varying,
    "episode_number" bigint,
    "duration" bigint,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "show_management"."episodes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."favorite_attendees" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" character varying,
    "user_id" "uuid",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "attendee_id" "uuid"
);


ALTER TABLE "show_management"."favorite_attendees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."favorite_shows" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" character varying,
    "user_id" "uuid",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid"
);


ALTER TABLE "show_management"."favorite_shows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."ingest_state" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "show_management"."ingest_state" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."seasons" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "season_number" bigint,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "show_id" "uuid",
    "total_episodes" bigint,
    "release_frequency" character varying,
    "streaming_release_time" time without time zone,
    "streaming_release_date" "date",
    "episode_length" bigint,
    "streaming_option" character varying
);


ALTER TABLE "show_management"."seasons" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."shows" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "title" character varying DEFAULT ''::character varying,
    "description" character varying,
    "genre" character varying,
    "status" character varying,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text"
);


ALTER TABLE "show_management"."shows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "show_management"."streaming_options" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "platform" character varying,
    "url" character varying,
    "updated_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid"
);


ALTER TABLE "show_management"."streaming_options" OWNER TO "postgres";


ALTER TABLE ONLY "public"."attendees"
    ADD CONSTRAINT "attendees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_event_types"
    ADD CONSTRAINT "bingo_event_types_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."bingo_event_types"
    ADD CONSTRAINT "bingo_event_types_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_items"
    ADD CONSTRAINT "bingo_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_items"
    ADD CONSTRAINT "bingo_items_unique_position" UNIQUE ("bingo_id", "position_index");



ALTER TABLE ONLY "public"."bingo_phrases"
    ADD CONSTRAINT "bingo_phrases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_session_emotions"
    ADD CONSTRAINT "bingo_session_emotions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_session_items"
    ADD CONSTRAINT "bingo_session_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingo_session_items"
    ADD CONSTRAINT "bingo_session_items_unique" UNIQUE ("bingo_session_id", "bingo_item_id");



ALTER TABLE ONLY "public"."bingo_session_stats"
    ADD CONSTRAINT "bingo_session_stats_pkey" PRIMARY KEY ("bingo_session_id");



ALTER TABLE ONLY "public"."bingo_sessions"
    ADD CONSTRAINT "bingo_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingos"
    ADD CONSTRAINT "bingos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bingos"
    ADD CONSTRAINT "bingos_unique_per_episode" UNIQUE ("show_event_id");



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."creator_events"
    ADD CONSTRAINT "creator_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."creators"
    ADD CONSTRAINT "creators_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feed_items"
    ADD CONSTRAINT "feed_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."news_ticker_items"
    ADD CONSTRAINT "news_ticker_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_outbox"
    ADD CONSTRAINT "notification_outbox_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."premium_waitlist"
    ADD CONSTRAINT "premium_waitlist_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."show_events"
    ADD CONSTRAINT "show_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."show_social_tags"
    ADD CONSTRAINT "show_social_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."show_social_videos"
    ADD CONSTRAINT "show_social_videos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shows"
    ADD CONSTRAINT "shows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."streaming_options"
    ADD CONSTRAINT "streaming_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trash_events"
    ADD CONSTRAINT "trash_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_creator_relations"
    ADD CONSTRAINT "user_creator_relations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_creator_relations"
    ADD CONSTRAINT "user_creator_relations_user_id_creator_id_interaction_type_key" UNIQUE ("user_id", "creator_id", "interaction_type");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("user_id", "preference_key");



ALTER TABLE ONLY "public"."user_show_relations"
    ADD CONSTRAINT "user_show_interactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_show_relations"
    ADD CONSTRAINT "user_show_interactions_user_id_show_id_interaction_type_key" UNIQUE ("user_id", "show_id", "interaction_type");



ALTER TABLE ONLY "show_management"."attendees"
    ADD CONSTRAINT "attendees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."calendar_events"
    ADD CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."episodes"
    ADD CONSTRAINT "episodes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."favorite_attendees"
    ADD CONSTRAINT "favorite_attendees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."favorite_shows"
    ADD CONSTRAINT "favorite_shows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."ingest_state"
    ADD CONSTRAINT "ingest_state_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "show_management"."seasons"
    ADD CONSTRAINT "seasons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."shows"
    ADD CONSTRAINT "shows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "show_management"."streaming_options"
    ADD CONSTRAINT "streaming_options_pkey" PRIMARY KEY ("id");



CREATE INDEX "attendees_name_idx" ON "public"."attendees" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_bingo_session_items_checked" ON "public"."bingo_session_items" USING "btree" ("bingo_session_id", "checked_at") WHERE ("checked_at" IS NOT NULL);



CREATE INDEX "idx_bingo_session_items_session" ON "public"."bingo_session_items" USING "btree" ("bingo_session_id");



CREATE INDEX "idx_news_ticker_items_active_priority" ON "public"."news_ticker_items" USING "btree" ("is_active", "priority");



CREATE INDEX "idx_news_ticker_items_priority" ON "public"."news_ticker_items" USING "btree" ("priority");



CREATE INDEX "idx_news_ticker_items_updated_at" ON "public"."news_ticker_items" USING "btree" ("updated_at" DESC);



CREATE INDEX "idx_seasons_release_date" ON "public"."seasons" USING "btree" ("streaming_release_date");



CREATE INDEX "profiles_created_at_idx" ON "public"."profiles" USING "btree" ("created_at" DESC);



CREATE INDEX "profiles_display_name_idx" ON "public"."profiles" USING "btree" ("lower"("display_name"));



CREATE INDEX "shows_title_idx" ON "public"."shows" USING "gin" ("title" "public"."gin_trgm_ops");



CREATE UNIQUE INDEX "uniq_user_device_token" ON "public"."user_devices" USING "btree" ("fcm_token");



CREATE UNIQUE INDEX "uq_seasons_show_season" ON "public"."seasons" USING "btree" ("show_id", "season_number");



CREATE UNIQUE INDEX "uq_shows_slug" ON "public"."shows" USING "btree" ("slug");



CREATE UNIQUE INDEX "uq_streaming_season_platform" ON "public"."streaming_options" USING "btree" ("season_id", "platform");



CREATE INDEX "attendees_name_idx" ON "show_management"."attendees" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_seasons_release_date" ON "show_management"."seasons" USING "btree" ("streaming_release_date");



CREATE INDEX "shows_title_idx" ON "show_management"."shows" USING "gin" ("title" "public"."gin_trgm_ops");



CREATE UNIQUE INDEX "uq_seasons_show_season" ON "show_management"."seasons" USING "btree" ("show_id", "season_number");



CREATE UNIQUE INDEX "uq_shows_slug" ON "show_management"."shows" USING "btree" ("slug");



CREATE OR REPLACE TRIGGER "trg_news_ticker_items_set_priority" BEFORE INSERT ON "public"."news_ticker_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_priority_news_ticker_items"();



CREATE OR REPLACE TRIGGER "trg_news_ticker_items_set_updated_at" BEFORE UPDATE ON "public"."news_ticker_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at_news_ticker_items"();



CREATE OR REPLACE TRIGGER "trg_profiles_set_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_bingo_stats" AFTER INSERT OR UPDATE ON "public"."bingo_session_items" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_calculate_bingo_on_check"();



CREATE OR REPLACE TRIGGER "trigger_manage_calendar_events" AFTER INSERT OR UPDATE ON "public"."seasons" FOR EACH ROW EXECUTE FUNCTION "public"."manage_calendar_events"();



CREATE OR REPLACE TRIGGER "trg_seasons_updated_at" BEFORE UPDATE ON "show_management"."seasons" FOR EACH ROW EXECUTE FUNCTION "show_management"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_shows_updated_at" BEFORE UPDATE ON "show_management"."shows" FOR EACH ROW EXECUTE FUNCTION "show_management"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_generate_calendar_events" AFTER INSERT ON "show_management"."seasons" FOR EACH ROW EXECUTE FUNCTION "public"."generate_calendar_events"();



ALTER TABLE ONLY "public"."bingo_items"
    ADD CONSTRAINT "bingo_items_bingo_fkey" FOREIGN KEY ("bingo_id") REFERENCES "public"."bingos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_items"
    ADD CONSTRAINT "bingo_items_event_type_fkey" FOREIGN KEY ("event_type_id") REFERENCES "public"."bingo_event_types"("id");



ALTER TABLE ONLY "public"."bingo_items"
    ADD CONSTRAINT "bingo_items_phrase_fkey" FOREIGN KEY ("phrase_id") REFERENCES "public"."bingo_phrases"("id");



ALTER TABLE ONLY "public"."bingo_phrases"
    ADD CONSTRAINT "bingo_phrases_event_type_fkey" FOREIGN KEY ("event_type_id") REFERENCES "public"."bingo_event_types"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_phrases"
    ADD CONSTRAINT "bingo_phrases_show_fkey" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_emotions"
    ADD CONSTRAINT "bingo_session_emotions_bingo_session_id_fkey" FOREIGN KEY ("bingo_session_id") REFERENCES "public"."bingo_sessions"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_emotions"
    ADD CONSTRAINT "bingo_session_emotions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_items"
    ADD CONSTRAINT "bingo_session_items_bingo_item_id_fkey" FOREIGN KEY ("bingo_item_id") REFERENCES "public"."bingo_items"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_items"
    ADD CONSTRAINT "bingo_session_items_bingo_session_id_fkey" FOREIGN KEY ("bingo_session_id") REFERENCES "public"."bingo_sessions"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_items"
    ADD CONSTRAINT "bingo_session_items_checked_by_fkey" FOREIGN KEY ("checked_by") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_stats"
    ADD CONSTRAINT "bingo_session_stats_bingo_session_id_fkey" FOREIGN KEY ("bingo_session_id") REFERENCES "public"."bingo_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_session_stats"
    ADD CONSTRAINT "bingo_session_stats_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_sessions"
    ADD CONSTRAINT "bingo_sessions_bingo_fkey" FOREIGN KEY ("bingo_id") REFERENCES "public"."bingos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingo_sessions"
    ADD CONSTRAINT "bingo_sessions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bingos"
    ADD CONSTRAINT "bingos_show_event_id_fkey" FOREIGN KEY ("show_event_id") REFERENCES "public"."show_events"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_creator_event_id_fkey" FOREIGN KEY ("creator_event_id") REFERENCES "public"."creator_events"("id");



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_show_event_id_fkey" FOREIGN KEY ("show_event_id") REFERENCES "public"."show_events"("id");



ALTER TABLE ONLY "public"."calendar_events"
    ADD CONSTRAINT "calendar_events_trash_event_id_fkey" FOREIGN KEY ("trash_event_id") REFERENCES "public"."trash_events"("id");



ALTER TABLE ONLY "public"."creator_events"
    ADD CONSTRAINT "creator_events_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."creators"("id");



ALTER TABLE ONLY "public"."creator_events"
    ADD CONSTRAINT "creator_events_related_season_id_fkey" FOREIGN KEY ("related_season_id") REFERENCES "public"."seasons"("id");



ALTER TABLE ONLY "public"."creator_events"
    ADD CONSTRAINT "creator_events_related_show_id_fkey" FOREIGN KEY ("related_show_id") REFERENCES "public"."shows"("id");



ALTER TABLE ONLY "public"."attendees"
    ADD CONSTRAINT "fk_season" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."attendees"
    ADD CONSTRAINT "fk_show" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "fk_show_season" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notification_outbox"
    ADD CONSTRAINT "notification_outbox_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."premium_waitlist"
    ADD CONSTRAINT "premium_waitlist_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."show_events"
    ADD CONSTRAINT "show_events_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."show_events"
    ADD CONSTRAINT "show_events_show_id_fkey" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."show_social_tags"
    ADD CONSTRAINT "show_social_tags_show_id_fkey" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."show_social_videos"
    ADD CONSTRAINT "show_social_videos_show_id_fkey" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."streaming_options"
    ADD CONSTRAINT "streaming_options_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trash_events"
    ADD CONSTRAINT "trash_events_related_season_id_fkey" FOREIGN KEY ("related_season_id") REFERENCES "public"."seasons"("id");



ALTER TABLE ONLY "public"."trash_events"
    ADD CONSTRAINT "trash_events_related_show_id_fkey" FOREIGN KEY ("related_show_id") REFERENCES "public"."shows"("id");



ALTER TABLE ONLY "public"."user_creator_relations"
    ADD CONSTRAINT "user_creator_relations_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."creators"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_creator_relations"
    ADD CONSTRAINT "user_creator_relations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_show_relations"
    ADD CONSTRAINT "user_show_interactions_show_id_fkey" FOREIGN KEY ("show_id") REFERENCES "public"."shows"("id");



ALTER TABLE ONLY "public"."user_show_relations"
    ADD CONSTRAINT "user_show_relations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "show_management"."favorite_attendees"
    ADD CONSTRAINT "favorite_attendees_attendee_id_fkey" FOREIGN KEY ("attendee_id") REFERENCES "show_management"."attendees"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "show_management"."favorite_attendees"
    ADD CONSTRAINT "favorite_attendees_show_id_fkey" FOREIGN KEY ("attendee_id") REFERENCES "show_management"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."favorite_attendees"
    ADD CONSTRAINT "favorite_attendees_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "show_management"."favorite_attendees"
    ADD CONSTRAINT "favorite_attendees_user_id_fkey1" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "show_management"."favorite_shows"
    ADD CONSTRAINT "favorite_shows_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "show_management"."favorite_shows"
    ADD CONSTRAINT "fk_favorite_show" FOREIGN KEY ("show_id") REFERENCES "show_management"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."attendees"
    ADD CONSTRAINT "fk_season" FOREIGN KEY ("season_id") REFERENCES "show_management"."seasons"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."calendar_events"
    ADD CONSTRAINT "fk_season_event" FOREIGN KEY ("season_id") REFERENCES "show_management"."seasons"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."attendees"
    ADD CONSTRAINT "fk_show" FOREIGN KEY ("show_id") REFERENCES "show_management"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."calendar_events"
    ADD CONSTRAINT "fk_show_event" FOREIGN KEY ("show_id") REFERENCES "show_management"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."seasons"
    ADD CONSTRAINT "fk_show_season" FOREIGN KEY ("show_id") REFERENCES "show_management"."shows"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "show_management"."streaming_options"
    ADD CONSTRAINT "streaming_options_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "show_management"."seasons"("id") ON UPDATE CASCADE ON DELETE CASCADE;



CREATE POLICY "Enable delete for users based on user_id" ON "public"."user_show_relations" FOR DELETE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_event_types" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_phrases" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_session_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_session_stats" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingo_sessions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."bingos" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."user_devices" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."user_show_relations" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for users based on user_id" ON "public"."bingo_sessions" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "created_by")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "created_by"));



CREATE POLICY "Enable insert for users based on user_id" ON "public"."premium_waitlist" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Enable read access for all users" ON "public"."attendees" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_event_types" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_items" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_phrases" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_session_items" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_session_stats" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingo_sessions" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."bingos" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."calendar_events" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."creator_events" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."creators" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."feed_items" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."premium_waitlist" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."seasons" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."show_events" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."show_social_tags" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."show_social_videos" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."shows" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."streaming_options" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."trash_events" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."user_creator_relations" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."user_devices" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."user_show_relations" FOR SELECT USING (true);



CREATE POLICY "Enable update for authenticated users only" ON "public"."user_devices" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK (true);



ALTER TABLE "public"."attendees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bingos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."calendar_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."creator_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."creators" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "delete own preferences" ON "public"."user_preferences" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "editor_delete_calendar_events" ON "public"."calendar_events" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_creator_events" ON "public"."creator_events" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_creators" ON "public"."creators" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_feed_items" ON "public"."feed_items" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_seasons" ON "public"."seasons" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_show_events" ON "public"."show_events" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_show_social_tags" ON "public"."show_social_tags" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_show_social_videos" ON "public"."show_social_videos" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_shows" ON "public"."shows" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_streaming_options" ON "public"."streaming_options" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_trash_events" ON "public"."trash_events" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_user_creator_relations" ON "public"."user_creator_relations" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_delete_user_preferences" ON "public"."user_preferences" FOR DELETE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_calendar_events" ON "public"."calendar_events" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_creator_events" ON "public"."creator_events" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_creators" ON "public"."creators" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_feed_items" ON "public"."feed_items" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_seasons" ON "public"."seasons" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_show_events" ON "public"."show_events" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_show_social_tags" ON "public"."show_social_tags" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_show_social_videos" ON "public"."show_social_videos" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_shows" ON "public"."shows" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_streaming_options" ON "public"."streaming_options" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_trash_events" ON "public"."trash_events" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_user_creator_relations" ON "public"."user_creator_relations" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_insert_user_preferences" ON "public"."user_preferences" FOR INSERT TO "authenticated" WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_calendar_events" ON "public"."calendar_events" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_creator_events" ON "public"."creator_events" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_creators" ON "public"."creators" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_feed_items" ON "public"."feed_items" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_seasons" ON "public"."seasons" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_show_events" ON "public"."show_events" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_show_social_tags" ON "public"."show_social_tags" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_show_social_videos" ON "public"."show_social_videos" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_shows" ON "public"."shows" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_streaming_options" ON "public"."streaming_options" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_trash_events" ON "public"."trash_events" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_user_creator_relations" ON "public"."user_creator_relations" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



CREATE POLICY "editor_update_user_preferences" ON "public"."user_preferences" FOR UPDATE TO "authenticated" USING ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text")) WITH CHECK ((((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" -> 'app_metadata'::"text") -> 'roles'::"text") ? 'editor'::"text"));



ALTER TABLE "public"."feed_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "news_ticker_admin_delete" ON "public"."news_ticker_items" FOR DELETE TO "authenticated" USING (((COALESCE(("auth"."jwt"() ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])) OR (COALESCE((("auth"."jwt"() -> 'app_metadata'::"text") ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"]))));



CREATE POLICY "news_ticker_admin_insert" ON "public"."news_ticker_items" FOR INSERT TO "authenticated" WITH CHECK (((COALESCE(("auth"."jwt"() ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])) OR (COALESCE((("auth"."jwt"() -> 'app_metadata'::"text") ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"]))));



CREATE POLICY "news_ticker_admin_read_all" ON "public"."news_ticker_items" FOR SELECT TO "authenticated" USING (((COALESCE(("auth"."jwt"() ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])) OR (COALESCE((("auth"."jwt"() -> 'app_metadata'::"text") ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"]))));



CREATE POLICY "news_ticker_admin_update" ON "public"."news_ticker_items" FOR UPDATE TO "authenticated" USING (((COALESCE(("auth"."jwt"() ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])) OR (COALESCE((("auth"."jwt"() -> 'app_metadata'::"text") ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])))) WITH CHECK (((COALESCE(("auth"."jwt"() ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"])) OR (COALESCE((("auth"."jwt"() -> 'app_metadata'::"text") ->> 'role'::"text"), ''::"text") = ANY (ARRAY['admin'::"text", 'editor'::"text"]))));



ALTER TABLE "public"."news_ticker_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "news_ticker_public_read_active" ON "public"."news_ticker_items" FOR SELECT TO "authenticated", "anon" USING (("is_active" = true));



ALTER TABLE "public"."notification_outbox" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."premium_waitlist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_delete_own" ON "public"."profiles" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "profiles_insert_own" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "profiles_select_own" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "read own preferences" ON "public"."user_preferences" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."seasons" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."show_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."show_social_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."show_social_videos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."streaming_options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."trash_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "update own preferences" ON "public"."user_preferences" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "upsert own preferences" ON "public"."user_preferences" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."user_creator_relations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_devices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_show_relations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Enable read access for all users" ON "show_management"."attendees" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."calendar_events" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."episodes" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."favorite_attendees" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."favorite_shows" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."seasons" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."shows" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "show_management"."streaming_options" FOR SELECT USING (true);



ALTER TABLE "show_management"."attendees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."calendar_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."episodes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."favorite_attendees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."favorite_shows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."seasons" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."shows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "show_management"."streaming_options" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






GRANT USAGE ON SCHEMA "show_management" TO "anon";
GRANT USAGE ON SCHEMA "show_management" TO "authenticated";
GRANT USAGE ON SCHEMA "show_management" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";
























SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;
























































































































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;

































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;












GRANT ALL ON TABLE "public"."bingo_session_stats" TO "anon";
GRANT ALL ON TABLE "public"."bingo_session_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_session_stats" TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_bingo_session_stats"("p_bingo_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_bingo_session_stats"("p_bingo_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_bingo_session_stats"("p_bingo_session_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_account"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_account"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_account"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_live"() TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_live"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_live"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_reminders"() TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_reminders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_calendar_event_reminders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enqueue_daily_digest"() TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_daily_digest"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_daily_digest"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enqueue_daily_digest_favorite"() TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_daily_digest_favorite"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_daily_digest_favorite"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enqueue_premiere_one_day_before_live"() TO "anon";
GRANT ALL ON FUNCTION "public"."enqueue_premiere_one_day_before_live"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enqueue_premiere_one_day_before_live"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_almost_complete_season_item"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_almost_complete_season_item"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_almost_complete_season_item"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_coming_this_week_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_coming_this_week_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_coming_this_week_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_creator_spotlight_card"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_creator_spotlight_card"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_creator_spotlight_card"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_featured_show_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_featured_show_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_featured_show_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_generic_bingo_stats_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_generic_bingo_stats_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_generic_bingo_stats_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_latest_releases_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_latest_releases_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_latest_releases_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_monthly_overview_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_monthly_overview_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_monthly_overview_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_next_3_premieres_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_next_3_premieres_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_next_3_premieres_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_next_month_preview_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_next_month_preview_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_next_month_preview_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_random_show"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_random_show"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_random_show"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_season_finale_item"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_season_finale_item"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_season_finale_item"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_season_starts_soon_item"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_season_starts_soon_item"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_season_starts_soon_item"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_today_shows_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_today_shows_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_today_shows_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_feed_weekend_binge_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_feed_weekend_binge_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_feed_weekend_binge_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_bingo_for_show_event"("p_show_event_id" "uuid", "p_grid_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."generate_bingo_for_show_event"("p_show_event_id" "uuid", "p_grid_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_bingo_for_show_event"("p_show_event_id" "uuid", "p_grid_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_calendar_events"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_calendar_events"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_calendar_events"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_editor_policies"("tables" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."generate_editor_policies"("tables" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_editor_policies"("tables" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_calendar_events_with_shows_by_date"("event_date" timestamp with time zone, "show_ids" "uuid"[], "attendee_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_calendar_events_with_shows_by_date"("event_date" timestamp with time zone, "show_ids" "uuid"[], "attendee_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_calendar_events_with_shows_by_date"("event_date" timestamp with time zone, "show_ids" "uuid"[], "attendee_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user_profile"() TO "service_role";



GRANT ALL ON FUNCTION "public"."manage_calendar_events"() TO "anon";
GRANT ALL ON FUNCTION "public"."manage_calendar_events"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."manage_calendar_events"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_season_start"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_season_start"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_season_start"() TO "service_role";



GRANT ALL ON FUNCTION "public"."search_shows_and_attendees"("query" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_shows_and_attendees"("query" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_shows_and_attendees"("query" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_priority_news_ticker_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_priority_news_ticker_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_priority_news_ticker_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at_news_ticker_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at_news_ticker_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at_news_ticker_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_on_check"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_on_check"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_on_check"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_session_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_session_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_calculate_bingo_session_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."truncate_feed_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."truncate_feed_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."truncate_feed_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "show_management"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "show_management"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "show_management"."set_updated_at"() TO "service_role";



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;
























GRANT ALL ON TABLE "public"."attendees" TO "anon";
GRANT ALL ON TABLE "public"."attendees" TO "authenticated";
GRANT ALL ON TABLE "public"."attendees" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_event_types" TO "anon";
GRANT ALL ON TABLE "public"."bingo_event_types" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_event_types" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_items" TO "anon";
GRANT ALL ON TABLE "public"."bingo_items" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_items" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_phrases" TO "anon";
GRANT ALL ON TABLE "public"."bingo_phrases" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_phrases" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_session_emotions" TO "anon";
GRANT ALL ON TABLE "public"."bingo_session_emotions" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_session_emotions" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_session_items" TO "anon";
GRANT ALL ON TABLE "public"."bingo_session_items" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_session_items" TO "service_role";



GRANT ALL ON TABLE "public"."bingo_sessions" TO "anon";
GRANT ALL ON TABLE "public"."bingo_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."bingo_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."bingos" TO "anon";
GRANT ALL ON TABLE "public"."bingos" TO "authenticated";
GRANT ALL ON TABLE "public"."bingos" TO "service_role";



GRANT ALL ON TABLE "public"."calendar_events" TO "anon";
GRANT ALL ON TABLE "public"."calendar_events" TO "authenticated";
GRANT ALL ON TABLE "public"."calendar_events" TO "service_role";



GRANT ALL ON TABLE "public"."creator_events" TO "anon";
GRANT ALL ON TABLE "public"."creator_events" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_events" TO "service_role";



GRANT ALL ON TABLE "public"."creators" TO "anon";
GRANT ALL ON TABLE "public"."creators" TO "authenticated";
GRANT ALL ON TABLE "public"."creators" TO "service_role";



GRANT ALL ON TABLE "public"."seasons" TO "anon";
GRANT ALL ON TABLE "public"."seasons" TO "authenticated";
GRANT ALL ON TABLE "public"."seasons" TO "service_role";



GRANT ALL ON TABLE "public"."show_events" TO "anon";
GRANT ALL ON TABLE "public"."show_events" TO "authenticated";
GRANT ALL ON TABLE "public"."show_events" TO "service_role";



GRANT ALL ON TABLE "public"."shows" TO "anon";
GRANT ALL ON TABLE "public"."shows" TO "authenticated";
GRANT ALL ON TABLE "public"."shows" TO "service_role";



GRANT ALL ON TABLE "public"."trash_events" TO "anon";
GRANT ALL ON TABLE "public"."trash_events" TO "authenticated";
GRANT ALL ON TABLE "public"."trash_events" TO "service_role";



GRANT ALL ON TABLE "public"."calendar_event_resolved" TO "anon";
GRANT ALL ON TABLE "public"."calendar_event_resolved" TO "authenticated";
GRANT ALL ON TABLE "public"."calendar_event_resolved" TO "service_role";



GRANT ALL ON TABLE "public"."feed_items" TO "anon";
GRANT ALL ON TABLE "public"."feed_items" TO "authenticated";
GRANT ALL ON TABLE "public"."feed_items" TO "service_role";



GRANT ALL ON TABLE "public"."news_ticker_items" TO "anon";
GRANT ALL ON TABLE "public"."news_ticker_items" TO "authenticated";
GRANT ALL ON TABLE "public"."news_ticker_items" TO "service_role";



GRANT ALL ON TABLE "public"."notification_outbox" TO "anon";
GRANT ALL ON TABLE "public"."notification_outbox" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_outbox" TO "service_role";



GRANT ALL ON TABLE "public"."premium_waitlist" TO "anon";
GRANT ALL ON TABLE "public"."premium_waitlist" TO "authenticated";
GRANT ALL ON TABLE "public"."premium_waitlist" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."show_social_tags" TO "anon";
GRANT ALL ON TABLE "public"."show_social_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."show_social_tags" TO "service_role";



GRANT ALL ON TABLE "public"."show_social_videos" TO "anon";
GRANT ALL ON TABLE "public"."show_social_videos" TO "authenticated";
GRANT ALL ON TABLE "public"."show_social_videos" TO "service_role";



GRANT ALL ON TABLE "public"."show_tiktok_data" TO "anon";
GRANT ALL ON TABLE "public"."show_tiktok_data" TO "authenticated";
GRANT ALL ON TABLE "public"."show_tiktok_data" TO "service_role";



GRANT ALL ON TABLE "public"."streaming_options" TO "anon";
GRANT ALL ON TABLE "public"."streaming_options" TO "authenticated";
GRANT ALL ON TABLE "public"."streaming_options" TO "service_role";



GRANT ALL ON TABLE "public"."user_creator_relations" TO "anon";
GRANT ALL ON TABLE "public"."user_creator_relations" TO "authenticated";
GRANT ALL ON TABLE "public"."user_creator_relations" TO "service_role";



GRANT ALL ON TABLE "public"."user_devices" TO "anon";
GRANT ALL ON TABLE "public"."user_devices" TO "authenticated";
GRANT ALL ON TABLE "public"."user_devices" TO "service_role";



GRANT ALL ON TABLE "public"."user_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."user_show_relations" TO "anon";
GRANT ALL ON TABLE "public"."user_show_relations" TO "authenticated";
GRANT ALL ON TABLE "public"."user_show_relations" TO "service_role";



GRANT ALL ON TABLE "show_management"."attendees" TO "anon";
GRANT ALL ON TABLE "show_management"."attendees" TO "authenticated";
GRANT ALL ON TABLE "show_management"."attendees" TO "service_role";



GRANT ALL ON TABLE "show_management"."calendar_events" TO "anon";
GRANT ALL ON TABLE "show_management"."calendar_events" TO "authenticated";
GRANT ALL ON TABLE "show_management"."calendar_events" TO "service_role";



GRANT ALL ON TABLE "show_management"."episodes" TO "anon";
GRANT ALL ON TABLE "show_management"."episodes" TO "authenticated";
GRANT ALL ON TABLE "show_management"."episodes" TO "service_role";



GRANT ALL ON TABLE "show_management"."favorite_attendees" TO "anon";
GRANT ALL ON TABLE "show_management"."favorite_attendees" TO "authenticated";
GRANT ALL ON TABLE "show_management"."favorite_attendees" TO "service_role";



GRANT ALL ON TABLE "show_management"."favorite_shows" TO "anon";
GRANT ALL ON TABLE "show_management"."favorite_shows" TO "authenticated";
GRANT ALL ON TABLE "show_management"."favorite_shows" TO "service_role";



GRANT ALL ON TABLE "show_management"."ingest_state" TO "anon";
GRANT ALL ON TABLE "show_management"."ingest_state" TO "authenticated";
GRANT ALL ON TABLE "show_management"."ingest_state" TO "service_role";



GRANT ALL ON TABLE "show_management"."seasons" TO "anon";
GRANT ALL ON TABLE "show_management"."seasons" TO "authenticated";
GRANT ALL ON TABLE "show_management"."seasons" TO "service_role";



GRANT ALL ON TABLE "show_management"."shows" TO "anon";
GRANT ALL ON TABLE "show_management"."shows" TO "authenticated";
GRANT ALL ON TABLE "show_management"."shows" TO "service_role";



GRANT ALL ON TABLE "show_management"."streaming_options" TO "anon";
GRANT ALL ON TABLE "show_management"."streaming_options" TO "authenticated";
GRANT ALL ON TABLE "show_management"."streaming_options" TO "service_role";



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "show_management" GRANT ALL ON TABLES TO "service_role";




























drop extension if exists "pg_net";

create extension if not exists "pg_net" with schema "public";

drop policy "news_ticker_public_read_active" on "public"."news_ticker_items";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.manage_calendar_events()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
  event_date TIMESTAMPTZ;
  base_date  TIMESTAMPTZ;
  event_type TEXT;

  calendar_event_id UUID;
  show_event_id UUID;

  episode_len   INTERVAL;
  episode_start TIMESTAMPTZ;

  per_week INT;
  week_no  INT;

  drama_level INT;

  next_day INT;
  i INT;
BEGIN
  IF NEW.total_episodes IS NULL OR NEW.total_episodes <= 0 THEN
    RAISE EXCEPTION 'Total episodes must be greater than 0';
  END IF;

  -- =====================================================
  -- Bei UPDATE: Events der Season komplett neu aufbauen
  -- =====================================================
-- IMMER: vorhandene Events dieser Season entfernen

DELETE FROM public.calendar_events ce
USING public.show_events se
WHERE ce.show_event_id = se.id AND se.season_id = NEW.id;

DELETE FROM public.show_events
WHERE season_id = NEW.id;


event_date :=
  (NEW.streaming_release_date::timestamp
   + NEW.streaming_release_time)
  AT TIME ZONE 'UTC';

  base_date := event_date;

  episode_len := NEW.episode_length * INTERVAL '1 minute';

  -- =====================================================
  -- Episoden-Loop
  -- =====================================================
  FOR i IN 0 .. (NEW.total_episodes - 1) LOOP

    event_type := CASE
      WHEN i = 0 THEN 'premiere'
      WHEN i = NEW.total_episodes - 1 THEN 'finale'
      ELSE 'regular'
    END;

    drama_level := CASE
      WHEN event_type IN ('premiere', 'finale')
        THEN floor(random() * 2 + 9)
      ELSE floor(random() * 5 + 6)
    END;

    -- =====================================================
    -- RELEASE-LOGIK
    -- =====================================================
    IF NEW.release_frequency = 'weekly2' THEN
      per_week := 2;
      week_no := i / per_week;
      episode_start := base_date + week_no * INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'weekly3' THEN
      per_week := 3;
      week_no := i / per_week;
      episode_start := base_date + week_no * INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'daily' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 day';

    ELSIF NEW.release_frequency = 'weekly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 week';

    ELSIF NEW.release_frequency = 'biweekly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '2 weeks';

    ELSIF NEW.release_frequency = 'monthly' THEN
      episode_start := event_date;
      event_date := event_date + INTERVAL '1 month';

    -- =====================================================
    -- ✅ KORRIGIERT: MULTI WEEKLY
    -- =====================================================
    ELSIF NEW.release_frequency = 'multi_weekly' THEN
  IF NEW.release_days IS NULL OR array_length(NEW.release_days, 1) = 0 THEN
    RAISE EXCEPTION 'release_days[] must be provided when using multi_weekly';
  END IF;

  per_week := array_length(NEW.release_days, 1);

  -- Wir arbeiten nur mit dem Datumsteil von base_date (Zeit bleibt erhalten)
  base_date := base_date; -- nur Lesbarkeit
  episode_len := NEW.episode_length * INTERVAL '1 minute'; -- bleibt bei dir eh oben

  -- Wochentag des Anchors (Postgres: 0=Sonntag ... 6=Samstag)
  -- Wir nutzen dafür day-Teil, damit die Offsetrechnung konsistent ist.
  next_day := NULL; -- nur um Warnungen zu vermeiden
  DECLARE
    start_dow INT;
    k INT;
    prev_off INT;
    raw_off INT;
    off INT[];
  BEGIN
    start_dow := EXTRACT(DOW FROM date_trunc('day', base_date))::int;

    -- Offsets für release_days[k] innerhalb EINER "multi_weekly"-Sequenz aufbauen,
    -- sodass sie monoton steigen (Wrap = +7 Tage).
    off := ARRAY[]::INT[];
    prev_off := -1;

    FOR k IN 1..per_week LOOP
      raw_off := ((NEW.release_days[k]::int - start_dow + 7) % 7); -- 0..6
      IF prev_off = -1 THEN
        off := off || raw_off;
        prev_off := raw_off;
      ELSE
        IF raw_off < prev_off THEN
          raw_off := raw_off + 7; -- Wrap in nächste Woche innerhalb des Durchlaufs
        END IF;
        off := off || raw_off;
        prev_off := raw_off;
      END IF;
    END LOOP;

    week_no := i / per_week;           -- 0-basiert
    next_day := (i % per_week) + 1;   -- Index in off[]

    episode_start :=
      date_trunc('day', base_date)
      + make_interval(secs => 0) + (off[next_day] * INTERVAL '1 day')
      + (week_no * INTERVAL '1 week')
      + (base_date - date_trunc('day', base_date)); -- Uhrzeit beibehalten
  END;

    ELSIF NEW.release_frequency = 'premiere3_then_weekly' THEN
      episode_start := event_date;

      IF (i + 1) = 3 THEN
        event_date := event_date + INTERVAL '1 week';
      ELSIF (i + 1) > 3 THEN
        event_date := event_date + INTERVAL '1 week';
      END IF;

    ELSIF NEW.release_frequency = 'premiere2_then_weekly' THEN
      episode_start := event_date;

      IF (i + 1) = 2 THEN
        event_date := event_date + INTERVAL '1 week';
      ELSIF (i + 1) > 2 THEN
        event_date := event_date + INTERVAL '1 week';
      END IF;

    ELSE
      episode_start := event_date;
    END IF;

    -- =====================================================
    -- INSERT: show_events
    -- =====================================================
    show_event_id := extensions.uuid_generate_v4();
    calendar_event_id := extensions.uuid_generate_v4();

    INSERT INTO public.show_events (
      id,
      show_id,
      season_id,
      event_subtype,
      episode_number,
      description
    ) VALUES (
      show_event_id,
      NEW.show_id,
      NEW.id,
      event_type,
      i + 1,
      NULL
    );

    -- =====================================================
    -- INSERT: calendar_events
    -- =====================================================
    INSERT INTO public.calendar_events (
      id,
      start_datetime,
      end_datetime,
      event_type,
      drama_level,
      event_entity_type,
      show_event_id,
      creator_event_id,
      trash_event_id
    ) VALUES (
      calendar_event_id,
      episode_start,
      episode_start + episode_len,
      event_type,
      drama_level,
      'show_event',
      show_event_id,
      NULL,
      NULL
    );

  END LOOP;

  RETURN NEW;
END;$function$
;


  create policy "news_ticker_public_read_active"
  on "public"."news_ticker_items"
  as permissive
  for select
  to anon, authenticated
using ((is_active = true));


CREATE TRIGGER on_auth_user_created_profile AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();


