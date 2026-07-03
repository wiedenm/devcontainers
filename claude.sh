#!/bin/bash
#
# Simplifies launching Claude inside the dev container.
# Assumes the script's located in <worktree>/.devcontainers.

WORKTREE=$(dirname "$(dirname "$(realpath "$0")")")

devcontainer exec --workspace-folder "$WORKTREE" -- \
  zsh -i -c "claude --dangerously-skip-permissions; exec zsh -i"
