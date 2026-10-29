#!/bin/sh
set -eu
cd "$(dirname "$0")"
: "${GODOT:?Set GODOT to the Godot executable path (4.7.2 recommended; see WEB_OPTIMIZATION.md)}"
engine_version=$("$GODOT" --version)
case "$engine_version" in
  4.7.2.stable.*) ;;
  *) echo "Expected Godot 4.7.2 stable, got: $engine_version" >&2; exit 1 ;;
esac
# Custom templates must be explicitly marked to avoid mixing 4.5 and 4.7 binaries.
if [ ! -f .tools/template-version.txt ] || [ "$(cat .tools/template-version.txt)" != "4.7.2" ]; then
  echo "Install matching templates; see WEB_OPTIMIZATION.md. Old templates are not safe." >&2
  exit 1
fi
mkdir -p web
build_log=$(mktemp)
trap 'rm -f "$build_log"' EXIT HUP INT TERM
"$GODOT" --headless --log-file "$build_log" --path . --editor --import --quit
./test.sh
"$GODOT" --headless --log-file "$build_log" --path . --export-release Web web/index.html

cp assets/NotoSansArabic.ttf web/NotoSansArabic.ttf
cp assets/OFL.txt web/OFL.txt
cp ../telegram-game.js web/telegram-game.js

cp assets/ramin.png assets/borhan.png assets/mammad.png web/

python3 tools/compress-web.py web
