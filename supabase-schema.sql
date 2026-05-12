-- Four of a Kind — Supabase Schema
-- Safe to run multiple times (uses IF NOT EXISTS / CREATE OR REPLACE)

-- ============================================================
-- TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  display_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- Auto-create profile on sign-up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Profiles RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are publicly readable" ON profiles;
CREATE POLICY "Profiles are publicly readable"
  ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- ============================================================

CREATE TABLE IF NOT EXISTS puzzles (
  id text PRIMARY KEY,
  data text NOT NULL,
  creator_id uuid REFERENCES auth.users(id),
  play_count int DEFAULT 0,
  completion_count int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS votes (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  puzzle_id text REFERENCES puzzles(id) ON DELETE CASCADE,
  value smallint NOT NULL DEFAULT 1 CHECK (value IN (-1, 1)),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, puzzle_id)
);

CREATE TABLE IF NOT EXISTS plays (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_id text REFERENCES puzzles(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  won boolean NOT NULL,
  mistakes int NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_puzzles_creator ON puzzles(creator_id);
CREATE INDEX IF NOT EXISTS idx_puzzles_created_at ON puzzles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_plays_user ON plays(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plays_puzzle ON plays(puzzle_id);

-- ============================================================
-- VIEWS
-- ============================================================

CREATE OR REPLACE VIEW puzzle_stats AS
SELECT
  p.id,
  p.data,
  p.creator_id,
  p.play_count,
  p.completion_count,
  p.created_at,
  COALESCE(v.vote_count, 0) AS vote_count,
  COALESCE(v.upvotes, 0) AS upvotes,
  COALESCE(v.downvotes, 0) AS downvotes,
  CASE WHEN p.play_count > 0
    THEN ROUND(p.completion_count::numeric / p.play_count * 100, 1)
    ELSE 0
  END AS completion_pct
FROM puzzles p
LEFT JOIN (
  SELECT puzzle_id,
    SUM(value)::int AS vote_count,
    COUNT(*) FILTER (WHERE value = 1)::int AS upvotes,
    COUNT(*) FILTER (WHERE value = -1)::int AS downvotes
  FROM votes
  GROUP BY puzzle_id
) v ON v.puzzle_id = p.id;

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Puzzles are publicly readable" ON puzzles;
CREATE POLICY "Puzzles are publicly readable"
  ON puzzles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create puzzles (max 20/day)" ON puzzles;
CREATE POLICY "Authenticated users can create puzzles (max 20/day)"
  ON puzzles FOR INSERT WITH CHECK (
    auth.uid() = creator_id
    AND (SELECT count(*) FROM puzzles WHERE creator_id = auth.uid()
         AND created_at > now() - interval '1 day') < 20
  );

ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Votes are publicly readable" ON votes;
CREATE POLICY "Votes are publicly readable"
  ON votes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert their own votes" ON votes;
CREATE POLICY "Users can insert their own votes"
  ON votes FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own votes" ON votes;
CREATE POLICY "Users can update their own votes"
  ON votes FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own votes" ON votes;
CREATE POLICY "Users can delete their own votes"
  ON votes FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE plays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can record a play" ON plays;
CREATE POLICY "Anyone can record a play"
  ON plays FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can read their own plays" ON plays;
CREATE POLICY "Users can read their own plays"
  ON plays FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION record_play(p_puzzle_id text, p_won boolean, p_mistakes int)
RETURNS void AS $$
BEGIN
  UPDATE puzzles
  SET play_count = play_count + 1,
      completion_count = completion_count + CASE WHEN p_won THEN 1 ELSE 0 END
  WHERE id = p_puzzle_id;

  INSERT INTO plays(puzzle_id, user_id, won, mistakes)
  VALUES (p_puzzle_id, auth.uid(), p_won, p_mistakes);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
