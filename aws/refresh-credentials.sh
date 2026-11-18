#!/bin/sh
#
# Writes short-lived credentials of the host's specified AWS profile to where the dev containers can read them through
# `credential_process`. This way, we make sure dev containers always have access to valid credentials without having
# access to the SSO token (whose scope is wider than just the selected profile).

set -eu
umask 077

AWS_PROFILE="devops"

# Make sure the AWS CLI is on the path.
PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

DIR="$HOME/dev/claude-config/.credentials/aws"
mkdir -p "$DIR"

# Replace files via rename so that containers never read a partially written one.
printf '[default]\ncredential_process = cat %s/credentials.json\nregion = eu-west-1\n' "$DIR" > "$DIR/.config.tmp"
mv "$DIR/.config.tmp" "$DIR/config"

TMP=$(mktemp "$DIR/.credentials.XXXXXX")
if aws configure export-credentials --profile "$AWS_PROFILE" --format process > "$TMP"; then
  mv "$TMP" "$DIR/credentials.json"
else
  rm -f "$TMP"
  echo "$(date): refresh failed, run: aws sso login --profile $AWS_PROFILE" >&2
  exit 1
fi
