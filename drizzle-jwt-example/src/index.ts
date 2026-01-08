import { db, testConnection } from './db';
import { users, posts, products, type NewUser, type NewPost, type NewProduct } from './schema';
import { eq, desc, sql } from 'drizzle-orm';

async function main() {
    console.log('Testing libSQL connection with JWT authentication...\n');

    // Test connection
    const connected = await testConnection();
    if (!connected) {
        process.exit(1);
    }

    console.log('\n=== Running Drizzle ORM Examples ===\n');

    try {
        // 1. Insert a new user
        console.log('1. Creating a new user...');
        const newUser: NewUser = {
            name: 'John Doe',
            email: 'john@example.com',
        };

        const [insertedUser] = await db.insert(users).values(newUser).returning();
        console.log('User created:', insertedUser);

        // 2. Query users
        console.log('\n2. Querying all users...');
        const allUsers = await db.select().from(users);
        console.log('All users:', allUsers);

        // 3. Insert a post
        console.log('\n3. Creating a new post...');
        const newPost: NewPost = {
            title: 'Hello from Drizzle + JWT Auth',
            content: 'This post was created using Drizzle ORM with JWT authentication!',
            authorId: insertedUser.id,
            published: true,
        };

        const [insertedPost] = await db.insert(posts).values(newPost).returning();
        console.log('Post created:', insertedPost);

        // 4. Query posts with author
        console.log('\n4. Querying posts with authors...');
        const postsWithAuthors = await db
            .select({
                postId: posts.id,
                title: posts.title,
                content: posts.content,
                authorName: users.name,
                authorEmail: users.email,
            })
            .from(posts)
            .leftJoin(users, eq(posts.authorId, users.id))
            .where(eq(posts.published, true))
            .orderBy(desc(posts.createdAt));

        console.log('Posts with authors:', postsWithAuthors);

        // 5. Insert products
        console.log('\n5. Creating products...');
        const newProducts: NewProduct[] = [
            {
                name: 'Laptop',
                description: 'High-performance laptop',
                price: 999.99,
                stock: 10,
                category: 'Electronics',
            },
            {
                name: 'Wireless Mouse',
                description: 'Ergonomic wireless mouse',
                price: 29.99,
                stock: 50,
                category: 'Accessories',
            },
        ];

        const insertedProducts = await db.insert(products).values(newProducts).returning();
        console.log('Products created:', insertedProducts);

        // 6. Query products with aggregation
        console.log('\n6. Product statistics...');
        const productStats = await db
            .select({
                category: products.category,
                totalProducts: sql<number>`count(*)`,
                avgPrice: sql<number>`avg(${products.price})`,
                totalStock: sql<number>`sum(${products.stock})`,
            })
            .from(products)
            .groupBy(products.category);

        console.log('Product stats by category:', productStats);

        // 7. Update example
        console.log('\n7. Updating user...');
        const updatedUser = await db
            .update(users)
            .set({ name: 'John Smith' })
            .where(eq(users.id, insertedUser.id))
            .returning();

        console.log('Updated user:', updatedUser);

        // 8. Transaction example
        console.log('\n8. Running transaction...');
        await db.transaction(async (tx) => {
            // Create a user and a post in a single transaction
            const [transactionUser] = await tx
                .insert(users)
                .values({
                    name: 'Alice Wonder',
                    email: 'alice@example.com',
                })
                .returning();

            await tx.insert(posts).values({
                title: 'Transaction Test',
                content: 'This post was created in a transaction!',
                authorId: transactionUser.id,
                published: true,
            });

            console.log('Transaction completed successfully!');
        });

        // 9. Raw SQL query
        console.log('\n9. Running raw SQL query...');
        const rawResult = await db.all(
            sql`SELECT COUNT(*) as user_count FROM ${users}`
        );
        console.log('Total users (raw SQL):', rawResult);

        console.log('\n=== All examples completed successfully! ===');
        console.log('\nYour libSQL + JWT + Drizzle setup is working perfectly! 🎉');

    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

// Run the examples
main().catch(console.error);