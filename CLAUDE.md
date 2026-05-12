# Four of a Kind

A custom Connections puzzle game where users create and share word-grouping puzzles.

## Stack

- **Frontend:** Vanilla HTML/CSS/JS (no framework, no build step)
- **Backend:** Supabase (Postgres + Auth + RLS)
- **Hosting:** Cloudflare Pages (static)
- **Auth:** Email/password via Supabase Auth

## Project Structure

```
index.html          — Main app (create + play puzzles)
browse.html         — Leaderboard / discover puzzles
profile.html        — User profile (stats, created puzzles)
js/
  supabase-config.js — Supabase client init (URL + anon key)
  auth.js            — Auth modal, session management
  nanoid.js          — 8-char ID generation
supabase-schema.sql — Full schema reference (may drift, migrations are source of truth)
migrations/         — Numbered SQL files to run in order in Supabase SQL Editor
og-image.png        — Social share preview
```

## Key Concepts

- **Puzzle storage:** Puzzles are serialized as `cat1~w1~w2~w3~w4|cat2~...` and stored in the `puzzles` table
- **Short links:** DB-backed puzzles use `?p=<nanoid>` query params
- **Legacy links:** Old hash-based URLs (`#compressed-data`) still work
- **RLS:** All security is enforced via Postgres Row Level Security policies
- **Play tracking:** `record_play` is a SECURITY DEFINER function that atomically updates counters

## Supabase

- Project URL and anon key are in `js/supabase-config.js`
- Schema lives in `supabase-schema.sql` — run in SQL Editor to apply
- Tables: `profiles`, `puzzles`, `votes`, `plays`
- View: `puzzle_stats` (joins puzzles with vote counts and completion %)

## Development

Open `index.html` directly in a browser or serve with any static server. No build step needed. Changes to JS/HTML deploy automatically via Cloudflare Pages on push to main.

## Conventions

- No frameworks or build tools — keep it vanilla
- Single responsibility per HTML page (not SPA)
- Shared JS loaded via `<script>` tags
- Supabase client accessed as `supabaseClient` global
- Auth state in `currentUser` global
