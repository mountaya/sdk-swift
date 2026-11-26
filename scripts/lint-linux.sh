#!/usr/bin/env bash
# Runs the lints and the printed files' check in the official Swift container for one toolchain
# version: the format check and its never-force rules, the layout law, the naming law, and whether
# the printed surface is what the contract prints.
#
#   bash scripts/lint-linux.sh <swift version>
#
# The version comes from mise.toml, which is the one place it is written. The naming law reads
# this host's symbol graphs; the declarations an iOS build alone compiles are read by the macOS
# run, `mise run lint:naming`. The repository is mounted read-write, since the tools build under
# `.build/`, in the scratch directory the version's suites build in, and the contract checkout is
# mounted read-only beside it, where the printer reads the model.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd docker "Docker Desktop, installed by hand"

version="${1:?usage: bash scripts/lint-linux.sh <swift version>}"
schemas="${MOUNTAYA_SCHEMAS_DIR:-$PWD/../schemas}"

set -- --rm \
  -v "$PWD":/work/sdk-swift \
  -w /work/sdk-swift \
  -e CI

# A host path that does not exist would be created by the mount, so it is mounted only when it is
# there. Without it the printer's check says the contract is missing.
if [ -d "$schemas" ]; then
  set -- "$@" -v "$(cd "$schemas" && pwd)":/work/schemas:ro
fi

# Each step in the container, in the order `mise run lint` and the gate run them; the first that
# fails stops the rest. The scratch directory is the container shell's `$0`.
steps='swift format lint --strict --recursive Package.swift Sources Tests Tools Examples'
steps="$steps"' && swift run --scratch-path "$0" LintFileStructure'
steps="$steps"' && swift run --scratch-path "$0" LintNaming'
steps="$steps"' && swift run --scratch-path "$0" GenerateClient --check'

exec docker run "$@" "swift:${version}-noble" sh -c "$steps" ".build/linux-${version}"
