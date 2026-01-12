# libSQL / Turso-compatible Server for Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/turso-libsql-database-basic-auth?referralCode=wOLOAa&utm_medium=integration&utm_source=template&utm_campaign=generic)

Host your own **libSQL / Turso (sqld)** instance on Railway. This template provides a Turso-compatible database server that works with the `@libsql/client` SDK and Drizzle ORM, giving you a dedicated SQLite-compatible database with no row limits.

## 🔒 Authentication & Security
This deployment is secured using **JWT-based authentication** with Ed25519 signing keys. On first deployment, the system automatically generates a cryptographically secure key pair and a long-lived access token (valid for 10 years).

**How it works:** The server generates credentials on startup if none are configured. You'll copy these values from the deployment logs into your Railway service variables and your application's environment variables.

## About libSQL on Railway
libSQL is the open-source fork of SQLite designed for modern web applications. 

- ⚡ **Turso Compatible**: Swap your Turso URL for this Railway URL in your app code.
- 🗄️ **Persistent SQLite**: Uses Railway Volumes to ensure your data survives restarts.
- 🔄 **Hrana Protocol**: Supports high-speed pipelined queries over WebSockets and HTTP.
- 🛠️ **ORM Ready**: Works out of the box with Drizzle, Prisma, and the libSQL SDK.

## Post-Installation Setup

### Step 1: Deploy to Railway
Click the "Deploy on Railway" button at the top of this README. Railway will create a new service for you.

### Step 2: Get Your Credentials from the Logs
After deployment completes, you need to retrieve the auto-generated credentials:

1. Open your Railway project dashboard
2. Click on your libSQL service
3. Go to the **Deployments** tab
4. Click on the most recent deployment
5. Scroll through the deployment logs until you see a box that looks like this:

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

### Step 3: Configure Railway Environment Variable
Now you need to add the public key to your Railway service so the server can verify tokens:

1. In Railway, go to your libSQL service
2. Click the **Variables** tab
3. Click **+ New Variable**
4. Create a new variable:
   - **Name:** `SQLD_AUTH_JWT_KEY`
   - **Value:** Copy the entire value after `SQLD_AUTH_JWT_KEY=` from the logs (the long base64 string)
5. Click **Add** to save
6. The service will automatically redeploy with the new variable

**Why this step?** This tells the server which public key to use for verifying JWT tokens. Without this variable set, the server generates new credentials on every restart.

### Step 4: Configure Your Application
In your application's `.env` file (or environment variables), add these two values:

```env
DATABASE_URL=https://your-service.railway.app
DATABASE_AUTH_TOKEN=<paste-the-jwt-token-from-logs>
```

Replace:
- `your-service.railway.app` with your actual Railway service URL (found in the Settings tab)
- `<paste-the-jwt-token-from-logs>` with the token value from the deployment logs

### Step 5: Rotating Credentials

If you need to generate new credentials (e.g., token was compromised or expired):

1. Go to your Railway service's **Variables** tab
2. Find the `SQLD_AUTH_JWT_KEY` variable
3. **Delete** the variable (or clear its value)
4. Go to the **Deployments** tab and trigger a new deployment
5. Check the deployment logs for the new credentials box
6. Follow Steps 3-4 above to configure the new values

**Important:** After rotation, update the `DATABASE_AUTH_TOKEN` in all applications that connect to this database.

## 💾 Bottomless Backup Configuration (Optional)

libSQL supports **bottomless replication**, which automatically backs up your database to S3-compatible storage. This provides point-in-time recovery and protects against data loss.

### What Gets Backed Up?

- **Continuous replication**: Every write to the database is replicated to S3
- **Point-in-time recovery**: Restore your database to any point in time
- **Automatic snapshots**: Periodic full snapshots for faster recovery
- **Transaction log backup**: All database changes are preserved

### Setting Up Bottomless Backup

To enable bottomless backup, you'll need an S3-compatible storage service (AWS S3, Railway Buckets, Cloudflare R2 etc.) and add the following environment variables to your Railway service:

```env
SQLD_ENABLE_BOTTOMLESS_REPLICATION="true"
LIBSQL_BOTTOMLESS_BUCKET="your-bucket-name"
LIBSQL_BOTTOMLESS_ENDPOINT="https://your-s3-endpoint.com"
LIBSQL_BOTTOMLESS_AWS_ACCESS_KEY_ID="your-access-key-id"
LIBSQL_BOTTOMLESS_AWS_SECRET_ACCESS_KEY="your-secret-access-key"
LIBSQL_BOTTOMLESS_AWS_DEFAULT_REGION="auto"
```

If you're using Railway's bucket, you can use the `Add to Service` and select `Custom`. Then rename the variable as in the example below:

```env
SQLD_ENABLE_BOTTOMLESS_REPLICATION="true"
LIBSQL_BOTTOMLESS_BUCKET="${{service.BUCKET}}"
LIBSQL_BOTTOMLESS_ENDPOINT="${{service.ENDPOINT}}"
LIBSQL_BOTTOMLESS_AWS_ACCESS_KEY_ID="${{service.ACCESS_KEY_ID}}"
LIBSQL_BOTTOMLESS_AWS_SECRET_ACCESS_KEY="${{service.SECRET_ACCESS_KEY}}"
LIBSQL_BOTTOMLESS_AWS_DEFAULT_REGION="${{service.REGION}}"
```
