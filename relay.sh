#!/bin/sh

apk add --no-cache curl jq

echo "Starting ntfy relay: $RELAY_TOPICS"

# Simple single relay - no subshells
SRC=$(echo "$RELAY_TOPICS" | cut -d: -f1)
DST=$(echo "$RELAY_TOPICS" | cut -d: -f2)

echo "Relaying $SRC -> $DST"

while true; do
  echo "[$SRC] Connecting..."
  curl -N -H "Authorization: Bearer $TOKEN" "$NTFY_BASE/$SRC/json?since=all" 2>/dev/null |
  while read -r line; do
    [ -z "$line" ] && continue
    msg=$(echo "$line" | jq -r 'select(.event=="message") | .message // empty' 2>/dev/null)
    [ -z "$msg" ] && continue
    echo "[$SRC] Forwarding to $DST"
    curl -H "Authorization: Bearer $TOKEN" -d "$msg" "$NTFY_BASE/$DST" >/dev/null 2>&1
  done
  echo "[$SRC] Reconnecting in 5s..."
  sleep 5
done
