#!/bin/bash
#
# Extracts the OAuth credentials obtained via an earlier interactive `claude` login from the macOS keychain into a file
# that the dev container mounts as $CLAUDE_CONFIG_DIR/.credentials.json. The keychain payload uses the very same format
# that Claude stores in .credentials.json on Linux, so this is a plain copy without any transformation.
#
# Caveat: Claude refreshes these tokens inside the container and writes them back through the mount, while the host
# keychain keeps the original ones. Refresh tokens usually rotate, so the host's copy may become invalid, logging out
# the host's Claude. Use a long-lived token from `claude setup-token` via CLAUDE_CODE_OAUTH_TOKEN if that's a problem.

set -euo pipefail

DEST="${HOME}/dev/claude-config/.credentials/claude_code.credentials.json"
SERVICE="Claude Code-credentials"

# Keep the credentials readable by their owner only.
umask 077

if ! creds=$(security find-generic-password -s "$SERVICE" -a "$USER" -w 2>/dev/null); then
    echo "error: no keychain item '$SERVICE' for account '$USER'. Log in by running 'claude' on the host first." >&2
    exit 1
fi

if ! printf '%s' "$creds" | jq -e '.claudeAiOauth.refreshToken != null' >/dev/null 2>&1; then
    echo "error: keychain item '$SERVICE' holds no OAuth refresh token." >&2
    exit 1
fi

mkdir -p "$(dirname "$DEST")"
printf '%s\n' "$creds" >"$DEST"
chmod 600 "$DEST"

# Report a fingerprint of the refresh token rather than the token itself, so that rotation can be spotted by comparing
# the fingerprint before and after the container has used the credentials.
FINGERPRINT=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.refreshToken' | shasum -a 256 | cut -c1-12)
EXPIRES_AT=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.expiresAt / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ")')

echo "wrote $DEST"
echo "  refresh token fingerprint: $FINGERPRINT"
echo "  access token expires at:   $EXPIRES_AT"

# The keychain is only a snapshot: the host's Claude refreshes its tokens in memory and does not necessarily write them
# back. Once the snapshot is old enough, its refresh token is rotated away too and the container fails to authenticate
# with "OAuth session expired and could not be refreshed". Warn rather than fail, since a merely expired access token is
# the normal case and can be refreshed.
EXPIRES_AT_SECONDS=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.expiresAt / 1000 | floor')
STALE_FOR_DAYS=$((($(date +%s) - EXPIRES_AT_SECONDS) / 86400))
if [ "$STALE_FOR_DAYS" -gt 7 ]; then
    echo "warning: this snapshot expired $STALE_FOR_DAYS days ago, its refresh token is likely rotated away." >&2
    echo "         Log in again on the host ('/login' in Claude) to refresh the keychain, then re-run this script." >&2
fi
