# Mustache2 Godot architecture

The Godot client is a growing game, not a one-file demo. The entry scene composes
modules; gameplay can run without nodes, device events, UI, audio, storage or HTTP.
The Canvas release is independent and remains the reference for current mechanics.

## Ownership and interfaces

| Module | Owns | Interface used by callers |
| --- | --- | --- |
| `main.gd` | Module construction, signal connections, camera coordinates | Scene lifecycle; does not implement scoring, touch gestures or widgets |
| `scripts/round_model.gd` | One round's state, actions, timer, captures and score | `reset`, `step(dt, movement, sprint)`, `inspect`, `fire`, `fire_auto`, `toggle_pause`; emits round lifecycle and sound cues |
| `scripts/navigation.gd` | Obstacle clearance, sliding, AStar routes, cover/flank/noise selection | Geometry/policy queries; no scene nodes or presentation |
| `scripts/game_input.gd` | Keyboard, mouse and unhandled world taps | Bounded movement vector and intent signals |
| `scripts/virtual_joystick.gd` | One movement finger, analogue value and stick drawing | `value`, `movement_changed`, `reset`; consumes only its own touch stream |
| `scripts/game_hud.gd` | Persian widgets, menus, touch action hit regions | `present(round, preferences)`, `resize_layout`, `release_touch`; emits intents without changing round state |
| `scripts/house_view.gd` | World rendering and depth ordering | Reads round state, camera offset and motion preference |
| `scripts/preferences.gd` | Local best, mute and motion storage | Preference toggles and `record_score` |
| `scripts/game_audio.gd` | Sound generation and playback | `play_tone`, `muted`; receives model cues |
| `scripts/web_platform.gd` | Optional browser/Telegram adapter | Round start/results; preserves the existing JS/backend contract |
| `scripts/game_text.gd` | Shared names, original menu copy, phase copy and Persian numbers | Text helpers, independent of font rendering |
| `scripts/typography.gd` | Real variable-font weights and Persian label shaping | `font(weight)`, `rtl(label, weight)` |
| `scripts/character_art.gd` | Character sheets, portrait crops and avatar colors | Shared visual definitions; not imported by gameplay |
| `scripts/house.gd` | Original world geometry and hideouts | Data only |

The round model owns mutable actor/projectile/clue collections. Views read them;
only the model and navigation policies update gameplay. Actor dictionaries are an
internal representation, not an external serialization contract. Round results
are separate dictionaries with an explicit backend payload in the web adapter.

## Data flow

```text
keyboard / mouse / world touch -> GameInput ---+
                                             |
HUD buttons / touch action regions ----------+-> main connections -> RoundModel
                                             |                         |
VirtualJoystick -> bounded movement -> GameInput.movement()             |
                                                                       |
                                  HUD + HouseView <--- read round state-+
                                  Audio           <--- sound cue signal
                                  Preferences     <--- completed round
                                  WebPlatform     <--- lifecycle/result
```

A model sound cue cannot alter score; failed/absent browser services cannot gate a
round. Localhost remote scoring stays disabled in the existing HTML/JS adapter.

## Touch invariants

- The fixed-origin joystick matches the old client's 42-pixel logical travel.
  Partial travel retains partial speed; diagonal/full travel is bounded to one.
- One finger owns movement until release or cancellation, including outside the
  pad. A second finger can fire or investigate without stealing the first finger.
- Synthetic mouse events from touch drivers are excluded from gameplay/button
  activation to avoid processing the same touch twice.
- HUD actions consume their touch events so a button tap never also becomes a
  world shot. Movement touches likewise never become shots.
- Releasing, cancellation, pause, focus loss, replay and resize clear the stick.
- Input coordinates stay in Godot viewport space; only the composition root
  converts screen aiming into world coordinates using the camera offset.
- Touch/compact layouts show the stick. Wider non-touch desktops retain keyboard
  movement and show the keyboard legend. Mouse dragging the stick is supported for
  local preview; real iOS/Android WebView checks are still needed before release.

## Extending the game

- Add mechanics and score changes in the round model, with behavior tests through
  its public interface. Do not put a new scoring branch in a widget or renderer.
- Add device controls in GameInput or the relevant touch control. Translate them
  into existing intents rather than duplicating the simulation for mobile.
- Change character images/crops in CharacterArt; names and user-facing phase copy
  in GameText. The three-character game rule and corresponding NPC policy remain
  explicit; adding another playable target requires model/policy/test changes.
- Add levels through map data and navigation, then verify routes/clearance. Do not
  duplicate map dimensions inside HUD components.
- Keep external integrations in adapters. Never place Telegram identities, HTTP,
  filesystem calls or wallet logic in the round model.
- Prefer a new module when behavior has a distinct owner and useful small
  interface. Do not make a file for every helper, or add a generic plugin/ECS
  framework for features the game does not have.

## Checks

`requirements-dev.txt` pins gdtoolkit. After installing it in an activated local
virtual environment, `./check-code.sh` checks formatting and lint without edits.
`GODOT=/path/to/Godot ./test.sh` runs the model and touch integration suites.
`build-web.sh` imports resources, runs those same suites, then exports the browser
build. A frame watchdog plus a required completion summary prevents a script
failure from silently passing a suite.

The model suite checks all hideout routes and gameplay outcomes. The input suite
pushes actual multi-finger viewport events through the same scene used in play,
including concurrent movement/fire and all reset paths. Browser checks validate
layout and runtime behavior separately. Screenshots are review artifacts, not
pixel-diff assertions.
