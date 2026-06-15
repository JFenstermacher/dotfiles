import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "sqlite",
  dbCredentials: {
    url: "data/database/sessionizer.db",
  },
  schema: "./db/schema.ts",
  out: "./db/migrations",
});
