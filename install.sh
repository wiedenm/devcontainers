#!/bin/bash
#
# Sets up the target directory for use with devcontainers.
# Usage: ./install.sh [<target-dir>] (default: current directory)

set -euo pipefail

TARGET_DIR="$(realpath "${1:-.}")"

echo "Setting up $TARGET_DIR..."

TARGET_DIR="$TARGET_DIR/.devcontainer"

mkdir -p "$TARGET_DIR"

CURRENT_DIR=$(dirname "$(realpath "$0")")
for name in devcontainer.json claude.sh copy-to-container.sh down.sh rebuild.sh stop.sh up.sh; do
    TARGET=$TARGET_DIR/$name
    if [ -e "$TARGET" ]; then
        echo "Skipping $TARGET (already exists)"
    else
        ln -s "$CURRENT_DIR/$name" "$TARGET"
    fi
done

echo "*" > "$TARGET_DIR/.gitignore"

echo "done."