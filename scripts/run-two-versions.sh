#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

process-compose -f process-compose-upgrade.yaml
