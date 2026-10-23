#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# The Codespaces C++ image includes most build tools. Install the small
# server-side dependency set if the environment is missing it.
need_packages=0
for cmd in git make g++; do
    if ! command -v "$cmd" >/dev/null 2>&1; then need_packages=1; fi
done
if command -v dpkg-query >/dev/null 2>&1; then
    for pkg in build-essential libpng-dev zlib1g-dev; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
            need_packages=1
        fi
    done
fi
if (( need_packages )); then
    command -v apt-get >/dev/null 2>&1 || fail 'Missing build tools; this setup script expects an Ubuntu/Debian Codespace.'
    command -v sudo >/dev/null 2>&1 || fail 'Missing build tools and sudo is unavailable. Use a C++ Codespaces image.'
    echo 'Installing required Linux build packages...'
    sudo apt-get update
    sudo apt-get install -y git build-essential libpng-dev zlib1g-dev
fi

clone_or_validate() {
    local dir="$1" url="$2"
    if [[ -e "$ROOT/$dir" ]]; then
        [[ -d "$ROOT/$dir/.git" ]] || fail "$dir already exists but is not a Git checkout. Rename it before retrying; this script will not delete it."
        local origin
        origin="$(git -C "$ROOT/$dir" remote get-url origin 2>/dev/null || true)"
        case "$origin" in
            "https://github.com/twohoursonelife/${dir}.git"|"git@github.com:twohoursonelife/${dir}.git") ;;
            *) fail "$dir has unexpected origin '$origin'. This setup needs the official 2HOL repository; it will not overwrite the existing folder." ;;
        esac
    else
        echo "Cloning 2HOL $dir..."
        git clone "$url" "$ROOT/$dir"
    fi
    git -C "$ROOT/$dir" fetch --tags origin
}

latest_2hol_tag() {
    local dir="$1" tag
    tag="$(git -C "$ROOT/$dir" tag --list '2HOL_v*' --sort=-version:refname | head -n 1)"
    [[ -n "$tag" ]] || fail "No 2HOL_v* release tags found in $dir after fetching tags."
    printf '%s' "$tag"
}

clone_or_validate minorGems https://github.com/twohoursonelife/minorGems.git
clone_or_validate OneLife https://github.com/twohoursonelife/OneLife.git
clone_or_validate OneLifeData7 https://github.com/twohoursonelife/OneLifeData7.git

# The old upstream install script referenced 2HOL_liveServer, but that branch
# is not exposed by the current official repository. Use one shared version
# tag across code, game data, and engine to avoid a mixed-version installation.
server_tag="$(latest_2hol_tag OneLife)"
echo "Selected common 2HOL release: $server_tag"

for dir in OneLife OneLifeData7 minorGems; do
    git -C "$ROOT/$dir" rev-parse --verify "refs/tags/$server_tag^{commit}" >/dev/null 2>&1 \
        || fail "$dir does not contain $server_tag. Refusing to mix incompatible release versions."
    current="$(git -C "$ROOT/$dir" describe --tags --exact-match HEAD 2>/dev/null || true)"
    if [[ "$current" == "$server_tag" ]]; then
        echo "$dir already at $server_tag."
        continue
    fi
    if [[ -n "$(git -C "$ROOT/$dir" status --porcelain)" ]]; then
        fail "$dir has local changes. Back them up or clean them manually before switching to $server_tag."
    fi
    echo "Checking out $dir $server_tag..."
    git -C "$ROOT/$dir" checkout --detach "$server_tag"
done

server_dir="$ROOT/OneLife/server"
[[ -x "$server_dir/configure" ]] || fail "Expected configure script not found at $server_dir/configure."

# Point the server at the matching 2HOL game data without replacing real files.
for name in objects transitions categories tutorialMaps dataVersionNumber.txt; do
    link="$server_dir/$name"
    target="../../OneLifeData7/$name"
    if [[ -L "$link" ]]; then
        [[ "$(readlink "$link")" == "$target" ]] || fail "$link points somewhere unexpected. Inspect it before changing it."
    elif [[ -e "$link" ]]; then
        fail "$link already exists as a real file/directory, not a symlink. Nothing was overwritten."
    else
        ln -s "$target" "$link"
    fi
done

server_version="${server_tag#2HOL_v}"
printf '%s\n' "$server_version" > "$server_dir/serverCodeVersionNumber.txt"
mkdir -p "$server_dir/settings"
printf '0\n' > "$server_dir/settings/requireTicketServerCheck.ini"
printf '8005\n' > "$server_dir/settings/port.ini"

jobs="${BUILD_JOBS:-2}"
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || fail 'BUILD_JOBS must be a positive integer.'
echo "Configuring 2HOL server for Linux (release $server_tag)..."
(
    cd "$server_dir"
    ./configure 1
    make -j"$jobs"
)
[[ -x "$server_dir/OneLifeServer" ]] || fail 'Build finished without producing OneLife/server/OneLifeServer.'
[[ -s "$server_dir/serverCodeVersionNumber.txt" ]] || fail 'Server version file is missing or empty.'

echo
echo '2HOL server build completed.'
echo "Server code/data tag: $server_tag"
echo 'Next: run bash scripts/start-2hol.sh to launch the server.'
echo 'Your world database files will be stored under OneLife/server and are excluded from Git.'
