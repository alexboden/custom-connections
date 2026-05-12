-- Migration 003: Views and functions
-- Safe to re-run (drops and recreates).

DROP VIEW IF EXISTS puzzle_stats;
CREATE VIEW puzzle_stats AS
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

-- Atomically record a play and update counters
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
