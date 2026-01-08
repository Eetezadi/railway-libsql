#!/bin/bash
set -e

DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- GENERATING SECURE KEYS ---"
    openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_DIR/libsql.pem"
    openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -out "$KEY_DIR/libsql_full.pub"
    
    # Create URL-safe public key with prefix
    RAW_PUB=$(cat "$KEY_DIR/libsql_full.pub" | grep -v "PUBLIC KEY" | tr -d '\n' | tr '+/' '-_')
    PUB_KEY="es256:$RAW_PUB"
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # Create JWT
    HEADER="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    JWT="$HEADER.$PAYLOAD.$SIG"

    echo "**************************************************"
    echo "COPY THIS TO RAILWAY SQLD_AUTH_JWT_KEY:"
    echo "$PUB_KEY"
    echo ""
    echo "COPY THIS TO YOUR APP .env (TURSO_AUTH_TOKEN):"
    echo "$JWT"
    echo "**************************************************"
fi

export SQLD_AUTH_JWT_KEY=$(cat "$KEY_DIR/libsql.pub")
chown -R sqld:sqld "$DATA_DIR"

echo "Starting libSQL..."
# If it fails, we sleep so you can read the logs
exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@" || (echo "Server crashed! Keeping logs alive for 60s..."; sleep 60)