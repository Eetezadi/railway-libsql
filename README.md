# libSQL / Turso-compatible Server for Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/kU5TW-?referralCode=wOLOAa&utm_medium=integration&utm_source=template&utm_campaign=generic)

Host your own **libSQL / Turso (sqld)** instance on Railway. This template provides a Turso-compatible database server that works with the `@libsql/client` SDK and Drizzle ORM, giving you a dedicated SQLite-compatible database with no row limits.

## 🔒 Authentication & Security
This deployment is secured using **HTTP Basic Authentication**. It functions similarly to a standard Postgres or MySQL setup where access is protected by a username and a password.

**Important:** This setup does not use JWT "Auth Tokens." Most libSQL SDKs expect a JWT when using the `authToken` property. To connect successfully, you must either include credentials in the URL or use a custom fetch wrapper (see Drizzle example below).

## About libSQL on Railway
libSQL is the open-source fork of SQLite designed for modern web applications. 

- ⚡ **Turso Compatible**: Swap your Turso URL for this Railway URL in your app code.
- 🗄️ **Persistent SQLite**: Uses Railway Volumes to ensure your data survives restarts.
- 🔄 **Hrana Protocol**: Supports high-speed pipelined queries over WebSockets and HTTP.
- 🛠️ **ORM Ready**: Works out of the box with Drizzle, Prisma, and the libSQL SDK.

## Post-Installation Setup

### 1. Environment Variables
Ensure these are configured in your Railway project settings:

| Variable | Default | Description |
|----------|---------|-------------|
| `SQLD_USER` | `root` | The username for database access (defaults to root). |
| `SQLD_PASSWORD` | *Required* | Your database password. Use a long, random string. |
| `PORT` | `8080` | The internal port the server listens on. |

### 2. Connecting to your Database
Because this uses Basic Auth, you must include the username and your password in the URL.

#### Connecting with Drizzle ("Basic Auth" Fix)
Since `@libsql/client` expects a `Bearer` token by default, use a custom fetch wrapper to inject the `Basic` Auth header required by this server:

##### Configure the Client (`db/index.ts`)
The @libsql/client SDK defaults to Bearer (JWT) when using the authToken parameter. To support the Basic Auth required by this server, use this custom fetch wrapper:
```typescript
import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';
import * as schema from './schema';

export function createDbClient(url: string, username: string, password: string) {
  // 1. Encode credentials for HTTP Basic Auth
  const credentials = Buffer.from(`${username}:${password}`).toString('base64');

  // 2. Create custom fetch to force "Basic" instead of "Bearer"
  const authenticatedFetch = (input: string | Request | URL, init?: RequestInit) => {
    const headers = new Headers(init?.headers);
    headers.set('Authorization', `Basic ${credentials}`);
    return fetch(input, { ...init, headers });
  };

  // 3. Initialize libSQL with the custom fetcher
  const client = createClient({
    url,
    fetch: authenticatedFetch,
  });

  return drizzle(client, { schema });
}
```
##### Usage in App
```typescript
import { createDbClient } from './db';

const db = createDbClient(
  process.env.DATABASE_URL!, 
  process.env.DB_USER!, 
  process.env.DB_PASSWORD!
);

// Now you can run migrations or queries
// await db.select().from(schema.users);
