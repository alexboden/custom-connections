-- Migration 001: Initial schema
-- Run this on a fresh Supabase project to set up everything from scratch.
-- Skip if your database already has these tables.

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS puzzles (
  id text PRIMARY KEY,
  data text NOT NULL,
  creator_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_puzzles_creator ON puzzles(creator_id);
CREATE INDEX IF NOT EXISTS idx_puzzles_created_at ON puzzles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_plays_user ON plays(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plays_puzzle ON plays(puzzle_id);
