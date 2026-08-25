#!/bin/bash
#
# Simplifies starting up containers with support for git worktrees.
# Assumes the script's located in <worktree>/.devcontainers.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
WORKTREE=$(dirname "$SCRIPT_DIR")

# Refresh the credentials that the container mounts to authenticate Claude. This must succeed before the container is
# started: if the file were missing, Docker would silently create a directory in its place and break Claude's auth.
"$SCRIPT_DIR/extract-claude-credentials.sh"

devcontainer up \
  --workspace-folder "$WORKTREE" \
  --mount-git-worktree-common-dir
