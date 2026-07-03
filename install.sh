#!/bin/bash
#
# Sets up the target directory for use with devcontainers.
# Usage: ./install.sh <source-dir> <target-dir>

set -euo pipefail

SOURCE_DIR="$(realpath "${1:?Usage: $0 <source-directory> <target-directory>}")"
TARGET_DIR="$(realpath "${2:?Usage: $0 <source-directory> <target-directory>}")"

echo "Setting up $TARGET_DIR..."

TARGET_DIR="$TARGET_DIR/.devcontainer"

mkdir -p "$TARGET_DIR"

TARGET=$TARGET_DIR/devcontainer.json
if [ -e "$TARGET" ]; then
    echo "Skipping $TARGET (already exists)"
else
    cp "$SOURCE_DIR/devcontainer.json" "$TARGET"
fi

CURRENT_DIR=$(dirname "$(realpath "$0")")
for name in claude.sh copy-to-container.sh down.sh up.sh; do
    TARGET=$TARGET_DIR/$name
    if [ -e "$TARGET" ]; then
        echo "Skipping $TARGET (already exists)"
    else
        cp "$CURRENT_DIR/$name" "$TARGET"
        chmod +x "$TARGET"
    fi
done

echo "done."