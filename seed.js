#!/usr/bin/env node
/**
 * Seed runner — runs scripts/seed.sql against the database.
 * Fully idempotent: safe to run multiple times.
 *
 * Usage:
 *   node scripts/seed.js
 *   DATABASE_URL="postgresql://..." node scripts/seed.js
 */

const { readFileSync } = require("fs");
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
  console.log("🌱  Running seed...");

  const seedPath = join(__dirname, "seed.sql");
  const content = readFileSync(seedPath, "utf8");

  try {
    await sql.unsafe(content);
    console.log("✅  Seed complete.");
  } catch (err) {
    console.error("❌  Seed failed:", err.message);
    await sql.end();
    process.exit(1);
  }

  await sql.end();
}

run().catch((err) => {
  console.error("Fatal:", err.message);
  process.exit(1);
});
