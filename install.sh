#!/bin/bash
#
# Sets up the target directory for use with devcontainers.

set -euo pipefail

SOURCE_DIR="$(realpath "${1:?Usage: $0 <source-directory> <target-directory>}")"
TARGET_DIR="$(realpath "${2:?Usage: $0 <source-directory> <target-directory>}")"

echo "Setting up $TARGET_DIR..."

mkdir -p "$TARGET_DIR/.devcontainer"

TARGET=$TARGET_DIR/.devcontainer/devcontainer.json
if [ -e "$TARGET" ]; then
    echo "Skipping $TARGET (already exists)"
else
    cp "$SOURCE_DIR/devcontainer.json" "$TARGET"
fi

echo "done."