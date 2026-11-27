#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
godot="${GODOT_BIN:-godot}"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export UMBRAL_TEST_DIR="$tmp"

# El editor importa texturas y audio antes de ejecutar GDScript por CLI.
if ! "$godot" --headless --path "$root" --editor --import --log-file "$tmp/import.log" > "$tmp/import.out" 2>&1; then
  cat "$tmp/import.out"
  exit 1
fi
if grep -E 'SCRIPT ERROR|Parse Error' "$tmp/import.out"; then
  exit 1
fi
"$godot" --headless --path "$root" --log-file "$tmp/godot.log" --script res://qa/godot/suite.gd
