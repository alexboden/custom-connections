-- Migration 004: Add upvote/downvote support
-- Run this if your database was set up before the Reddit-style voting change.
-- Adds a `value` column (-1 or 1) to votes. Existing votes become upvotes.

ALTER TABLE votes ADD COLUMN IF NOT EXISTS value smallint NOT NULL DEFAULT 1 CHECK (value IN (-1, 1));
