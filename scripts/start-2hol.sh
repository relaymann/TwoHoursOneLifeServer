#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT/OneLife/server"

has_expected_origins() {
    local pair dir expected origin
    for pair in \
        "OneLife|https://github.com/twohoursonelife/OneLife.git" \
        "OneLifeData7|https://github.com/twohoursonelife/OneLifeData7.git" \
        "minorGems|https://github.com/twohoursonelife/minorGems.git"; do
        dir="${pair%%|*}"
        expected="${pair#*|}"
        [[ -d "$ROOT/$dir/.git" ]] || return 1
        origin="$(git -C "$ROOT/$dir" remote get-url origin 2>/dev/null || true)"
        [[ "$origin" == "$expected" || "$origin" == "git@github.com:${expected#https://github.com/}" ]] || return 1
    done
}

# Do not use git describe --exact-match: the same commit may have multiple tags,
# so Git can print an alias such as OneLife_v... instead of the 2HOL_v... tag.
# Compare each HEAD to the commit named by the shared 2HOL tag instead.
matching_2hol_build() {
    local tag dir head_sha tag_sha expected_version written_version
    has_expected_origins || return 1
    tag="$(git -C "$ROOT/OneLife" tag --list '2HOL_v*' --sort=-version:refname | head -n 1)"
    [[ "$tag" == 2HOL_v* ]] || return 1

    for dir in OneLife OneLifeData7 minorGems; do
        tag_sha="$(git -C "$ROOT/$dir" rev-parse --verify "refs/tags/$tag^{commit}" 2>/dev/null)" || return 1
        head_sha="$(git -C "$ROOT/$dir" rev-parse HEAD 2>/dev/null)" || return 1
        [[ "$head_sha" == "$tag_sha" ]] || return 1
    done

    [[ -x "$SERVER_DIR/OneLifeServer" && -s "$SERVER_DIR/serverCodeVersionNumber.txt" ]] || return 1
    expected_version="${tag#2HOL_v}"
    written_version="$(tr -d '[:space:]' < "$SERVER_DIR/serverCodeVersionNumber.txt")"
    [[ "$written_version" == "$expected_version" ]] || return 1
}

if ! matching_2hol_build; then
    echo 'A matching 2HOL release build was not found. Running the 2HOL setup/build first...'
    bash "$ROOT/scripts/setup-2hol.sh"
fi

if ! matching_2hol_build; then
    echo 'ERROR: 2HOL build validation failed after setup. Please send the last 40 lines of output.' >&2
    exit 1
fi

release_tag="$(git -C "$ROOT/OneLife" tag --list '2HOL_v*' --sort=-version:refname | head -n 1)"
printf '0\n' > "$SERVER_DIR/settings/requireTicketServerCheck.ini"
printf '8005\n' > "$SERVER_DIR/settings/port.ini"
cd "$SERVER_DIR"
echo "Starting Two Hours One Life server (release $release_tag) on TCP port 8005."
echo 'Keep this terminal open. Press Ctrl+C to stop the server.'
exec ./OneLifeServer
