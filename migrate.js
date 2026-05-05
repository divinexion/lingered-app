#!/usr/bin/env node
/**
 * Migration runner — tracks applied migrations in `schema_migrations` table.
 * Runs only NEW migrations on each execution.
 *
 * Usage:
 *   node scripts/migrate.js
 *   DATABASE_URL="postgresql://..." node scripts/migrate.js
 */

const { readFileSync, readdirSync } = require("fs");
const { join } = require("path");
const postgres = require("postgres");

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error("❌  DATABASE_URL is not set.");
  process.exit(1);
}

const sql = postgres(DATABASE_URL, {
  ssl: "require",
  max: 1,
  idle_timeout: 30,
  connect_timeout: 30,
});

async function run() {
  console.log("🔌  Connecting to database...");

  // 1. Create migrations tracking table if it doesn't exist
  await sql`
    CREATE TABLE IF NOT EXISTS public.schema_migrations (
      filename   TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;

  // 2. Get already-applied migrations
  const applied = await sql`SELECT filename FROM public.schema_migrations`;
  const appliedSet = new Set(applied.map((r) => r.filename));

  // 3. Get all migration files sorted
  const migrationsDir = join(__dirname, "../migrations");
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  const pending = files.filter((f) => !appliedSet.has(f));

  if (pending.length === 0) {
    console.log("✅  No new migrations to apply.");
    await sql.end();
    return;
  }

  console.log(`📋  ${pending.length} pending migration(s):\n`);

  // 4. Run each pending migration in a transaction
  for (const filename of pending) {
    const filepath = join(migrationsDir, filename);
    const content = readFileSync(filepath, "utf8");

    process.stdout.write(`  ▶  ${filename} ... `);

    try {
      await sql.begin(async (tx) => {
        // Execute migration SQL
        await tx.unsafe(content);
        // Record it as applied
        await tx`
          INSERT INTO public.schema_migrations (filename)
          VALUES (${filename})
        `;
      });
      console.log("✅");
    } catch (err) {
      console.log("❌  FAILED");
      console.error(`\n     Error: ${err.message}\n`);
      await sql.end();
      process.exit(1);
    }
  }

  console.log(`\n✅  ${pending.length} migration(s) applied successfully.`);
  await sql.end();
}

run().catch((err) => {
  console.error("Fatal:", err.message);
  process.exit(1);
});
