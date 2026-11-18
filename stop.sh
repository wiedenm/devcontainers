#!/bin/bash
#
# Simplifies stopping a running devcontainer, and everything running in its Docker-in-Docker, without removing it. up.sh
# starts it again.
# Assumes the script's located in <worktree>/.devcontainers.

set -euo pipefail

container=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1)

if [[ -z "$container" ]]; then
  echo "No running devcontainer found for $(pwd)" >&2
  exit 1
fi

docker stop "$container"
