#!/usr/bin/env bash
# Runs the test suites in the official Swift container for one toolchain version.
#
#   bash scripts/test-linux.sh <swift version>
#
# SWIFT_TEST_SKIP, when set, is passed to `swift test --skip`, for a run narrowed by hand; the
# gate (`mise run ci`) sets nothing and runs every suite.
#
# The version comes from mise.toml, which is the one place it is written. The repository is
# mounted read-write, since the build writes under `.build/`, and the contract checkout and the
# `ai` checkout, whose skill for this SDK BoundaryTests reads, are mounted read-only beside it,
# where the suites look for them: the Linux run checks the report and never writes one. Each
# version builds into a scratch directory of its own, apart from the host's.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd docker "Docker Desktop, installed by hand"

version="${1:?usage: bash scripts/test-linux.sh <swift version>}"
schemas="${MOUNTAYA_SCHEMAS_DIR:-$PWD/../schemas}"
ai="$PWD/../ai"

set -- --rm \
  -v "$PWD":/work/sdk-swift \
  -w /work/sdk-swift \
  -e CI \
  -e MOUNTAYA_CONFORMANCE_REPORT \
  -e MOUNTAYA_CONFORMANCE_ONLY \
  -e SWIFT_TEST_SKIP

# A host path that does not exist would be created by the mount, so each is mounted only when
# it is there. Without one the suites run as they do for a contributor with no such checkout.
if [ -d "$schemas" ]; then
  set -- "$@" -v "$(cd "$schemas" && pwd)":/work/schemas:ro
fi
if [ -d "$ai" ]; then
  set -- "$@" -v "$(cd "$ai" && pwd)":/work/ai:ro
fi

exec docker run "$@" "swift:${version}-noble" \
  sh -c 'exec swift test --disable-xctest --scratch-path "$0" ${SWIFT_TEST_SKIP:+--skip "$SWIFT_TEST_SKIP"}' ".build/linux-${version}"
