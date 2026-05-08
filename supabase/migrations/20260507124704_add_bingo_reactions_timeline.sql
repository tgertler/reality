-- Live timeline support for bingo watch sessions.
ALTER TABLE public.bingo_sessions
	ADD COLUMN IF NOT EXISTS phase text NOT NULL DEFAULT 'PRESTART',
	ADD COLUMN IF NOT EXISTS countdown_started_at timestamptz,
	ADD COLUMN IF NOT EXISTS live_started_at timestamptz;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conname = 'bingo_sessions_phase_check'
			AND conrelid = 'public.bingo_sessions'::regclass
	) THEN
		ALTER TABLE public.bingo_sessions
			ADD CONSTRAINT bingo_sessions_phase_check
			CHECK (phase = ANY (ARRAY['PRESTART'::text, 'LIVE'::text, 'COMPLETED'::text]));
	END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.bingo_session_reactions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	bingo_session_id uuid NOT NULL REFERENCES public.bingo_sessions(id) ON DELETE CASCADE,
	show_event_id uuid NOT NULL,
	user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
	emoji text NOT NULL,
	anchor text NOT NULL CHECK (anchor = ANY (ARRAY['BEGINNING'::text, 'MIDDLE'::text, 'END'::text])),
	reaction_offset_seconds integer NOT NULL CHECK (reaction_offset_seconds >= 0),
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bingo_session_reactions_session
	ON public.bingo_session_reactions (bingo_session_id, created_at);

CREATE INDEX IF NOT EXISTS idx_bingo_session_reactions_show_anchor_offset
	ON public.bingo_session_reactions (show_event_id, anchor, reaction_offset_seconds);

ALTER TABLE public.bingo_session_reactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM pg_policies
		WHERE schemaname = 'public'
			AND tablename = 'bingo_session_reactions'
			AND policyname = 'Enable read access for authenticated users'
	) THEN
		CREATE POLICY "Enable read access for authenticated users"
			ON public.bingo_session_reactions
			FOR SELECT TO authenticated
			USING (true);
	END IF;
END $$;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM pg_policies
		WHERE schemaname = 'public'
			AND tablename = 'bingo_session_reactions'
			AND policyname = 'Enable insert for users based on user_id'
	) THEN
		CREATE POLICY "Enable insert for users based on user_id"
			ON public.bingo_session_reactions
			FOR INSERT TO authenticated
			WITH CHECK ((SELECT auth.uid()) = user_id);
	END IF;
END $$;
