# libSQL / Turso-compatible Server for Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/kU5TW-?referralCode=wOLOAa&utm_medium=integration&utm_source=template&utm_campaign=generic)

Host your own **libSQL / Turso (sqld)** instance on Railway. This template provides a Turso-compatible database server that works with the `@libsql/client` SDK and Drizzle ORM, giving you a dedicated SQLite-compatible database with no row limits.

## 🔒 Authentication & Security
This deployment is secured using **HTTP Basic Authentication**. It functions similarly to a standard Postgres or MySQL setup where access is protected by a username and a password.

**Important:** This setup does not use JWT "Auth Tokens." To connect, you include your credentials directly in the connection URL. As long as you use the **HTTPS** URL provided by Railway, your password remains encrypted in transit.

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
| `DB_USER` | `root` | The username for database access (defaults to root). |
| `DB_PASSWORD` | *Required* | Your database password. Use a long, random string. |
| `PORT` | `8080` | The internal port the server listens on. |

### 2. Connecting to your Database
Because this uses Basic Auth, you must include the username and your password in the URL. Most SDKs will automatically handle the "Basic" authorization header when they see this URL format.

**Using `@libsql/client`:**
```typescript
import { createClient } from "@libsql/client";

const client = createClient({
  // Format: https://username:password@host
  url: `https://${process.env.SQLD_USER}:${process.env.SQLD_PASSWORD}@your-project.up.railway.app`,
});
