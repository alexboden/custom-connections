-- Add optional name column to puzzles (creator-chosen word used as display title)
ALTER TABLE puzzles ADD COLUMN IF NOT EXISTS name text;

-- Recreate view to include name (can't reorder columns with CREATE OR REPLACE)
DROP VIEW IF EXISTS puzzle_stats;
CREATE VIEW puzzle_stats AS
SELECT
  p.id,
  p.data,
  p.name,
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
