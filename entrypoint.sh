#!/bin/bash
set -e

export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# Ensure data directory is owned by the sqld user (for Railway volumes)
chown -R sqld:sqld /var/lib/sqld

# Start sqld in background (filter out ASCII art banner, keep useful info)
gosu sqld /bin/sqld --db-path /var/lib/sqld/data.sqld "$@" 2>&1 | grep -v "___  __ _" | grep -v "/ __|/ _\`" | grep -v "\\__ \\\\ (_|" | grep -v "|___\\\\__," | grep -v "|_|" | grep -v "sqld!" | grep -v "This software is in BETA" | grep -v "If you encounter any bug" &
SQLD_PID=$!

# Wait for sqld to start up, then show credentials
sleep 1
if [ -z "$SQLD_AUTH_JWT_KEY" ]; then
    echo ""
    echo ""
    /usr/local/bin/token-gen
    echo ""
fi

# Wait for sqld process
wait $SQLD_PID
