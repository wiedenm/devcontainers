#!/bin/bash
#
# Simplifies launching Claude inside the dev container.
# Assumes the script's located in <worktree>/.devcontainers.

WORKTREE=$(dirname "$(cd "$(dirname "$0")" && pwd -P)")

HERDR_AGENT=claude devcontainer exec --workspace-folder "$WORKTREE" -- \
  zsh -i -c "claude --dangerously-skip-permissions --add-dir /workspaces/git"
