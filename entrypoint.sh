#!/bin/bash
set -e

export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# Generate JWT keys if SQLD_AUTH_JWT_KEY is not set
if [ -z "$SQLD_AUTH_JWT_KEY" ]; then
    /usr/local/bin/token-gen
fi

# Ensure data directory is owned by the sqld user (for Railway volumes)
chown -R sqld:sqld /var/lib/sqld

# Drop privileges and start sqld
exec gosu sqld /bin/sqld --db-path /var/lib/sqld/data.sqld "$@"
