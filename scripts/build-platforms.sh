#!/usr/bin/env bash
# Builds every target under Sources/ for each Apple platform other than the host's.
#
#   bash scripts/build-platforms.sh
#
# The host build proves macOS. This proves the rest, which is where an `@available` barrier or
# an API missing from one platform shows. A triple carries no version: the floor comes from
# Package.swift, which is the one place it is written. Each platform builds into a scratch
# directory of its own.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd swift "Xcode on macOS, or the pinned Swift from mise on Linux"
require_cmd xcrun "Xcode, installed by hand"

for target in Sources/*/; do
  name="$(basename "$target")"
  while read -r platform triple sdk; do
    echo "== ${name} for ${platform}"
    swift build \
      --target "$name" \
      --triple "$triple" \
      --sdk "$(xcrun --sdk "$sdk" --show-sdk-path)" \
      --scratch-path ".build/platforms/${platform}"
  done <<'PLATFORMS'
ios arm64-apple-ios iphoneos
tvos arm64-apple-tvos appletvos
watchos arm64_32-apple-watchos watchos
visionos arm64-apple-xros xros
catalyst arm64-apple-ios-macabi macosx
PLATFORMS
done
