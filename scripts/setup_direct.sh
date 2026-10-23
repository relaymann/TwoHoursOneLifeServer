#!/usr/bin/env bash
# Backwards-compatible entry point for Linux/macOS users of this fork.
# This fork targets Two Hours One Life (2HOL), not the original OHOL repos.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT/scripts/setup-2hol.sh" "$@"
