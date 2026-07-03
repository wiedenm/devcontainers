#!/bin/bash
#
# Simplifies stopping and removing a running devcontainer without having to look up its name/ID and going via the
# `docker` CLI.
# Assumes the script's located in <worktree>/.devcontainers.
 
set -euo pipefail
 
container=$(docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1)
 
if [[ -z "$container" ]]; then
  echo "No devcontainer found for $(pwd)" >&2
  exit 1
fi
 
docker stop "$container"
docker rm "$container"
