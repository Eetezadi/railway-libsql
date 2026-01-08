#!/bin/bash
set -e

DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- INITIALIZING SECURITY KEYS ---"
    
    # 1. Generate Private Key
    openssl genpkey -algorithm Ed25519 -out "$KEY_DIR/libsql.pem"
    
    # 2. Extract Public Key (URL-safe Base64)
    # We take the raw 32-byte public key from the DER output
    PUB_KEY=$(openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -outform DER | tail -c 32 | base64 | tr '+/' '-_' | tr -d '=')
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # 3. Generate JWT
    # Header & Payload are static for "read-write" access
    HEADER="eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    
    # FIXED SIGNING COMMAND: 
    # Added '-rawin' and ensured input is passed correctly for Ed25519
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl pkeyutl -sign -inkey "$KEY_DIR/libsql.pem" -rawin | base64 | tr '+/' '-_' | tr -d '=')
    
    JWT="$HEADER.$PAYLOAD.$SIG"

    echo "**************************************************"
    echo "RAILWAY VARIABLE: SQLD_AUTH_JWT_KEY"
    echo "Value: $PUB_KEY"
    echo "--------------------------------------------------"
    echo "DRIZZLE AUTH_TOKEN (Add to your client .env):"
    echo "Value: $JWT"
    echo "**************************************************"
fi

export SQLD_AUTH_JWT_KEY=$(cat "$KEY_DIR/libsql.pub")
chown -R sqld:sqld "$DATA_DIR"

exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@"