#!/bin/bash
# Map this repository's existing App Store Connect secret names onto the
# environment variables the `asc` CLI reads, so no secrets need renaming.
#
#   source scripts/asc-env.sh
#
# Accepts either naming scheme:
#   APP_STORE_CONNECT_KEY_ID        -> ASC_KEY_ID
#   APP_STORE_CONNECT_ISSUER_ID     -> ASC_ISSUER_ID
#   APP_STORE_CONNECT_API_KEY_BASE64 -> ASC_PRIVATE_KEY_B64
#   APP_STORE_CONNECT_APP_ID        -> ASC_APP_ID
#
# `asc` reads these directly, so no `asc auth login` step is needed in CI.

export ASC_KEY_ID="${ASC_KEY_ID:-${APP_STORE_CONNECT_KEY_ID:-}}"
export ASC_ISSUER_ID="${ASC_ISSUER_ID:-${APP_STORE_CONNECT_ISSUER_ID:-}}"
export ASC_PRIVATE_KEY_B64="${ASC_PRIVATE_KEY_B64:-${APP_STORE_CONNECT_API_KEY_BASE64:-}}"
export ASC_APP_ID="${ASC_APP_ID:-${APP_STORE_CONNECT_APP_ID:-}}"

# CI runners have no unlockable keychain, and nothing here should phone home
# for update checks mid-release.
export ASC_BYPASS_KEYCHAIN="${ASC_BYPASS_KEYCHAIN:-1}"
export ASC_NO_UPDATE="${ASC_NO_UPDATE:-1}"

asc_missing=""
[ -n "$ASC_KEY_ID" ]          || asc_missing="$asc_missing\n   - ASC_KEY_ID / APP_STORE_CONNECT_KEY_ID"
[ -n "$ASC_ISSUER_ID" ]       || asc_missing="$asc_missing\n   - ASC_ISSUER_ID / APP_STORE_CONNECT_ISSUER_ID"
[ -n "$ASC_PRIVATE_KEY_B64" ] || asc_missing="$asc_missing\n   - ASC_PRIVATE_KEY_B64 / APP_STORE_CONNECT_API_KEY_BASE64"
[ -n "$ASC_APP_ID" ]          || asc_missing="$asc_missing\n   - ASC_APP_ID / APP_STORE_CONNECT_APP_ID"

if [ -n "$asc_missing" ]; then
    printf "⚠️  Missing App Store Connect credentials:%b\n" "$asc_missing" >&2
    echo "   See docs/APP_STORE_CONNECT.md for setup." >&2
    return 1 2>/dev/null || exit 1
fi
unset asc_missing
