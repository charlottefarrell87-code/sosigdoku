# Sosigdoku

A daily sausage-dog logic puzzle for competing with friends.

## Rules

- Place 9 sausage dogs on the 9x9 board.
- One dog in every coloured patch, every row and every column.
- Dogs can't touch, not even diagonally.
- Tap a square to mark it with ×, tap again to place a dog. Drag to mark several squares.
- A wrong dog leaves a red × and adds 30 seconds to your score. Lowest score wins.

## How it works

- A new hard puzzle is generated each day (UK time), seeded by the date, so everyone gets the same board.
- Every puzzle is checked to have exactly one solution.
- Missed days can be played from the puzzle picker.
- Leaderboards: Daily, This week (most daily wins) and Overall (most weekly wins).

## Note on the leaderboard

The leaderboard uses the Claude artifact runtime (`window.claude`) for shared storage, so scores only save when the page runs as a Claude artifact. Opened anywhere else, the puzzle is fully playable but scores aren't shared.
