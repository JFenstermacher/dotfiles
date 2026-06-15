import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { drizzle } from "drizzle-orm/node-sqlite";
import { migrate } from "drizzle-orm/node-sqlite/migrator";
import type { Config } from "../config.ts";

export function databasePath(config: Config): string {
  return `${config.databaseDir}/sessionizer.db`;
}

export function migrationsPath(config: Config): string {
  return `${config.databaseDir}/migrations`;
}

export function createDb(config: Config) {
  const dbPath = databasePath(config);
  mkdirSync(dirname(dbPath), { recursive: true });

  const db = drizzle(dbPath);
  migrate(db, { migrationsFolder: migrationsPath(config) });

  return db;
}

export type DbClient = ReturnType<typeof createDb>;
