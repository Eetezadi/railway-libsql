# Deploy and Host Turso / libSQL Database (JWT Auth) on Railway

Host your own **libSQL (sqld)** instance, the open-source heart of **Turso**, directly on Railway. This template provides a SQLite-compatible database server maintaining full compatibility with the libSQL ecosystem and Drizzle ORM.

This deployment is secured using **JWT-based authentication** automatically generated on first deployment. See details below.

## About Hosting Turso / libSQL Database (JWT Auth)

Hosting libSQL on Railway involves deploying a containerized `sqld` server paired with a persistent Railway Volume. This setup is secured via **JWT-based authentication** with Ed25519 signing keys, making it fully compatible with the libSQL SDK and Turso ecosystem. The server automatically generates  a cryptographically secure key pair and a long-lived access token (valid for 10 years) on first deployment.

## Common Use Cases

- **Self-Hosted Turso Alternative**: Get a dedicated database for production apps without usage-based pricing or row caps.
- **Edge-Ready Backend**: Provide a centralized, low-latency SQLite entry point for serverless functions on Vercel or Netlify.
- **Dev/Staging Environments**: Cost-effectively mirror your production Turso architecture for testing and migrations.

## Dependencies for Turso / libSQL Database (JWT Auth) Hosting

- **Railway Volume**: Required to be mounted at `/var/lib/sqld` to persist your SQLite database files.
- **Environment Variables**: The system automatically generates JWT credentials on first deployment. You'll need to copy the `SQLD_AUTH_JWT_KEY` from the deployment logs into your Railway service variables.

### Deployment Dependencies

- [libSQL (sqld) GitHub Repository](https://github.com/tursodatabase/libsql)

### Post-Deployment Setup

After your initial deployment, follow these steps to configure authentication:

**Step 1: Retrieve Credentials from Deployment Logs**

1. Open your Railway project dashboard
2. Click on your libSQL service
3. Navigate to the **Deployments** tab
4. Click on the most recent deployment
5. Scroll through the logs to find the credentials box:

```
################################################################################
###                                                                          ###
###  🔐 libSQL CREDENTIALS - COPY THESE VALUES                              ###
###                                                                          ###
################################################################################

→ RAILWAY VARIABLE (paste in Railway Service Variables):
  SQLD_AUTH_JWT_KEY=<your-public-key-here>

→ CLIENT ENV (paste in your .env file):
  DATABASE_AUTH_TOKEN=<your-jwt-token-here>

ℹ️  Private key was destroyed after signing. To rotate, empty the Railway
   variable SQLD_AUTH_JWT_KEY and redeploy.

################################################################################
```

**Step 2: Configure Railway Service Variable**

1. Go to your libSQL service in Railway
2. Click the **Variables** tab
3. Click **+ New Variable**
4. Add:
   - **Name:** `SQLD_AUTH_JWT_KEY`
   - **Value:** Copy the entire base64 string from the logs after `SQLD_AUTH_JWT_KEY=`
5. Click **Add**
6. Railway will automatically redeploy your service with the new variable

**Step 3: Configure Your Application**

In your application's environment variables (`.env` file or hosting platform):

```env
DATABASE_URL=https://your-service.railway.app
DATABASE_AUTH_TOKEN=<paste-the-jwt-token-from-logs>
```

Replace `your-service.railway.app` with your actual Railway service URL (found in the service **Settings** tab).

**Rotating Credentials:**

To generate new credentials:
1. Delete or clear the `SQLD_AUTH_JWT_KEY` variable in Railway
2. Trigger a new deployment
3. Repeat Steps 1-3 above with the new credentials

## Why Deploy Turso / libSQL Database (JWT Auth) on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Turso / libSQL Database (JWT Auth) on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
