#!/bin/bash
set -e

DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- INITIALIZING SECURITY KEYS (ES256) ---"
    
    # 1. Generate Private Key (ECDSA P-256)
    # This works on ALL OpenSSL versions
    openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_DIR/libsql.pem"
    
    # 2. Extract Public Key (SubjectPublicKeyInfo format)
    # We strip the "PEM headers" to get the raw key data for the log
    openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -out "$KEY_DIR/libsql_full.pub"
    
    # Formatted specifically for passing to sqld (remove headers/newlines)
    PUB_KEY=$(cat "$KEY_DIR/libsql_full.pub" | grep -v "PUBLIC KEY" | tr -d '\n')
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # 3. Generate JWT
    # Header: {"alg":"ES256","typ":"JWT"} -> eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9
    HEADER="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    
    # 4. SIGNING (Standard SHA256)
    # This is the "bulletproof" method that works everywhere
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    
    JWT="$HEADER.$PAYLOAD.$SIG"

    echo "**************************************************"
    echo "RAILWAY VARIABLE: SQLD_AUTH_JWT_KEY"
    echo "Value: $PUB_KEY"
    echo "--------------------------------------------------"
    echo "DRIZZLE AUTH_TOKEN (Add to your client .env):"
    echo "Value: $JWT"
    echo "**************************************************"
fi

# Set the key for the server
export SQLD_AUTH_JWT_KEY=$(cat "$KEY_DIR/libsql.pub")

chown -R sqld:sqld "$DATA_DIR"

# Start Server
exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@"