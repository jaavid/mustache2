# Mustache2 — Godot development build

Model and touch suites validated with Godot **4.7.2 stable**. Web export built with matching 4.7.2 templates; browser boot verified locally.
See [WEB_OPTIMIZATION.md](WEB_OPTIMIZATION.md) for upgrade, compression and custom-template steps.

 GDScript, Compatibility renderer; single-threaded web export.
This is a separate local development version in `godot/`. The existing Canvas
release, deployment workflow, bot, backend, records and wallet are not modified.

## Preserved mechanics

- Original six-room house, 13 furniture obstacles, nine hiding spots and exact world coordinates.
- Three-minute rounds; 218 movement / 295 sprint speed, original NPC speeds.
- Ramin favors reachable table/sofa cover; Borhan follows collision-checked flank
  routes and seeks cover after a sustained chase; Mammad plants fake clues lasting
  eight seconds, at most two concurrently, away from real hidden characters.
- E investigates the nearest clue/hider; proximity also reveals characters. A fake
  clue is dismissed without points. Capturing Mammad removes his remaining clues.
- NPCs must physically arrive at safe cover before hiding again. A tangential
  flank waypoint is deliberately not treated as a hiding spot.
- Original upper-lip ellipse (17×12), per-character lip calibration, projectile
  speed/TTL/cooldown, body misses, capture points and victory time bonus.
- Pause/resume, focus-loss pause, replay, accuracy, local best, mute and touch controls.

## Persian interface and original identity

The original menu, instructions, round messages and character status text are reused
from the Canvas client. Noto Sans Arabic uses its real variable `wght` axis across
100–900 (numeric OpenType tag), with separate title/name/button/body weights.
The HTML loading page declares the same full weight range without synthetic bold.
Labels use Persian shaping/language, RTL layout, Persian numerals and LTR-isolated
keyboard shortcuts/timer fields. Character cards restore the original face crops,
names and non-color-only status marks; compact phone cards retain all three photos.

## Maintainable modules and touch controls

See [ARCHITECTURE.md](ARCHITECTURE.md) for ownership, signal flow, extension points
and input invariants. `main.gd` composes the round model, device input, HUD, renderer,
audio, preferences and browser adapter. It no longer contains UI construction or
simulation logic. Character art and Persian copy have shared definitions.

Mobile/compact layouts use the original-style analogue joystick rather than four
direction buttons. It owns one finger, keeps partial-speed movement, and allows a
second finger to fire/search. Release, cancellation, pause, focus loss, rotation
and replay all return it to neutral. Non-touch desktop movement stays on WASD/arrows.

## Visible improvements

Original map rendered with room-specific floors, rugs, furniture silhouettes,
plants, window light, readable Persian room/character labels, depth sorting of
characters and furniture, projectile trails and impact particles. Camera follows
the player; a mini-map shows the house, player and exposed characters only.
Responsive portrait/landscape layouts avoid shrinking the entire world into a
letterboxed thumbnail. Motion reduction disables decorative bounce/pulses/impact
particles. Status uses text and symbols, not color alone. Keyboard menus have
visible focus, with Space auto-aim matching the original mobile fire action.

The default Godot boot image is disabled. `shell.html` supplies the Mustache
loading identity, actual engine-download progress and error/retry UI. There is no
artificial loading timer. Initial uncompressed engine payload is about 38 MB;
production delivery still needs compression and real-device performance checks.

## Telegram boundary

The web build copies the existing `../telegram-game.js` unchanged. GDScript forwards
round start/results through the shell adapter; ranking/share controls use that
same bridge. **Localhost always disables remote score requests, even with a session
query parameter.** No live Telegram score submission has been tested or deployed.
An authenticated staging test is required before replacing the live client. Scores
remain casual-only. No tokens, rewards or wallet features are added.

## Build and test

Open `project.godot` with Godot 4.5.2. Copy `web_nothreads_release.zip` and
`web_nothreads_debug.zip` from its official export-template archive into `.tools/`.
The engine/cache/templates and generated `web/` files are excluded from Git.

```sh
GODOT=/absolute/path/to/Godot ./build-web.sh
python3 -m http.server 5174 --bind 127.0.0.1 --directory web
```

Open http://127.0.0.1:5174 (WebAssembly + WebGL 2). No SharedArrayBuffer or cross-origin
isolation headers are needed. `build-web.sh` imports, runs `smoke_test.gd`, exports,
and copies the original Telegram bridge and local web font/license.

The model regression script checks all 81 pairs of hideouts plus collision-free route
segments, cover/flank/decoy policies, lip impacts/scoring, wall misses, pause,
timeout, replay and disabled default splash. The separate touch suite checks concurrent movement/fire, cancellation and reset
paths through real viewport events. Browser layout testing is separate.

For code style, create/activate a local Python virtual environment, install
`requirements-dev.txt`, and run `./check-code.sh` (gdformat + gdlint). Run
`GODOT=/path/to/Godot ./test.sh` for both behavior suites without exporting.

## Remaining limits

The character artwork still consists of the original four-frame cutouts: no new
directional walk/run sprites have been commissioned. Lighting is stylized drawing,
not a physically simulated lighting system. Live Telegram and iOS/Android WebViews
need staging/device verification. Current local best is stored in Godot browser
storage, separate from the original client's localStorage best; no score migration
is attempted. This development build is not a claim of full release readiness.

## Asset provenance

Character sheets are copied unchanged from `../assets/` and retain their original
rights (see `../ASSETS.md`). Noto Sans Arabic is SIL OFL 1.1 (`assets/OFL.txt`, also
copied to the web build). The environment and inline loading emblem are drawn in
code; no external asset packs or new commercial assets are bundled. Godot is MIT
licensed: https://godotengine.org/license/.

## GitHub Pages preview

The Pages workflow builds the pinned 4.7.2 engine/template pair and runs both
Godot regression suites before assembling a single artifact. The existing Canvas
client stays at `/mustache2/`; the development preview is at `/mustache2/godot/`.
The preview ignores Telegram session parameters and disables remote scoring and
ranking, so testing cannot submit scores to the production backend. Bot URLs
and registration are unchanged. A failing preview build blocks the new deployment;
the previously deployed Pages site stays available.
