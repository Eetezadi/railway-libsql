#!/bin/bash
set -e

# Configuration
DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

# Ensure directories exist
mkdir -p "$KEY_DIR"

# 1. KEY BOOTSTRAPPING
# Only generate if the private key doesn't exist in the volume
if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- INITIALIZING SECURITY KEYS ---"
    
    # Generate Ed25519 Private Key
    openssl genpkey -algorithm Ed25519 -out "$KEY_DIR/libsql.pem"
    
    # Extract Public Key (formatted for libSQL)
    PUB_KEY=$(openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -outform DER | tail -c 32 | base64 | tr '+/' '-_' | tr -d '=')
    echo "$PUB_KEY" > "$KEY_DIR/libsql.pub"
    
    # 2. GENERATE THE JWT (The "Auth Token")
    # Header & Payload (a:rw = access: read-write)
    HEADER="eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9"
    PAYLOAD="eyJhIjoicncifQ" 
    
    # Sign the token
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl pkeyutl -sign -inkey "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    JWT="$HEADER.$PAYLOAD.$SIG"

    echo "**************************************************"
    echo "RAILWAY VARIABLE: SQLD_AUTH_JWT_KEY"
    echo "Value: $PUB_KEY"
    echo "--------------------------------------------------"
    echo "DRIZZLE AUTH_TOKEN (Add to your client .env):"
    echo "Value: $JWT"
    echo "**************************************************"
fi

# 3. SET SERVER VARS
# Set the server to require the public key we just confirmed exists
export SQLD_AUTH_JWT_KEY=$(cat "$KEY_DIR/libsql.pub")

# Ensure data directory is owned by the sqld user
chown -R sqld:sqld "$DATA_DIR"

# 4. START SERVER
# We remove Basic Auth logic in favor of JWT
exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@"