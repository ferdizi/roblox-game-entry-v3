# Coin Rush — roblox-game-01 candidate

A 2D dodge-and-collect Roblox game. Move with the arrow keys or WASD, grab
coins, dodge the red blocks. Charge **4 vaults (30 coins in 150 seconds)**,
then beat **THE WARDEN** — dash through it 3 times — to win.
3 lives. Every 5 coins levels you up: enemies get faster and more numerous,
chasers appear from level 2, weavers from level 3, and rare star coins (+300)
show up every 12 s. Chain pickups for a **x5 COMBO** (a hit resets it).
Best score of the server is kept by the server script and shown on the menu.

## v3 (this copy)

v2 scored **93.64% provisional, rank 41/92** — up from v1's 89.03%, but still
outside the top 20 (cutoff 95.95%). The top of the leaderboard is full of
games with a real objective structure (vaults with quotas, a boss, a combo,
more enemy kinds). v3 closes those exact gaps, keeping the whole v2 core
(zones, dash, shield, bursts, shake, Play Time, best score, R restart):
**4 vaults** (Meadow 7 → Desert 8 → Neon 8 → Core 7; each vault has a quota
shown as "VAULT n - x/y TO PORTAL" and re-themes the arena), **COMBO x5**
(pickups chain the multiplier; a hit resets it; "+200 x2" floating popups),
**Weaver** (3rd enemy, purple, sweeps in a sine wave from level 3),
**THE WARDEN boss finale** (at 30 coins the field clears, the Warden spawns
with a 3-pip HP bar; dash through it 3 times to win; if it is not beaten in
30 s it retreats and the round is still a win, so the finale can never
soft-lock a win), **150 s round** (longer play, longer Play Time), plus a
richer menu (vault list, combo rule, boss name). Cut on purpose: no Endless
mode, no walls, no shooter enemy — all three would have touched the core
loop for little visible gain in the time left. New place + new screenshots
must be taken in Studio before the v3 submit.

## Files

| Path | What it is |
| --- | --- |
| `src/client/Game.client.luau` | Entrypoint: builds the UI, runs the round loop |
| `src/client/Config.luau` | All tuning numbers (arena, speeds, timer, palette) |
| `src/client/State.luau` | The whole round state, one place (menu/playing/won/lost) |
| `src/client/Ui.luau` | Every interface element: HUD, menu, win/lose screens |
| `src/client/Entities.luau` | Coins, stars, drifters, chasers, weavers, the Warden: spawn, move, collide |
| `src/client/Input.luau` | Arrow keys/WASD polling + Enter/R menu keys |
| `src/client/Sounds.luau` | Built-in sound effects, pcall-safe |
| `src/server/init.server.luau` | Server: keeps the server's best score (RemoteEvent) |
| `default.project.json` | Rojo project (builds `game.rbxl` from `src/`) |
| `game.rbxl` | The place, built with Rojo 7.5.1 (see `tools/`) |
| `main.ts` | The entry program: copies the game to `/output`, writes `dossier.json` |
| `vendor/makefun-roblox.ts` | Kit's library, unchanged (sha256 matches the kit) |
| `PLAY.json` | ⚠️ PLACEHOLDER (zeros) — see below |
| `screenshots/` | ⚠️ PLACEHOLDERS — see below |
| `tools/rojo` | Rojo 7.5.1 binary used to build the place — **do NOT put in the submit repo** |

## Validated here (Linux, no Studio)

- All 8 Luau files parse and compile with the official Luau 0.747 compiler
  (`luau-compile` OK on all 8), and `luau-analyze` reports no real errors
  (only "unknown global" for Roblox globals, which is expected off-Studio).
- `rojo build` → `game.rbxl`, **28,216 bytes** (cap 32 MiB), binary `<roblox!`
  header, sha256 `02bd2c68460833165b215cff66ec2b5990ec41727dd5b5ec2408e177829e2fba`.
- `main.ts` runs clean with placeholder screenshots: dossier **792,856 bytes**
  (cap 1.5 MiB), text **60,862 bytes** (cap 65,536), 4 images; two runs →
  byte-identical `dossier.json`. The outline names all v3 systems (VAULT,
  COMBO, WARDEN, weaver). **Screenshots/ is EMPTY right now — Gadiel must
  take 4 real ones in Studio before the submit (the gate refuses without them).**
- Winnability checked by math: 30 coins in 150 s (v2 was 20 in 75 s, same
  pace); fastest enemy in vault 4 is 244 px/s vs player 421 px/s at level 7;
  the Warden moves 70 px/s and the round is won even if it retreats after
  30 s, so the finale can never soft-lock a win.

## ⚠️ NOT SUBMITTABLE YET — Gadiel's Studio checklist

1. **Open the place.** Roblox Studio → sign in → open `game.rbxl`
   (File → Open from File). Do NOT run `rojo build` over a Studio-saved place.
2. **Play-test.** Press Play (F5): menu → START (or Enter) → move with arrows
   or WASD → collect coins → watch the COMBO badge climb and the vault
   objective count up → take a hit on purpose (combo resets) → reach 30
   coins → THE WARDEN spawns → dash through it 3 times to win (or wait 30 s
   for it to retreat) → R to restart. Also check lose (0 lives or timer out).
   Watch the Output window for errors. If a script errors, tell Muse the
   exact error line.
3. **Screenshots (4, while the game is RUNNING, not paused).**
   - `1-start.png` — the menu screen
   - `2-play.png` — mid-game, coins and enemies visible, COMBO badge showing
   - `3-boss.png` — the WARDEN boss fight, HP bar visible
   - `4-win.png` — the win screen ("WARDEN BEATEN!", Play Time on its own line)
   - 1280×720 each, ≤256 KiB each (save as JPEG quality ~85 if a PNG is too big).
   - Keep the HUD text clear of the screen's top-left corner (Roblox's own
     menu buttons sit there). Replace the placeholder files in `screenshots/`.
4. **Publish.** File → Publish to Roblox As… → name **Coin Rush**,
   description (no web addresses — Roblox refuses names/descriptions that
   read as URLs), genre, answer the content questions.
5. **Make it Public.** Creator Dashboard → the experience → set Public
   (after the age check, if Roblox asks).
6. **Get the IDs and fill `PLAY.json`:**
   - `place_id` — the number in the play link `roblox.com/games/<place_id>`
   - `universe_id` — the number after `experiences/` in the Creator
     Dashboard address, or `game.GameId` in Studio (`game.PlaceId` is the place)
   - Then tell Muse the two numbers (or paste the filled `PLAY.json`).
7. **Tell Muse.** Muse re-runs the validation, creates the GitHub repo,
   and submits. Deadline: **01:00 WIB Mon 16 Nov 2026**.

## What the submit repo holds

`main.ts`, `game.rbxl`, `src/`, `screenshots/`, `PLAY.json`,
`vendor/makefun-roblox.ts`, `default.project.json`, `LICENSE`, this README.
NOT `tools/` (15 MB Rojo binary) and NOT any `out/` validation folders.
