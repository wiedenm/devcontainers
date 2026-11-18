#!/bin/bash
#
# Simplifies starting up containers with support for git worktrees.
# Assumes the script's located in <worktree>/.devcontainers.

WORKTREE=$(dirname "$(cd "$(dirname "$0")" && pwd -P)")

devcontainer up \
  --workspace-folder "$WORKTREE" \
  --mount-git-worktree-common-dir
