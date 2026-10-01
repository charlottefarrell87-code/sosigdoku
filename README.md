# Sosigdoku

A daily sosig logic puzzle for competing with friends.

## Rules

- Place 9 sosigs on the 9x9 board.
- One dog in every coloured patch, every row and every column.
- Dogs can't touch, not even diagonally.
- Tap a square to mark it with ×, tap again to place a dog. Drag to mark several squares.
- A wrong dog leaves a red × and adds 30 seconds to your score. Lowest score wins.

## How it works

- A new hard puzzle is generated each day (UK time), seeded by the date, so everyone gets the same board.
- Every puzzle is checked to have exactly one solution.
- Missed days can be played from the puzzle picker.
- Leaderboards: Daily, This week (most daily wins) and Overall (most weekly wins).

## Players

- First visit: type your name and press **Join and start**. The site remembers you on that device.
- Each player gets an 8-character **player code** (shown under the leaderboard). Use it to sign in on another phone or computer.
- Names can be changed at any time with **Change name**.

## Leaderboard setup (Supabase, free)

1. Create a free project at [supabase.com](https://supabase.com).
2. Open **SQL Editor**, paste in everything from `supabase-setup.sql` and press **Run**.
3. Go to **Project Settings > API** (or **API Keys**) and copy the **Project URL** and the **publishable** (or **anon public**) key.
4. Paste them into the two lines at the top of the script in `index.html`:
   ```js
   const SUPABASE_URL = 'https://your-project.supabase.co';
   const SUPABASE_KEY = 'your-publishable-key';
   ```
5. Commit. GitHub Pages updates within a minute or two.

The publishable key is safe to have in the page: the database only allows reading names and scores, and every write goes through checked functions. Puzzle times are measured by the server.

Without these settings the puzzle still works, just without a shared leaderboard.
