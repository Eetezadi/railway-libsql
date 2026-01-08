# LibSQL JWT Authentication Setup

This guide explains how to configure libSQL with JWT authentication to replace Turso and work seamlessly with Drizzle ORM and other SDKs.

## Overview

LibSQL (sqld) supports JWT authentication natively, which is the same authentication method used by Turso. This setup allows you to:

- Use JWT tokens for secure authentication
- Work with any libSQL-compatible SDK (Drizzle, Prisma, etc.)
- Deploy on Railway, Docker, or any container platform
- Maintain compatibility with Turso's authentication model

## Quick Start

### 1. Generate JWT Keys

```bash
cd jwt-utils
npm install  # Only needed for the first time
node generate-jwt-keys.js
```

This creates:
- `jwt-public.pem` - Public key for server configuration
- `jwt-private.pem` - Private key for generating tokens (keep secure!)
- `.env.jwt.example` - Example environment variables

### 2. Generate JWT Tokens

```bash
cd jwt-utils
node generate-jwt-token.js --private-key ./jwt-private.pem --permissions rw --expires-in 30d
```

Options:
- `--permissions`: `rw` (read-write) or `ro` (read-only)
- `--expires-in`: Token expiration (e.g., `30d`, `24h`, `60m`)
- `--subject`: User identifier (default: `user`)

### 3. Deploy with Docker

#### Local Development

```bash
# Set environment variables
export SQLD_AUTH_JWT_KEY="<base64-encoded-public-key-from-.env.jwt.example>"
export DATABASE_AUTH_TOKEN="<generated-jwt-token>"

# Start the server
docker-compose -f docker-compose.jwt.yml up -d libsql-jwt

# Test with dev container (optional)
docker-compose -f docker-compose.jwt.yml --profile dev up dev-test
```

#### Production (Railway)

1. Build and push the Docker image:
```bash
docker build -f Dockerfile.jwt -t libsql-jwt .
```

2. Set Railway environment variables:
```env
SQLD_AUTH_JWT_KEY=<base64-encoded-public-key>
PORT=8080
ENABLE_WAL=true
MAX_DB_SIZE=10GB
```

3. Deploy to Railway using the custom Docker image.

## Using with Drizzle ORM

### Configuration

1. Install dependencies:
```bash
npm install @libsql/client drizzle-orm
npm install -D drizzle-kit
```

2. Create `.env` file:
```env
DATABASE_URL=http://localhost:8080  # or your Railway URL
DATABASE_AUTH_TOKEN=<your-jwt-token>
```

3. Configure Drizzle (`drizzle.config.ts`):
```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
    dialect: 'turso',
    schema: './src/schema.ts',
    dbCredentials: {
        url: process.env.DATABASE_URL,
        authToken: process.env.DATABASE_AUTH_TOKEN,
    },
});
```

4. Use in your application:
```typescript
import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';

const client = createClient({
    url: process.env.DATABASE_URL!,
    authToken: process.env.DATABASE_AUTH_TOKEN!,
});

export const db = drizzle(client);
```

## How It Works

### JWT Authentication Flow

1. **Key Generation**: Ed25519 keypair is generated
2. **Server Configuration**: Public key is provided to libSQL via `SQLD_AUTH_JWT_KEY`
3. **Token Creation**: JWT tokens are signed with the private key
4. **Client Connection**: Clients include the JWT token in the connection URL or headers
5. **Verification**: libSQL verifies the token using the public key

### JWT Token Structure

```json
{
  "alg": "EdDSA",
  "typ": "JWT"
}
{
  "sub": "user",       // Subject/user identifier
  "iat": 1704067200,   // Issued at timestamp
  "exp": 1706659200,   // Expiration timestamp
  "p": "rw"            // Permissions: 'rw' or 'ro'
}
```

## Environment Variables

### Server-side (libSQL/sqld)

| Variable | Description | Example |
|----------|-------------|---------|
| `SQLD_AUTH_JWT_KEY` | Base64-encoded public key | `LS0tLS1CRUdJTi...` |
| `SQLD_AUTH_JWT_KEY_FILE` | Path to public key file | `/etc/sqld/jwt-public.pem` |
| `PORT` | HTTP listen port | `8080` |
| `ENABLE_WAL` | Enable Write-Ahead Logging | `true` |
| `MAX_DB_SIZE` | Maximum database size | `10GB` |

### Client-side (Application)

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | LibSQL server URL | `http://localhost:8080` |
| `DATABASE_AUTH_TOKEN` | JWT authentication token | `eyJhbGc...` |

## Security Best Practices

1. **Keep Private Keys Secure**
   - Never commit private keys to version control
   - Store in secure secret management systems
   - Rotate keys periodically

2. **Token Management**
   - Use appropriate expiration times
   - Implement token refresh mechanisms
   - Use read-only tokens where write access isn't needed

3. **Network Security**
   - Use HTTPS in production
   - Implement IP whitelisting if possible
   - Monitor for unauthorized access attempts

## Migration from Basic Auth

If you're currently using basic authentication, you can migrate to JWT:

1. Generate JWT keys and tokens
2. Update your Docker configuration to use `Dockerfile.jwt` and `entrypoint-jwt.sh`
3. Replace username/password with JWT token in your application
4. The server supports both authentication methods during transition

## Compatibility

This JWT authentication setup is compatible with:

- **Drizzle ORM**: Full support via `@libsql/client`
- **Prisma**: Via the `@prisma/adapter-libsql` adapter
- **Turso SDK**: Direct drop-in replacement
- **Any libSQL client**: Standard JWT authentication

## Troubleshooting

### Invalid JWT Token Error

```
Error: The JWT is invalid
```

**Solution**: Ensure the public key on the server matches the private key used to generate the token.

### Connection Refused

**Solution**: Check that:
- The server is running on the correct port
- Firewall rules allow the connection
- The DATABASE_URL is correct

### Permission Denied

**Solution**: Verify the token has the correct permissions (`rw` for writes, `ro` for reads only).

## Example Files

All example files are provided in this repository:

- `jwt-utils/` - JWT key generation and token creation scripts
- `Dockerfile.jwt` - Docker configuration with JWT support
- `entrypoint-jwt.sh` - Entrypoint script with JWT configuration
- `docker-compose.jwt.yml` - Docker Compose for local development
- `drizzle-jwt-example/` - Complete Drizzle ORM example with JWT

## Advanced Configuration

### Custom Token Claims

You can extend the JWT payload with custom claims by modifying the token generation script:

```javascript
const payload = {
    sub: subject,
    iat: now,
    exp: exp,
    p: permissions,
    // Add custom claims
    role: 'admin',
    team: 'engineering'
};
```

### Multiple Users

Generate different tokens for different users with varying permissions:

```bash
# Admin user with full access
node generate-jwt-token.js --subject admin --permissions rw --expires-in 90d

# Read-only user for analytics
node generate-jwt-token.js --subject analytics --permissions ro --expires-in 7d
```

## Resources

- [LibSQL Documentation](https://github.com/libsql/libsql)
- [Drizzle ORM LibSQL Guide](https://orm.drizzle.team/docs/get-started-sqlite#turso)
- [JWT.io - JWT Debugger](https://jwt.io)
- [Railway Deployment Guide](https://railway.app/template/libsql-jwt-auth)