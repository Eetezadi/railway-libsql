import { createInterface } from 'readline/promises';
import { stdin as input, stdout as output } from 'process';
import { eq, sql } from 'drizzle-orm';
import { createDbClient, type DbClient } from './db/index.js';
import { users, posts } from './db/schema.js';

const rl = createInterface({ input, output });

// ANSI color codes for better output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testConnection(url: string, username: string, password: string) {
  log('\n📡 Testing database connection...', 'cyan');

  try {
    const db = createDbClient(url, username, password);

    // Test connection with a simple query
    await db.run(sql`SELECT 1`);

    log('✓ Connection successful!', 'green');
    return db;
  } catch (error) {
    log('✗ Connection failed!', 'red');
    if (error instanceof Error) {
      log(`Error: ${error.message}`, 'red');
    }
    throw error;
  }
}

async function createTables(db: DbClient) {
  log('\n📦 Creating tables...', 'cyan');

  try {
    // Create users table
    await db.run(sql`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL
      )
    `);

    // Create posts table
    await db.run(sql`
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        author_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    log('✓ Tables created successfully!', 'green');
  } catch (error) {
    log('✗ Failed to create tables!', 'red');
    if (error instanceof Error) {
      log(`Error: ${error.message}`, 'red');
    }
    throw error;
  }
}

async function performCrudOperations(db: DbClient) {
  log('\n🔨 Performing CRUD operations...', 'cyan');

  try {
    // CREATE - Insert users
    log('\n1️⃣  Inserting users...', 'yellow');
    const insertedUsers = await db.insert(users).values([
      { name: 'Alice Smith', email: 'alice@example.com' },
      { name: 'Bob Johnson', email: 'bob@example.com' },
      { name: 'Charlie Brown', email: 'charlie@example.com' },
    ]).returning();

    log(`   ✓ Inserted ${insertedUsers.length} users`, 'green');
    insertedUsers.forEach(user => {
      log(`     - ${user.name} (${user.email})`, 'blue');
    });

    // CREATE - Insert posts
    log('\n2️⃣  Inserting posts...', 'yellow');
    const insertedPosts = await db.insert(posts).values([
      {
        title: 'First Post',
        content: 'This is Alice\'s first post!',
        authorId: insertedUsers[0].id,
      },
      {
        title: 'Hello World',
        content: 'Bob says hello to the world!',
        authorId: insertedUsers[1].id,
      },
      {
        title: 'Testing libSQL',
        content: 'Charlie is testing the database.',
        authorId: insertedUsers[2].id,
      },
    ]).returning();

    log(`   ✓ Inserted ${insertedPosts.length} posts`, 'green');
    insertedPosts.forEach(post => {
      log(`     - "${post.title}" by user #${post.authorId}`, 'blue');
    });

    // READ - Query all users
    log('\n3️⃣  Reading all users...', 'yellow');
    const allUsers = await db.select().from(users);
    log(`   ✓ Found ${allUsers.length} users:`, 'green');
    allUsers.forEach(user => {
      log(`     - ID: ${user.id}, Name: ${user.name}, Email: ${user.email}`, 'blue');
    });

    // READ - Query posts with filtering
    log('\n4️⃣  Reading posts by Alice...', 'yellow');
    const alicePosts = await db
      .select()
      .from(posts)
      .where(eq(posts.authorId, insertedUsers[0].id));

    log(`   ✓ Found ${alicePosts.length} post(s):`, 'green');
    alicePosts.forEach(post => {
      log(`     - "${post.title}": ${post.content}`, 'blue');
    });

    // UPDATE - Update a user
    log('\n5️⃣  Updating Bob\'s name...', 'yellow');
    const updatedUser = await db
      .update(users)
      .set({ name: 'Robert Johnson' })
      .where(eq(users.id, insertedUsers[1].id))
      .returning();

    log(`   ✓ Updated user: ${updatedUser[0].name}`, 'green');

    // DELETE - Delete a post
    log('\n6️⃣  Deleting Charlie\'s post...', 'yellow');
    await db
      .delete(posts)
      .where(eq(posts.id, insertedPosts[2].id));

    log('   ✓ Post deleted successfully', 'green');

    // Final count
    log('\n7️⃣  Final counts...', 'yellow');
    const finalUsers = await db.select().from(users);
    const finalPosts = await db.select().from(posts);
    log(`   ✓ Total users: ${finalUsers.length}`, 'green');
    log(`   ✓ Total posts: ${finalPosts.length}`, 'green');

    log('\n✨ All CRUD operations completed successfully!', 'bright');

  } catch (error) {
    log('✗ CRUD operations failed!', 'red');
    if (error instanceof Error) {
      log(`Error: ${error.message}`, 'red');
    }
    throw error;
  }
}

async function cleanup(db: DbClient) {
  const shouldCleanup = await rl.question('\n🧹 Clean up test data? (y/N): ');

  if (shouldCleanup.toLowerCase() === 'y') {
    log('\n🧹 Cleaning up...', 'cyan');
    await db.delete(posts);
    await db.delete(users);
    log('✓ Test data cleaned up!', 'green');
  } else {
    log('\n✓ Test data preserved in database', 'yellow');
  }
}

async function main() {
  log('╔════════════════════════════════════════╗', 'bright');
  log('║  Drizzle ORM + libSQL Test App        ║', 'bright');
  log('╚════════════════════════════════════════╝', 'bright');

  try {
    // Get database credentials
    log('\n📝 Please enter your database credentials:', 'cyan');
    log('   (This server uses HTTP Basic Authentication)', 'blue');

    log('\n   Database URL (without credentials):', 'blue');
    log('   Format: https://your-project.up.railway.app', 'blue');
    const url = await rl.question('Database URL: ');

    log('\n   Username (default is usually "root"):', 'blue');
    const username = await rl.question('Username [root]: ') || 'root';

    log('\n   Password:', 'blue');
    const password = await rl.question('Password: ');

    if (!url || !password) {
      log('\n✗ URL and password are required!', 'red');
      process.exit(1);
    }

    // Test connection
    const db = await testConnection(url, username, password);

    // Create tables
    await createTables(db);

    // Perform CRUD operations
    await performCrudOperations(db);

    // Optional cleanup
    await cleanup(db);

    log('\n✅ Test completed successfully!', 'green');

  } catch (error) {
    log('\n❌ Test failed!', 'red');
    if (error instanceof Error) {
      log(`Error: ${error.message}`, 'red');
    }
    process.exit(1);
  } finally {
    rl.close();
  }
}

main();
