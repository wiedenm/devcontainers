#!/bin/bash
#
# Allows ad-hoc copying of files and directories into the workspace of a running devcontainer, e.g. to make additional
# data available to an agent without having to restart the container (which would be necessary when mounting additional
# volumes).
# Assumes the script's ran from the base directory containing `.devcontainer/devcontainer.json`.
 
set -euo pipefail
 
if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <source>" >&2
  exit 1
fi
 
container=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1)
 
if [[ -z "$container" ]]; then
  echo "No devcontainer found for $(pwd)" >&2
  exit 1
fi
 
docker cp "$1" "$container":/workspaces/
