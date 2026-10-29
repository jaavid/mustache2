# Mustache2 — Hide & Seek

A free-to-play, two-dimensional hide-and-chase game featuring **Ramin, Borhan, and Mammad** from [Mustache](https://github.com/jaavid/Mustache). **Mustache2** is a separate 2D sequel; **Mustache3** is reserved for a future 3D game.

## Play

This repository is a static HTML5 game: open `index.html` with a local static server, or deploy the root directory with GitHub Pages.

- **WASD / arrow keys**: move around the six-room farmhouse; hold **Shift** to sprint.
- **Mouse**: aim the mustache launcher; **click** or **Space** to shoot.
- **E**: investigate a suspicious hiding spot nearby.
- **P / Escape**: pause.
- **Mobile**: virtual movement pad and tap-to-shoot.
- Find all three characters before 3 minutes expire. Once spotted, they flee and can hide again. A mustache must actually hit the **upper lip** to catch a character.

### Independent NPC personalities

- **Ramin — cover seeker:** starts near a table, favors safe table/sofa edges, and hides again only once he has physically reached cover and the player is far enough away.
- **Borhan — flanker:** circles around the hunter using tangential waypoints and recalculates routes around walls/furniture; after a sufficiently long chase he can escape into hiding.
- **Mammad — noise trickster:** while uncaught, periodically plants a short-lived fake sound clue in a different nearby location. The room hint and pulsing `تق!` mark lure you to a false hiding spot. Inspect it with **E** or the mobile search button to dismiss it. It never counts as a capture or alters scoring.

Behavior selection is collision-aware and uses the existing grid-based navigation, including fallback when a flank is blocked. The policies are in `lib/npc-ai.mjs` and have deterministic regression tests in `tests/npc-ai.test.mjs`. No extra network calls or Telegram permissions are needed.

## Technical approach

Zero runtime dependencies. HTML/CSS and Canvas 2D, procedural room/furniture drawing (including a dedicated scenery module), 2D collision and grid-based pursuit/evasion, simulated mustache projectiles, original character PNG sprite sheets, Web Audio SFX. The new UI ships with a locally hosted **Noto Sans Arabic variable font (SIL OFL 1.1)** and accessible status indicators. Works offline when served with local assets. Deliberately separate from the original Phaser/Telegram/wallet stack.

The three character images are copied unchanged from the owner's original Mustache repository; their copyright status is **not** claimed to be CC0. The new source code in this repository is MIT licensed; original Mustache character artwork remains governed by its original rights.

See [ASSETS.md](ASSETS.md) for CC0 options, font licensing, and provenance.

## Local development

```sh
python3 -m http.server 5173
# open http://localhost:5173
```

Run static checks with `npm test` (Node 22). No build step is needed.

## GitHub Pages

Settings → Pages → Deploy from a branch → `main` / `(root)`. Alternatively, the included workflow publishes after checks. No external backend, API keys, CDN or account is required.

## Scope and limitations

This is a playable **v0.2 single-level prototype**. It uses a stylized top-down house with upright 2D character cutouts rather than six-direction walking sprites. It is single-player and local: there is no Telegram leaderboard, online multiplayer or token reward. Pathfinding and hit detection remain intentionally lightweight for the browser and Telegram; NPC decision-making is personality-driven and can be tuned after playtesting.

## Official Telegram Games integration

Telegram Game Card: **https://t.me/RJTtobot?game=Mustache2** (same bot as Mustache1).
The standalone website stays playable without login; session-authenticated
Telegram players can submit casual scores to the existing Cloudflare Worker
at `https://mustache.zedai.ir/api/mustache2/`, view a separate top-ten board,
and share via Telegram's native Game proxy.

This requires the companion PR in `jaavid/Mustache` to be deployed first,
and one-time registration of the **Mustache2** game under @RJTtobot using
BotFather `/newgame`. Do not replace the existing **mustache** game or webhook.

**Unverified casual scores only.** No wallet rewards or tokens are issued.
