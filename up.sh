#!/bin/bash
#
# Assumes the script's located at <worktree>/.devcontainers.

WORKTREE=$(dirname "$(dirname "$(realpath "$0")")")
GIT_ENTRY="${WORKTREE}/.git"

if [ -d "$GIT_ENTRY" ]; then
  # .git is a directory — this is a main repo, no mount needed
  MAIN_REPO="$WORKTREE"
  echo "Detected: main repo"
elif [ -f "$GIT_ENTRY" ]; then
  # .git is a file — this is a worktree, resolve main repo from gitdir pointer
  GITDIR_LINE=$(cat "$GIT_ENTRY")
  GITDIR_PATH="${GITDIR_LINE#gitdir: }"
  MAIN_GIT=$(dirname "$(dirname "$GITDIR_PATH")")
  MAIN_REPO=$(dirname "$MAIN_GIT")
  echo "Detected: worktree"
else
  echo "Error: ${GIT_ENTRY} is neither a file nor a directory" >&2
  exit 1
fi

echo "  Worktree:  ${WORKTREE}"
echo "  Main repo: ${MAIN_REPO}"

MOUNT_ARGS=""
if [ "$MAIN_REPO" != "$WORKTREE" ]; then
  MOUNT_ARGS="--mount type=bind,source=${MAIN_REPO},target=${MAIN_REPO}"
fi

echo "  Mount args: ${MOUNT_ARGS:-<none>}"

devcontainer up \
  --workspace-folder "$WORKTREE" \
  $MOUNT_ARGS
