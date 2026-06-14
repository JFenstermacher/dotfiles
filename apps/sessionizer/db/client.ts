import { mkdirSync, cpSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import { migrate } from "drizzle-orm/better-sqlite3/migrator";
import type { Config } from "../config.ts";

export function databasePath(config: Config): string {
  return join(config.databaseDir, "sessionizer.db");
}

export function migrationsPath(config: Config): string {
  return join(config.databaseDir, "migrations");
}

function bundledMigrationsPath(): string {
  return fileURLToPath(new URL("migrations", import.meta.url));
}

export function createDb(config: Config) {
  const dbPath = databasePath(config);
  const migrationsDir = migrationsPath(config);

  mkdirSync(dirname(dbPath), { recursive: true });
  mkdirSync(migrationsDir, { recursive: true });

  cpSync(bundledMigrationsPath(), migrationsDir, {
    recursive: true,
    force: true,
  });

  const sqlite = new Database(dbPath);
  const db = drizzle(sqlite);
  migrate(db, { migrationsFolder: migrationsDir });

  return db;
}

export type DbClient = ReturnType<typeof createDb>;
