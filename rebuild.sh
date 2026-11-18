#!/bin/bash
#
# Simplifies recreating the devcontainer, e.g. to pick up changes to devcontainer.json or an image rebuilt by
# build-image.sh, while keeping its Docker-in-Docker volumes.
# Assumes the script's located in <worktree>/.devcontainers.

WORKTREE=$(dirname "$(cd "$(dirname "$0")" && pwd -P)")

devcontainer up \
  --workspace-folder "$WORKTREE" \
  --mount-git-worktree-common-dir \
  --remove-existing-container
