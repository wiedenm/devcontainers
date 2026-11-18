#!/bin/bash
#
# Builds the images the dev container configs start from (claude-code-<flavor>:latest), from scratch and with the latest
# base images and features. Run it on purpose to update all containers at once, then recreate them with rebuild.sh.
# Usage: ./build-images.sh [<flavor>...] (default: base go java)

set -euo pipefail

DIR="$(dirname "$(realpath "$0")")/images"

flavors=("$@")
[[ $# -gt 0 ]] || flavors=(base go java)

for flavor in "${flavors[@]}"; do
    config="$DIR/$flavor/devcontainer.json"
    docker pull "$(grep -o '"BASE_IMAGE": *"[^"]*"' "$config" | cut -d'"' -f4)"
    devcontainer build --workspace-folder "$DIR" --config "$config" --image-name "claude-code-$flavor:latest" --no-cache
done

# Drop the images replaced above, unless containers still use them.
docker image prune -f
