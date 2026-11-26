#!/usr/bin/env bash
# Stops the gate before it starts where the disk it builds on lacks room for it. A build that runs
# the disk out of space fails part-way, can leave a file it was writing cut short, and stops every
# other program on the machine that writes.
#
#   bash scripts/check-disk.sh
#
# A first gate writes about 25 GB under `.build`, with the Linux images and the simulator's data on
# top, so it asks for 35 GB free where `.build/platforms` does not exist yet. A later gate rewrites
# what it built in place and asks for 15 GB. MOUNTAYA_MIN_FREE_GB, when set, asks for that many
# instead. Under CI the runner is sized for the gate, and the check passes saying so. Short of room,
# it names what frees some: `mise run clean`, inside the repository, and `mise run clean:toolchains`,
# the Linux images of a Swift no checkout pins any more, which is the person's to run.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"

if [ -n "${CI:-}" ]; then
  ok "CI: the runner is sized for the gate, so the free space is not checked"
  exit 0
fi

if [ -n "${MOUNTAYA_MIN_FREE_GB:-}" ]; then
  need="$MOUNTAYA_MIN_FREE_GB"
elif [ -d .build/platforms ]; then
  need=15
else
  need=35
fi

free_gb="$(df -Pk . | awk 'NR == 2 { printf "%d", $4 / 1048576 }')"
# Measured only where `.build` exists: in a fresh clone `du` fails, and under `set -e` and
# `pipefail` that failure ended the script with no word said, before a first gate could start.
built_gb=0
if [ -d .build ]; then
  built_gb="$(du -sk .build | awk '{ printf "%.1f", $1 / 1048576 }')"
fi

if [ "$free_gb" -lt "$need" ]; then
  die "The disk this repository builds on has ${free_gb} GB free, and the gate asks for ${need} GB." \
    "mise run clean -- --dry-run          # what the builds left behind and no longer use" \
    "mise run clean -- --all              # every build directory (${built_gb:-0} GB now), rebuilt by the next gate" \
    "mise run clean:toolchains            # yours to run: the Linux images of a Swift no checkout pins; -- --yes deletes them" \
    "MOUNTAYA_MIN_FREE_GB=<n> mise run ci # ask for less, knowing a full disk stops the build part-way"
fi
ok "${free_gb} GB free on the disk this repository builds on; the gate asks for ${need} GB"
