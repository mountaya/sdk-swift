#!/usr/bin/env bash
# Refuses to run the gate on a toolchain other than the one mise.toml names.
#
#   bash scripts/check-toolchain.sh <swift version> <xcode version>
#
# On Linux mise installs the Swift it pins. On macOS the compiler is Xcode's, which mise cannot
# install, so the pin is asserted instead: a gate that passed on another compiler says nothing
# about this one.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd swift "Xcode on macOS, or the pinned Swift from mise on Linux"
require_cmd xcodebuild "Xcode, installed by hand"

swift_version="${1:?usage: bash scripts/check-toolchain.sh <swift version> <xcode version>}"
xcode_version="${2:?usage: bash scripts/check-toolchain.sh <swift version> <xcode version>}"

# The compiler prints 6.4.0 as "6.4" and 6.2.3 as "6.2.3".
short_version="${swift_version%.0}"
reported="$(swift --version 2>&1)"

case "$(uname -s)" in
  Darwin)
    xcode="$(xcodebuild -version | sed -n 1p)"
    if [ "$xcode" != "Xcode ${xcode_version}" ]; then
      echo "mise.toml names Xcode ${xcode_version}, and the selected one is ${xcode}." >&2
      exit 1
    fi
    ;;
esac

case "$reported" in
  *"Swift version ${short_version} "*) ;;
  *)
    echo "mise.toml names Swift ${swift_version}, and \`swift --version\` reports:" >&2
    echo "$reported" >&2
    exit 1
    ;;
esac

echo "The toolchain is the pinned one: Swift ${swift_version}."
