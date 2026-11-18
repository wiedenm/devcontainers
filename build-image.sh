#!/bin/bash
#
# Builds the image devcontainer.json starts from (claude-code-devcontainer:latest), from scratch and with the latest base
# image and features. Run it on purpose to update all containers at once, then recreate them with rebuild.sh.

set -euo pipefail

DIR="$(dirname "$(realpath "$0")")/image"

docker pull "$(awk '/^FROM/ { print $2 }' "$DIR/Dockerfile")"
devcontainer build --workspace-folder "$DIR" --config "$DIR/devcontainer.json" --image-name claude-code-devcontainer:latest \
  --no-cache

# Drop the image replaced above, unless containers still use it.
docker image prune -f
