#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

region="${REGION:-iad}"
scale="${SCALE:-1}"

fly scale count -y -a "live-svg-ball" -r "$region" "$scale"
