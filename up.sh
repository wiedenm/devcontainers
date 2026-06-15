#!/bin/bash
#
# Simplifies starting up containers with support for git worktrees.
# Assumes the script's located in <worktree>/.devcontainers.

WORKTREE=$(dirname "$(dirname "$(realpath "$0")")")

devcontainer up \
  --workspace-folder "$WORKTREE" \
  --mount-git-worktree-common-dir
