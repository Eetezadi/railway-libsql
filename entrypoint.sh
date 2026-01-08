#!/bin/bash
set -e

DATA_DIR="/var/lib/sqld"
KEY_DIR="$DATA_DIR/keys"
export SQLD_HTTP_LISTEN_ADDR="0.0.0.0:${PORT:-8080}"

mkdir -p "$KEY_DIR"

# Only generate keys if they don't exist
if [ ! -f "$KEY_DIR/libsql.pem" ]; then
    echo "--- GENERATING SECURE KEYS ---"
    
    # 1. Generate Private Key
    openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_DIR/libsql.pem"
    
    # 2. Generate Public Key
    openssl pkey -in "$KEY_DIR/libsql.pem" -pubout -out "$KEY_DIR/libsql_full.pub"
    
    # 3. Process to Raw URL-Safe Base64 AND REMOVE PADDING
    # We strip the header, swap chars to URL-safe, and delete '='
    RAW_PUB=$(cat "$KEY_DIR/libsql_full.pub" | grep -v "PUBLIC KEY" | tr -d '\n' | tr '+/' '-_' | tr -d '=')
    
    # 4. Save Raw Key for the Server
    echo "$RAW_PUB" > "$KEY_DIR/libsql.pub"
    
    # 5. Generate JWT for the App
    HEADER="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9" # {"alg":"ES256","typ":"JWT"}
    PAYLOAD="eyJhIjoicncifQ" # {"a":"rw"}
    SIG=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$KEY_DIR/libsql.pem" | base64 | tr '+/' '-_' | tr -d '=')
    JWT="$HEADER.$PAYLOAD.$SIG"

    # 6. Print Credentials (ONLY ONCE)
    echo "**************************************************"
    echo "   CREDENTIALS GENERATED (Save these now!)"
    echo "**************************************************"
    echo ""
    echo "1. RAILWAY VARIABLE (SQLD_AUTH_JWT_KEY):"
    echo "es256:$RAW_PUB"
    echo ""
    echo "2. APPLICATION VARIABLE (TURSO_AUTH_TOKEN):"
    echo "$JWT"
    echo ""
    echo "**************************************************"
fi

# Determine which key to use
# If the user has set the variable in Railway (and it's not "temp"), use it.
# Otherwise, load from file to prevent crashes during bootstrap.
if [[ -z "$SQLD_AUTH_JWT_KEY" || "$SQLD_AUTH_JWT_KEY" == "temp" ]]; then
    if [ -f "$KEY_DIR/libsql.pub" ]; then
        # Load from file and prepend prefix
        RAW_KEY=$(cat "$KEY_DIR/libsql.pub")
        export SQLD_AUTH_JWT_KEY="es256:$RAW_KEY"
    fi
fi

chown -R sqld:sqld "$DATA_DIR"

echo "Starting libSQL..."
exec gosu sqld /bin/sqld --db-path "$DATA_DIR/data.sqld" "$@" || (echo "Crashed. Sleeping..." && sleep 60)