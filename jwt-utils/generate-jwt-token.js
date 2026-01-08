#!/usr/bin/env node

/**
 * JWT Token Generator for libSQL/Turso Authentication
 *
 * Creates JWT tokens compatible with libSQL using Ed25519 signatures
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Base64URL encoding (JWT standard)
function base64url(buffer) {
    return buffer.toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}

// Create JWT token
function createJWT(privateKeyPath, options = {}) {
    const {
        permissions = 'rw',  // 'rw' for read-write, 'ro' for read-only
        expiresIn = '30d',   // Default 30 days
        subject = 'user'
    } = options;

    // Read private key
    const privateKeyPem = fs.readFileSync(privateKeyPath, 'utf8');

    // JWT header for Ed25519
    const header = {
        alg: 'EdDSA',
        typ: 'JWT'
    };

    // Calculate expiration time
    const now = Math.floor(Date.now() / 1000);
    let exp;

    if (expiresIn.endsWith('d')) {
        const days = parseInt(expiresIn);
        exp = now + (days * 24 * 60 * 60);
    } else if (expiresIn.endsWith('h')) {
        const hours = parseInt(expiresIn);
        exp = now + (hours * 60 * 60);
    } else if (expiresIn.endsWith('m')) {
        const minutes = parseInt(expiresIn);
        exp = now + (minutes * 60);
    } else {
        exp = now + parseInt(expiresIn); // Assume seconds
    }

    // JWT payload (claims) - libSQL specific structure
    const payload = {
        sub: subject,          // Subject (user identifier)
        iat: now,             // Issued at
        exp: exp,             // Expiration time
        p: permissions        // libSQL permissions: 'rw' or 'ro'
    };

    // Encode header and payload
    const encodedHeader = base64url(Buffer.from(JSON.stringify(header)));
    const encodedPayload = base64url(Buffer.from(JSON.stringify(payload)));

    // Create signature
    const message = `${encodedHeader}.${encodedPayload}`;
    const sign = crypto.createSign('Ed25519');
    sign.update(message);
    const signature = sign.sign(privateKeyPem);

    // Combine to create JWT
    const jwt = `${message}.${base64url(signature)}`;

    return { jwt, exp, payload };
}

// Verify JWT with public key (for testing)
function verifyJWT(jwt, publicKeyPath) {
    try {
        const publicKeyPem = fs.readFileSync(publicKeyPath, 'utf8');
        const [encodedHeader, encodedPayload, encodedSignature] = jwt.split('.');

        const message = `${encodedHeader}.${encodedPayload}`;
        const signature = Buffer.from(encodedSignature, 'base64')
            .toString('base64')
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        const verify = crypto.createVerify('Ed25519');
        verify.update(message);

        const signatureBuffer = Buffer.from(signature, 'base64');
        const isValid = verify.verify(publicKeyPem, signatureBuffer);

        if (isValid) {
            const payload = JSON.parse(Buffer.from(encodedPayload, 'base64').toString());
            return { valid: true, payload };
        }

        return { valid: false };
    } catch (error) {
        return { valid: false, error: error.message };
    }
}

// Main execution
function main() {
    const args = process.argv.slice(2);

    if (args.length === 0 || args.includes('--help')) {
        console.log(`
JWT Token Generator for libSQL

Usage: node generate-jwt-token.js [options]

Options:
  --private-key <path>   Path to private key file (default: ./jwt-private.pem)
  --public-key <path>    Path to public key file for verification (default: ./jwt-public.pem)
  --permissions <p>      Permissions: 'rw' (read-write) or 'ro' (read-only) (default: rw)
  --expires-in <time>    Expiration time: e.g., '30d', '24h', '60m' (default: 30d)
  --subject <sub>        Subject/user identifier (default: user)
  --verify              Verify the generated token
  --help                Show this help message

Examples:
  node generate-jwt-token.js --private-key ./jwt-private.pem
  node generate-jwt-token.js --permissions ro --expires-in 7d
  node generate-jwt-token.js --private-key ./jwt-private.pem --verify
`);
        return;
    }

    // Parse arguments
    const options = {
        privateKeyPath: './jwt-private.pem',
        publicKeyPath: './jwt-public.pem',
        permissions: 'rw',
        expiresIn: '30d',
        subject: 'user',
        verify: false
    };

    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--private-key':
                options.privateKeyPath = args[++i];
                break;
            case '--public-key':
                options.publicKeyPath = args[++i];
                break;
            case '--permissions':
                options.permissions = args[++i];
                break;
            case '--expires-in':
                options.expiresIn = args[++i];
                break;
            case '--subject':
                options.subject = args[++i];
                break;
            case '--verify':
                options.verify = true;
                break;
        }
    }

    // Check if private key exists
    if (!fs.existsSync(options.privateKeyPath)) {
        console.error(`Error: Private key file not found at ${options.privateKeyPath}`);
        console.error('Run: node generate-jwt-keys.js to generate keys first.');
        process.exit(1);
    }

    // Generate JWT
    console.log('Generating JWT token...\n');
    const { jwt, exp, payload } = createJWT(options.privateKeyPath, {
        permissions: options.permissions,
        expiresIn: options.expiresIn,
        subject: options.subject
    });

    console.log('=== JWT Token Generated ===\n');
    console.log('Token:');
    console.log(jwt);
    console.log('\nPayload:');
    console.log(JSON.stringify(payload, null, 2));
    console.log('\nExpires at:', new Date(exp * 1000).toISOString());

    // Verify if requested
    if (options.verify && fs.existsSync(options.publicKeyPath)) {
        console.log('\n=== Verification ===');
        const verification = verifyJWT(jwt, options.publicKeyPath);
        if (verification.valid) {
            console.log('✓ Token is valid!');
        } else {
            console.log('✗ Token verification failed:', verification.error);
        }
    }

    // Connection example
    console.log('\n=== Usage Example ===');
    console.log('Use this token in your connection URL:');
    console.log(`libsql://your-domain:port?authToken=${jwt}`);
    console.log('\nOr in environment variable:');
    console.log(`TURSO_AUTH_TOKEN="${jwt}"`);
}

main();