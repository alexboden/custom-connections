-- Migration 004: RLS policies
-- Safe to re-run (drops before creating).

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are publicly readable" ON profiles;
CREATE POLICY "Profiles are publicly readable"
  ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Puzzles
ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Puzzles are publicly readable" ON puzzles;
CREATE POLICY "Puzzles are publicly readable"
  ON puzzles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create puzzles" ON puzzles;
CREATE POLICY "Authenticated users can create puzzles"
  ON puzzles FOR INSERT WITH CHECK (
    auth.uid() = creator_id
    AND (SELECT COUNT(*) FROM puzzles WHERE creator_id = auth.uid()
         AND created_at > now() - interval '1 day') < 20
  );

-- Votes
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

-- Plays
ALTER TABLE plays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can record a play" ON plays;
CREATE POLICY "Anyone can record a play"
  ON plays FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can read their own plays" ON plays;
CREATE POLICY "Users can read their own plays"
  ON plays FOR SELECT USING (auth.uid() = user_id);
