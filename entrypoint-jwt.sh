#!/bin/bash
set -e

# Bind to Railway's assigned port or default to 8080
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# JWT Authentication Configuration
# The public key can be provided either as:
# 1. SQLD_AUTH_JWT_KEY - Base64 encoded public key (environment variable)
# 2. SQLD_AUTH_JWT_KEY_FILE - Path to public key file
# 3. Falls back to basic auth if JWT is not configured

AUTH_ARGS=""

if [ -n "$SQLD_AUTH_JWT_KEY" ]; then
    echo "Configuring JWT authentication..."

    # Decode base64 public key and save to file
    echo "$SQLD_AUTH_JWT_KEY" | base64 -d > /etc/sqld/jwt-public.pem
    chmod 600 /etc/sqld/jwt-public.pem
    chown sqld:sqld /etc/sqld/jwt-public.pem

    AUTH_ARGS="--auth-jwt-key-file /etc/sqld/jwt-public.pem"

    echo "JWT authentication enabled. Connect using JWT token in authToken parameter."

elif [ -n "$SQLD_AUTH_JWT_KEY_FILE" ]; then
    echo "Using JWT key file: $SQLD_AUTH_JWT_KEY_FILE"
    AUTH_ARGS="--auth-jwt-key-file $SQLD_AUTH_JWT_KEY_FILE"

elif [ -n "$DB_PASSWORD" ]; then
    echo "Falling back to basic authentication..."

    # Basic authentication configuration (backward compatibility)
    DB_USER=${DB_USER:-root}
    AUTH_STR=$(echo -n "$DB_USER:$DB_PASSWORD" | base64 | tr -d '\n')
    export SQLD_HTTP_AUTH="basic:$AUTH_STR"

    echo "Basic authentication enabled. Use username/password for connection."
else
    echo "WARNING: No authentication configured! Database is unprotected."
fi

# Ensure data directory is owned by the sqld user
chown -R sqld:sqld /var/lib/sqld

# Additional configuration options
EXTRA_ARGS=""

# Enable WAL mode if specified
if [ "$ENABLE_WAL" = "true" ]; then
    EXTRA_ARGS="$EXTRA_ARGS --enable-wal"
fi

# Set max database size if specified
if [ -n "$MAX_DB_SIZE" ]; then
    EXTRA_ARGS="$EXTRA_ARGS --max-db-size $MAX_DB_SIZE"
fi

# Drop privileges and start sqld
echo "Starting libSQL server..."
echo "Listen address: $SQLD_HTTP_LISTEN_ADDR"

# Using "$@" allows you to pass extra flags from Docker run command
exec gosu sqld /bin/sqld \
    --db-path /var/lib/sqld/data.sqld \
    $AUTH_ARGS \
    $EXTRA_ARGS \
    "$@"