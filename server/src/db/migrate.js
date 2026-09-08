import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pg from "pg";
import dotenv from "dotenv";

dotenv.config();

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error("DATABASE_URL not found in .env");
    process.exit(1);
  }

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  try {
    console.log("Connecting to Supabase PostgreSQL database...");
    await client.connect();
    console.log("Connected successfully.");

    // Read schema DDL
    const schemaPath = path.join(__dirname, "migrations", "001_initial_schema.sql");
    const schemaSql = fs.readFileSync(schemaPath, "utf8");
    console.log("Applying schema migrations (creating tables)...");
    await client.query(schemaSql);
    console.log("Schema migration applied successfully.");

    // Read seed SQL
    const seedsPath = path.join(__dirname, "seeds.sql");
    const seedsSql = fs.readFileSync(seedsPath, "utf8");
    console.log("Applying seed data...");
    await client.query(seedsSql);
    console.log("Seed data applied successfully.");

    await client.end();
    console.log("All migrations and seeds applied to Supabase!");
    process.exit(0);
  } catch (error) {
    console.error("Migration error:", error.message);
    await client.end();
    process.exit(1);
  }
}

runMigration();

