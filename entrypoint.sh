#!/bin/bash
set -e

DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- INITIALIZING ES256 SECURITY KEYS ---"
    
    # 1. Generate Private Key (ECDSA P-256)
    openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_DIR/libsql.pem"
    
    # 2. Extract Public Key and format it correctly
    openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -out "$KEY_DIR/libsql_full.pub"
    
    # Convert to URL-safe Base64 and add the 'es256:' prefix
    # This prefix tells sqld NOT to treat it as Ed25519
    RAW_PUB=$(cat "$KEY_DIR/libsql_full.pub" | grep -v "PUBLIC KEY" | tr -d '\n' | tr '+/' '-_')
    PUB_KEY="es256:$RAW_PUB"
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # 3. Build the JWT
    HEADER="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    
    # 4. Sign the JWT (Standard ES256)
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    
    JWT="$HEADER.$PAYLOAD.$SIG"

    echo "**************************************************"
    echo "UPDATE RAILWAY VARIABLE: SQLD_AUTH_JWT_KEY"
    echo "Value: $PUB_KEY"
    echo "--------------------------------------------------"
    echo "DRIZZLE AUTH_TOKEN (Add to your client .env):"
    echo "Value: $JWT"
    echo "**************************************************"
fi

# Load the key with the es256: prefix
export SQLD_AUTH_JWT_KEY=$(cat "$KEY_DIR/libsql.pub")

chown -R sqld:sqld "$DATA_DIR"

exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@"