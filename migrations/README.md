# Database Migrations

Numbered SQL files to run in order in the Supabase SQL Editor.

## Fresh setup

Run all files in order: `001`, `002`, `003`, `004`.

## Existing database

Only run new migrations you haven't applied yet. Check what's already in your DB and start from the first migration you're missing.

## Rules

- Each file is one statement batch — paste the entire file into the SQL Editor and run it.
- Files are idempotent where possible (`IF NOT EXISTS`, `CREATE OR REPLACE`, `DROP IF EXISTS` before `CREATE`).
- New migrations get the next number: `005_description.sql`.
