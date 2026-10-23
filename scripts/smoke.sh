#!/usr/bin/env bash
# Check that a read-only wacli refuses every write and still pairs and syncs.
# Usage: scripts/smoke.sh path/to/wacli
set -uo pipefail

bin="${1:?usage: smoke.sh <wacli binary>}"
store="$(mktemp -d)"
failed=0
readonly_msg="read-only mode"
to="15550000001"
chat="15550000001@s.whatsapp.net"

expect() {
  local want="$1"; shift
  local got
  got="$(timeout 30 "$@" 2>&1 || true)"
  if [[ "$got" == *"$want"* ]]; then
    echo "ok    ${*:2}"
  else
    echo "FAIL  ${*:2}"
    echo "      want: $want"
    echo "      got:  ${got:0:300}"
    failed=1
  fi
}

refused() { expect "$readonly_msg" "$bin" --store "$store" "$@"; }

file "$bin" | grep -q "statically linked" || { echo "FAIL  binary is not statically linked"; failed=1; }

refused send text --to "$to" --message hi
refused send react --to "$to" --id ABC --reaction x
refused messages delete --chat "$chat" --id ABC
refused messages edit --chat "$chat" --id ABC --message x
refused chats mark-read --chat "$chat"
refused chats archive --chat "$chat"
refused groups leave --jid 120363000000000000@g.us
refused profile set-name x
refused presence typing --to "$to"
refused auth logout
expect "$readonly_msg" env WACLI_READONLY=0 "$bin" --store "$store" send text --to "$to" --message hi

# Pairing and sync must still be allowed: without a session they stop at authentication.
expect "Not authenticated" "$bin" --store "$store" auth status
expect "not authenticated" "$bin" --store "$store" sync --once

rm -rf "$store"
exit "$failed"
