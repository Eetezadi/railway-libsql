import { defineConfig } from 'drizzle-kit';
import 'dotenv/config';

const dbUser = process.env.DB_USER || 'root';
const dbPassword = process.env.DB_PASSWORD || '';
const dbUrl = process.env.DB_URL || '';

// Encode credentials for HTTP Basic Auth
// Note: drizzle-kit expects JWT tokens, not Basic Auth
// This configuration may not work for migrations with Basic Auth servers
// Use the interactive app or custom migration scripts instead
const credentials = `${dbUser}:${dbPassword}`;
const encodedCredentials = Buffer.from(credentials).toString('base64');

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './src/db/migrations',
  dialect: 'sqlite',
  driver: 'turso',
  dbCredentials: {
    url: dbUrl,
    authToken: encodedCredentials,
  },
});
