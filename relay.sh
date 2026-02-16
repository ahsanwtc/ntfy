#!/bin/sh

echo "Installing dependencies..."
apk add --no-cache curl jq

echo "Starting ntfy relay service"
echo "Base URL: $NTFY_BASE"
echo "Topics: $RELAY_TOPICS"
echo "Token set: ${TOKEN:+yes}"

echo "$RELAY_TOPICS" | tr "," "\n" | while IFS=: read -r src dst; do
  echo "Will relay $src -> $dst"
  (
    while true; do
      echo "[$src] Connecting to $NTFY_BASE/$src/json?since=all"
      curl -N -H "Authorization: Bearer $TOKEN" "$NTFY_BASE/$src/json?since=all" 2>/dev/null |
      while read -r line; do
        [ -z "$line" ] && continue
        msg=$(echo "$line" | jq -r 'select(.event=="message") | .message // empty' 2>/dev/null)
        [ -z "$msg" ] && continue
        title=$(echo "$line" | jq -r 'select(.event=="message") | .title // empty' 2>/dev/null)
        echo "[$src] Forwarding message to $dst: $msg"
        if [ -n "$title" ]; then
          curl -H "Authorization: Bearer $TOKEN" -H "Title: $title" -d "$msg" "$NTFY_BASE/$dst" >/dev/null 2>&1
        else
          curl -H "Authorization: Bearer $TOKEN" -d "$msg" "$NTFY_BASE/$dst" >/dev/null 2>&1
        fi
      done
      echo "[$src] Connection lost, reconnecting in 5s..."
      sleep 5
    done
  ) &
done

wait
