#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/OneLife/server"
[[ -d "$SERVER_DIR" ]] || { echo 'ERROR: 2HOL server files are not present yet.' >&2; exit 1; }
BACKUP_DIR="$ROOT/world-backups"
mkdir -p "$BACKUP_DIR"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/2hol-world-$STAMP.tar.gz"
echo 'Note: the safest backup is made with the game server stopped.'
tar -czf "$ARCHIVE" -C "$SERVER_DIR" .
echo "Created $ARCHIVE"
echo 'Download this archive from the Codespaces file explorer to keep a copy outside the Codespace.'
