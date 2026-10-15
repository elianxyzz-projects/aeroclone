# AeroV4 Lite — 10-module BedWars build

A pared-down module view using the **original AeroV4 GUI** and each retained module's **original settings and callbacks**. This repository contains an allowlist loader, **not copies of AeroV4's source or assets**. On launch it retrieves upstream source files from a pinned snapshot of [wrealaero/aerov4](https://github.com/wrealaero/aerov4).

## Quick start

**Execute this only in a Roblox environment and executor you trust, after reviewing the source.**

~~~lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/elianxyzz-projects/aeroclone/main/loader.lua', true))()
~~~

Source: [loader.lua](./loader.lua) — the script the loadstring fetches.

## Included modules (all 10)

| Module | AeroV4 UI tab | Original options retained |
|---|---|---|
| AimAssist (AA) | Combat | Yes |
| ProjectileAimbot (PA) | Blatant | Yes |
| HitFix | Legit | Original toggle |
| HitBoxes (hotboxes/hitboxes) | Combat | Yes |
| ESP (regular player boxes) | Render | Yes — choose Mode → 2D and Bounding Box |
| BedPlates | Minigames | Yes |
| KitESP | Kits | Yes |
| KitRender | Utility | Yes |
| NameTags | Render | Yes |
| **FPSBoost (FPS booster)** | **World** | **Yes** |

**Note:** The upstream module is called FPSBoost, not FPSBOOSTER. Keeping the original names protects module-option/profile compatibility. The original Friends, Targets, Favorites, Profiles and configuration controls are retained. Unused optional tabs are hidden.

## How the loader works

1. Runs in Roblox BedWars only (GameId 2619619496). Match-specific modules may not register until you enter a match.
2. Fetches the original AeroV4 main UI, main loader, universal modules and the appropriate BedWars-specific file from pinned upstream commit b723802d331778a362bfbd475fc2fb6f831c3fc1 (October 14, 2026).
3. Inserts the 10-module allowlist into local cached upstream main code. The original modules register and unwanted modules are removed **before** loading saved profile module settings. Retained module settings and callbacks are not reimplemented.
4. Retains the upstream Potassium-specific teleport delay and redirects the upstream teleport reload path to this repository's loader.

This script modifies the executor's **aerov4/** file cache. Back up original profiles before mixing it with an unmodified AeroV4 installation, and don't run both in the same game session.

## Potassium and Real

This loader uses common executor functions (getgenv, readfile, writefile, isfile, makefolder, loadstring, game:HttpGet) and checks for missing filesystem functions before writing its cache. HitFix needs constant/upvalue debug APIs (debug.getconstant, debug.setconstant, debug.setupvalue); the script warns if they are missing. Other features may have additional executor-specific dependencies.

**Not verified end to end:** no tests have been run in a live Roblox BedWars client using Potassium or Real. Local compile/mocked-module tests do not guarantee that all game-specific features function on every executor or future client update.

## Testing and troubleshooting

- Check that the raw loader URL returns Lua text, not a 404.
- Open BedWars, not a different Roblox game.
- Test match-only modules inside a match; some are absent from the lobby.
- Use Render → ESP → Mode → 2D and enable Bounding Box to show regular ESP boxes.
- For HitFix problems, look for executor-console warnings about debug APIs.
- If you have an old full-client profile, test a new profile rather than deleting your original files.

## Attribution / permissions

Upstream: [wrealaero/aerov4](https://github.com/wrealaero/aerov4). Its public repository has no declared license as inspected. Public visibility and noncommercial use do not automatically establish redistribution permission. This project hosts only a loader and fetches original source from upstream; it does not copy their original Lua sources or GUI images into this repository.
