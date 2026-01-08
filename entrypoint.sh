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
    # We extract the raw 32 bytes from the DER output
    PUB_KEY=$(openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -outform DER | tail -c 32 | base64 | tr '+/' '-_' | tr -d '=')
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # 3. Generate JWT
    HEADER="eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    
    # 4. SIGNING (Fixed version using dgst)
    # Ed25519 in dgst doesn't need a digest name (like -sha256) specified.
    # It automatically handles the "PureEdDSA" logic.
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sign "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    
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

# Ensure the directory belongs to sqld user before starting
chown -R sqld:sqld "$DATA_DIR"

# Start the server
exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@"