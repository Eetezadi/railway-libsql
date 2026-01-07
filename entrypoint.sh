#!/bin/bash
# Set defaults
USER=${DB_USER:-root}
PASS=${DB_PASSWORD}

# 1. Configuration for Railway/External Access
# Force binding to 0.0.0.0 so Railway can route traffic to it
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# 2. Auth Logic
if [ -n "$PASS" ]; then
    AUTH_STR=$(echo -n "$USER:$PASS" | base64 | tr -d '\n')
    export SQLD_HTTP_AUTH="basic:$AUTH_STR"
    echo "Auth configured for user: $USER"
fi

# 3. Fix Permissions
# Ensure the sqld user owns the data directory before starting
# sqld default path is usually /var/lib/sqld
mkdir -p /var/lib/sqld
# Note: Since we switch to USER sqld in Dockerfile, we need to ensure 
# the volume mount point is writable.

echo "Starting libSQL on $SQLD_HTTP_LISTEN_ADDR..."
exec /bin/sqld --db-path /var/lib/sqld/data.sqld "$@"
