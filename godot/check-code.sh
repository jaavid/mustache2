#!/bin/sh
set -eu
cd "$(dirname "$0")"
gdformat --check main.gd scripts/*.gd smoke_test.gd tests/*.gd
gdlint main.gd scripts/*.gd smoke_test.gd tests/*.gd
