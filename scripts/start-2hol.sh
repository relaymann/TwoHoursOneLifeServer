#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/OneLife/server"

if [[ ! -x "$SERVER_DIR/OneLifeServer" || ! -s "$SERVER_DIR/serverCodeVersionNumber.txt" ]]; then
    echo '2HOL server is not built yet (or its version file is missing). Running setup/build first...'
    bash "$ROOT/scripts/setup-2hol.sh"
fi

[[ -x "$SERVER_DIR/OneLifeServer" ]] || { echo 'ERROR: server executable still missing after setup.' >&2; exit 1; }
printf '0\n' > "$SERVER_DIR/settings/requireTicketServerCheck.ini"
printf '8005\n' > "$SERVER_DIR/settings/port.ini"
cd "$SERVER_DIR"
echo 'Starting the Two Hours One Life server on TCP port 8005.'
echo 'Keep this terminal open. Press Ctrl+C to stop the server.'
exec ./OneLifeServer
