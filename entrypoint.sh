#!/bin/bash
set -e

# Default to 'root' if no user is specified, and bind to Railway's assigned port
DB_USER=${DB_USER:-root}
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# Calculate Auth Token only if a password exists
if [ -n "$DB_PASSWORD" ]; then
    AUTH_STR=$(echo -n "$DB_USER:$DB_PASSWORD" | base64 | tr -d '\n')
    export SQLD_HTTP_AUTH="basic:$AUTH_STR"
fi

# Ensure data directory is owned by the sqld user
chown -R sqld:sqld /var/lib/sqld

# Drop privileges and start sqld
# Using "$@" allows you to pass extra flags from Railway/Dokploy UI
exec gosu sqld /bin/sqld --db-path /var/lib/sqld/data.sqld "$@"
