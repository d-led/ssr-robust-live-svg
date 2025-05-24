#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "${SCRIPT_DIR}/.."

new_module="lib/braitenberg_vehicles_live/actor_behaviors/random_rebound_v2_non_sticky.ex"

echo "--== releasing the first version "
mv "${new_module}" "{new_module}.tmp" || true
MIX_ENV=prod mix release --path _build/demo/v1 --overwrite

echo "--== bumpting the patch version ==--"
mix bump_version patch

echo "--== releasing the patched version ==--"
mv "{new_module}.tmp" "${new_module}" || true
MIX_ENV=prod mix release --path _build/demo/v2 --overwrite

echo "--== reverting mix.exs ==--"
git checkout -- mix.exs
