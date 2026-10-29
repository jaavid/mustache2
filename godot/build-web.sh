#!/bin/sh
set -eu
cd "$(dirname "$0")"
: "${GODOT:?Set GODOT to the Godot 4.5.2 executable path}"
mkdir -p web
"$GODOT" --headless --path . --editor --import --quit
./test.sh
"$GODOT" --headless --path . --export-release Web web/index.html

cp assets/NotoSansArabic.ttf web/NotoSansArabic.ttf
cp assets/OFL.txt web/OFL.txt
cp ../telegram-game.js web/telegram-game.js

cp assets/ramin.png assets/borhan.png assets/mammad.png web/
