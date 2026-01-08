import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';
import * as schema from './schema';

// Create libSQL client with JWT authentication
const client = createClient({
    url: process.env.DATABASE_URL!, // e.g., 'http://localhost:8080' or 'libsql://your-domain.railway.app'
    authToken: process.env.DATABASE_AUTH_TOKEN!, // Your JWT token
});

// Create Drizzle ORM instance
export const db = drizzle(client, { schema });

// Test connection function
export async function testConnection() {
    try {
        const result = await client.execute('SELECT 1');
        console.log('Database connection successful!');
        return true;
    } catch (error) {
        console.error('Database connection failed:', error);
        return false;
    }
}