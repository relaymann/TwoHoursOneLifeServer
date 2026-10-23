#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/OneLife/server"

# Check both the binary and source identity so a prior standard-OHOL build
# cannot be launched accidentally.
valid_sources=true
for pair in \
    "OneLife|https://github.com/twohoursonelife/OneLife.git" \
    "OneLifeData7|https://github.com/twohoursonelife/OneLifeData7.git" \
    "minorGems|https://github.com/twohoursonelife/minorGems.git"; do
    dir="${pair%%|*}"
    expected="${pair#*|}"
    if [[ ! -d "$ROOT/$dir/.git" ]]; then
        valid_sources=false
        break
    fi
    origin="$(git -C "$ROOT/$dir" remote get-url origin 2>/dev/null || true)"
    if [[ "$origin" != "$expected" && "$origin" != "git@github.com:${expected#https://github.com/}" ]]; then
        valid_sources=false
        break
    fi
done

code_tag=""
if [[ -d "$ROOT/OneLife/.git" ]]; then
    code_tag="$(git -C "$ROOT/OneLife" describe --tags --exact-match HEAD 2>/dev/null || true)"
fi

if [[ "$valid_sources" != true || "$code_tag" != 2HOL_v* || ! -x "$SERVER_DIR/OneLifeServer" || ! -s "$SERVER_DIR/serverCodeVersionNumber.txt" ]]; then
    echo 'A correct 2HOL release build was not found. Running the 2HOL setup/build first...'
    bash "$ROOT/scripts/setup-2hol.sh"
fi

[[ -x "$SERVER_DIR/OneLifeServer" ]] || { echo 'ERROR: server executable still missing after setup.' >&2; exit 1; }
printf '0\n' > "$SERVER_DIR/settings/requireTicketServerCheck.ini"
printf '8005\n' > "$SERVER_DIR/settings/port.ini"
cd "$SERVER_DIR"
echo "Starting Two Hours One Life server (release $code_tag) on TCP port 8005."
echo 'Keep this terminal open. Press Ctrl+C to stop the server.'
exec ./OneLifeServer
