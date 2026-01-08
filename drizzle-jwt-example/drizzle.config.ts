import { defineConfig } from 'drizzle-kit';
import * as dotenv from 'dotenv';

dotenv.config();

if (!process.env.DATABASE_URL || !process.env.DATABASE_AUTH_TOKEN) {
    throw new Error('DATABASE_URL and DATABASE_AUTH_TOKEN must be set');
}

export default defineConfig({
    dialect: 'turso', // Use turso dialect for libSQL
    schema: './src/schema.ts',
    out: './drizzle',
    dbCredentials: {
        url: process.env.DATABASE_URL,
        authToken: process.env.DATABASE_AUTH_TOKEN,
    },
    verbose: true,
    strict: true,
});