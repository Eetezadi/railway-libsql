#!/usr/bin/env node

/**
 * JWT Key Generation and Token Creation Utility for libSQL
 *
 * This script generates Ed25519 keypairs for JWT authentication
 * and creates JWT tokens compatible with libSQL/Turso
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Generate Ed25519 keypair
function generateKeypair() {
    const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519', {
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem'
        }
    });

    return { publicKey, privateKey };
}

// Save keys to files
function saveKeys(publicKey, privateKey, outputDir = '.') {
    const publicKeyPath = path.join(outputDir, 'jwt-public.pem');
    const privateKeyPath = path.join(outputDir, 'jwt-private.pem');

    fs.writeFileSync(publicKeyPath, publicKey);
    fs.writeFileSync(privateKeyPath, privateKey);

    console.log('Keys generated successfully!');
    console.log(`Public key saved to: ${publicKeyPath}`);
    console.log(`Private key saved to: ${privateKeyPath}`);

    // Also create a base64 version for easier environment variable usage
    const publicKeyBase64 = Buffer.from(publicKey).toString('base64');
    const envExample = path.join(outputDir, '.env.jwt.example');

    fs.writeFileSync(envExample, `# JWT Authentication Configuration for libSQL

# Public key (for server configuration)
SQLD_AUTH_JWT_KEY="${publicKeyBase64}"

# Private key (keep this secret! Use for generating tokens)
JWT_PRIVATE_KEY="${Buffer.from(privateKey).toString('base64')}"

# Example connection URL format:
# libsql://your-domain:port?authToken=YOUR_JWT_TOKEN
`);

    console.log(`\nEnvironment variable example saved to: ${envExample}`);
}

// Main execution
function main() {
    const args = process.argv.slice(2);
    const outputDir = args[0] || '.';

    // Create output directory if it doesn't exist
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    console.log('Generating Ed25519 keypair for JWT authentication...\n');

    const { publicKey, privateKey } = generateKeypair();
    saveKeys(publicKey, privateKey, outputDir);

    console.log('\n=== Next Steps ===');
    console.log('1. Copy the public key to your libSQL server configuration');
    console.log('2. Use the private key to generate JWT tokens for clients');
    console.log('3. Run: node generate-jwt-token.js to create a JWT token');
}

main();