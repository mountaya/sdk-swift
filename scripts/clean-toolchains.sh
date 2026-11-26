#!/usr/bin/env bash
# USAGE-START
# Lists the Linux container images this repository's Linux runs pulled for a Swift no Mountaya
# checkout pins any more, and deletes them with --yes. Docker keeps them in a disk of its own that
# every project on the machine shares, so it is the person's to run: an agent is denied it, and
# neither the gate nor `mise run clean`, which deletes inside the repository alone, runs it.
#
#   bash scripts/clean-toolchains.sh [--yes]
#
# Without --yes it lists each image it would delete and the room that would free, and deletes
# nothing. It reads the official Swift container alone, `swift:<version>-noble`, the image
# `scripts/test-linux.sh` and `scripts/lint-linux.sh` run, and keeps every version a Mountaya
# checkout beside this one pins, this one's included: each `swift` and `swift_floor` of a
# `../*/mise.toml`, the pinned toolchain and the floor the suites run at. No other image is ever
# touched. An image a container still holds, running or stopped, is kept and named, as Docker keeps
# it; a Docker that does not answer within five seconds, as Docker Desktop hangs when its disk
# fills, is passed over and nothing is deleted. A Swift toolchain on the host is never touched: on
# macOS the compiler is Xcode's, and on Linux mise's install of the pinned one.
# USAGE-END
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd docker "Docker Desktop, installed by hand"

yes=0
for argument in "$@"; do
  case "$argument" in
    --yes) yes=1 ;;
    --) ;;
    *) die "Unknown argument: $argument" "bash scripts/clean-toolchains.sh --help" ;;
  esac
done

root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"
freed_kb=0
found=0

# human <kilobytes>: a size the way df and du print it to a person.
human() {
  awk -v k="$1" 'BEGIN { if (k >= 1048576) printf "%.1f GB", k / 1048576; else printf "%.0f MB", k / 1024 }'
}

# docker_answers: whether Docker's daemon answers within five seconds. One that hung, as Docker
# Desktop does when its disk fills, is passed over rather than waited on.
docker_answers() {
  docker info >/dev/null 2>&1 &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge 50 ]; then
      kill "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 0.1
    waited=$((waited + 1))
  done
  wait "$pid"
}

# The Swift versions every Mountaya checkout beside this one pins, this one's included: a
# `swift = "<v>"` or a `swift_floor = "<v>"`, each read as written.
pinned=" $(cat ../*/mise.toml 2>/dev/null \
  | sed -n 's/^[[:space:]]*swift\(_floor\)\{0,1\}[[:space:]]*=[[:space:]]*"\([0-9][0-9.]*\)".*/\2/p' \
  | tr '\n' ' ')"
case "$pinned" in
  *[0-9]*) ;;
  *) die "No Mountaya checkout's mise.toml pins a Swift, so nothing can be told kept." \
    "Run it from a checkout of sdk-swift, whose mise.toml pins swift and swift_floor." ;;
esac
info "kept: every swift:<version>-noble image of a pinned Swift,${pinned% }"

if ! docker_answers; then
  warn "Docker does not answer, so its images were not looked at and nothing was deleted"
  exit 0
fi

for image in $(docker images --format '{{.Repository}}:{{.Tag}}' swift 2>/dev/null); do
  tag="${image#swift:}"
  case "$tag" in
    [0-9]*-noble) version="${tag%-noble}" ;;
    *) continue ;;
  esac
  case "$pinned " in
    *" ${version} "*) continue ;;
  esac
  holders="$(docker ps --all --quiet --filter "ancestor=${image}" 2>/dev/null || true)"
  if [ -n "$holders" ]; then
    info "kept the image ${image}: a container still holds it"
    continue
  fi
  bytes="$(docker image inspect --format '{{.Size}}' "$image" 2>/dev/null || echo 0)"
  kb=$((${bytes:-0} / 1024))
  found=$((found + 1))
  why="no Mountaya checkout pins Swift ${version}"
  if [ "$yes" = 0 ]; then
    info "would delete the image ${image} ($(human "$kb")): ${why}"
    freed_kb=$((freed_kb + kb))
  elif docker image rm "$image" >/dev/null 2>&1; then
    info "deleted the image ${image} ($(human "$kb")): ${why}"
    freed_kb=$((freed_kb + kb))
  else
    warn "kept the image ${image}: Docker refused to delete it"
  fi
done

if [ "$found" = 0 ]; then
  ok "Nothing to delete: every Swift image here is one a pin uses"
elif [ "$yes" = 1 ]; then
  ok "$(human "$freed_kb") freed"
else
  ok "$(human "$freed_kb") would be freed: nothing was deleted, and \`mise run clean:toolchains -- --yes\` deletes it"
fi
