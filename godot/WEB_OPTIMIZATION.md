# Mobile web optimization and engine upgrade

Verified on 2026-10-29: latest stable is 4.7.2; 4.8 is beta.
Model and touch suites pass with installed 4.7.2 (2669 model checks and 17 touch checks).
A joystick script alias was renamed to avoid the new native VirtualJoystick class.
Web export built with matching 4.7.2 templates and booted in a local browser.
Raw measured files: 41,547,711 bytes; gzip: 11,465,235 bytes.
Only missing favicon was reported by browser console. Real-device Telegram tests
and custom stripped-template compilation remain pending.

## Install for upgrade

Install Godot 4.7.2 Standard for macOS (not .NET) and its matching Standard
export templates from https://godotengine.org/download/archive/4.7.2-stable/ .
Extract the matching web_nothreads_release.zip and web_nothreads_debug.zip
into godot/.tools/, replacing the old templates only when upgrading the engine.
After copying matching templates, write `4.7.2` into `.tools/template-version.txt`.
Do not mix engine and template versions. Then run:

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./build-web.sh
```

Check desktop, Android Telegram and iOS Telegram: cold load, Persian shaping,
movement plus fire, sound after user gesture, pause/resume, rotation, session
score submission and native score sharing. Headless tests cannot replace these.

## Delivery compression

The build creates deterministic .gz sidecars and web/size-report.json.
These files alone do not enable compression. Configure the host to negotiate
Accept-Encoding, serve the matching Content-Encoding: gzip, Vary: Accept-Encoding,
and the original Content-Type (application/wasm for WASM). Keep raw files as fallback.
Python's simple HTTP server does not negotiate sidecars. Verify actual response
headers and transferred bytes before claiming reduced production downloads.
Do not deploy both raw and gzip files as additional client downloads.

## Smaller engine

The standard template contains features this 2D game does not use. Candidate
SCons options are in tools/web-size.custom.py. Building a custom template needs
Godot source matching the editor, SCons and the Emscripten SDK version required
by that source. These tools are not installed by this project. Follow the target
version's compiling-for-web guide before installing a specific SDK.

From the matching Godot source checkout, use the candidate configuration with:

```sh
scons platform=web target=template_release threads=no optimize=size_extra lto=full debug_symbols=no disable_3d=yes
```

The candidate configuration has not been compiled or benchmarked. Save the
resulting release template as .tools/web_nothreads_release.zip, then rebuild
and repeat all regression and device checks. Keep the official template for
comparison. Preserve advanced text shaping for Persian. Do not blindly disable
GUI classes: the HUD must keep its controls. Use the editor's engine compilation
configuration tool to detect additional unused features, then review its results
against dynamically created GDScript controls.

References:
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/engine_details/development/compiling/optimizing_for_size.html
