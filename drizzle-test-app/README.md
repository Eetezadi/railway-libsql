# Drizzle ORM + libSQL Test App

An interactive command-line application to test libSQL database connections with HTTP Basic Authentication using Drizzle ORM.

## Features

- Interactive CLI that prompts for database credentials
- Connection validation
- Automatic table creation
- Complete CRUD operations demonstration:
  - Creating users and posts
  - Reading data with filtering
  - Updating records
  - Deleting records
- Colorful terminal output
- Optional cleanup of test data

## Prerequisites

- Node.js 18 or higher
- A running libSQL database (e.g., from the main project or Turso)

## Installation

1. Navigate to the drizzle-test-app directory:
   ```bash
   cd drizzle-test-app
   ```

2. Install dependencies:
   ```bash
   pnpm install
   ```

## Usage

### Interactive Mode (Recommended)

Simply run the application and it will prompt you for credentials:

```bash
pnpm start
```

You'll be asked to enter:
- **Database URL**: Your libSQL database URL without credentials (e.g., `https://your-project.up.railway.app`)
- **Username**: Database username (default: `root`)
- **Password**: Your database password for HTTP Basic Authentication

### Using Environment Variables

Alternatively, you can set up a `.env` file:

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your credentials:
   ```
   DB_URL=https://your-project.up.railway.app
   DB_USER=root
   DB_PASSWORD=your-password-here
   ```

3. Run the app:
   ```bash
   pnpm start
   ```

## Database Connection Formats

### For the Railway libSQL server from the main project:

If you're testing the libSQL server from the parent directory, it uses **HTTP Basic Authentication**:

```
URL: https://your-project.up.railway.app  (use HTTPS, not libsql://)
Username: root  (or the value of DB_USER you set)
Password: your-database-password  (the value of DB_PASSWORD you set)
```

**Important Notes:**
- Use `https://` protocol (HTTPS encrypts credentials in transit)
- Do NOT include username:password in the URL when prompted - enter them separately
- The app uses a custom fetch function to add `Authorization: Basic` headers
- This matches the HTTP Basic Auth setup in the main project's [entrypoint.sh](../entrypoint.sh)
- Note: `@libsql/client`'s `authToken` parameter uses `Bearer` prefix (for JWT), so we use custom fetch for `Basic` auth

### For Turso (Token-based auth):

For Turso databases, you can still use this app, but note that Turso uses JWT tokens:

```
URL: libsql://your-database.turso.io
Username: (leave as default "root")
Password: your-turso-auth-token
```

## What the App Does

1. **Connection Test**: Validates your database credentials
2. **Table Creation**: Creates two example tables:
   - `users`: id, name, email, created_at
   - `posts`: id, title, content, author_id, created_at
3. **CRUD Operations**:
   - Inserts 3 sample users
   - Inserts 3 sample posts
   - Queries all users
   - Filters posts by author
   - Updates a user's name
   - Deletes a post
   - Shows final counts
4. **Cleanup**: Optionally removes test data

## Scripts

- `pnpm start` - Run the interactive application
- `pnpm run dev` - Run with auto-reload on file changes
- `pnpm run build` - Compile TypeScript to JavaScript
- `pnpm run db:push` - Push schema changes to database (Note: May not work with Basic Auth)
- `pnpm run db:studio` - Open Drizzle Studio (Note: May not work with Basic Auth)

## Project Structure

```
drizzle-test-app/
├── src/
│   ├── db/
│   │   ├── schema.ts      # Database schema definitions
│   │   └── index.ts       # Database client setup
│   └── index.ts           # Main application
├── drizzle.config.ts      # Drizzle Kit configuration
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

## Troubleshooting

### Connection Failed

- Verify your database URL is correct (use `https://`, not `libsql://` for HTTP servers)
- Check that your username and password are valid
- Ensure the database server is running
- For Railway deployments, make sure the service is deployed and accessible

### Permission Errors

- Verify your credentials have write permissions
- Check that HTTP Basic Auth is properly configured on the server

### Module Errors

- Make sure you've run `pnpm install`
- Try deleting `node_modules` and `package-lock.json`, then reinstall

## Learn More

- [Drizzle ORM Documentation](https://orm.drizzle.team/)
- [libSQL Documentation](https://github.com/tursodatabase/libsql)
- [Turso Documentation](https://docs.turso.tech/)

## License

MIT
