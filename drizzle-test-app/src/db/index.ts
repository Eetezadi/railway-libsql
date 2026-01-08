import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';
import * as schema from './schema.js';

export function createDbClient(url: string, username: string, password: string) {
  // Encode credentials for HTTP Basic Auth
  const credentials = `${username}:${password}`;
  const encodedCredentials = Buffer.from(credentials).toString('base64');

  // Create custom fetch that adds Basic Auth header
  // Note: @libsql/client's authToken parameter uses "Bearer" prefix (for JWT tokens)
  // We need "Basic" prefix for HTTP Basic Auth, so we use custom fetch instead
  const authenticatedFetch = (
    input: string | Request | URL,
    init?: RequestInit
  ): Promise<Response> => {
    const headers = new Headers(init?.headers);

    // Set the Basic Auth header (not Bearer!)
    headers.set('Authorization', `Basic ${encodedCredentials}`);

    // Call the native fetch with modified headers
    return fetch(input, {
      ...init,
      headers,
    });
  };

  // Create libSQL client with custom fetch
  const client = createClient({
    url,                          // Plain HTTPS URL without credentials
    fetch: authenticatedFetch,    // Custom fetch adds "Basic" auth header
  });

  return drizzle(client, { schema });
}

export type DbClient = ReturnType<typeof createDbClient>;
export { schema };
