import { sql } from "drizzle-orm";
import { int, text, sqliteTable, primaryKey } from "drizzle-orm/sqlite-core"

export const workspaces = sqliteTable("workspaces", {
  slug: text('repo_slug').primaryKey(),
  path: text('path').notNull(),
  owner: text('owner').generatedAlwaysAs(
    () => sql`substr(repo_slug, 1, instr(repo_slug, '/') - 1)`,
    { mode: 'stored' }
  ).notNull(),
  repo: text('repo').generatedAlwaysAs(
    () => sql`substr(repo_slug, instr(repo_slug, '/') + 1)`,
    { mode: 'stored' }
  ).notNull(),
  isCheckedOut: int("is_checked_out", { mode: "boolean" }).notNull(),
  isBareRepo: int("is_bare_repo", { mode: "boolean" }),
  defaultBranch: text("default_branch").notNull(),
  activeBranch: text("active_branch"),
})

export const pullRequests = sqliteTable("pull_requests", {
  id: text().primaryKey(),
  title: text().notNull(),
  updatedAt: int("updated_at", { mode: "timestamp" }).notNull(),
  state: text("state"),
  repo: text().generatedAlwaysAs(
    () => sql`substr(id, 1, instr(id, '#') - 1)`,
    { mode: 'stored' }
  ).notNull(),
  prNumber: int("pr_number").generatedAlwaysAs(
    () => sql`cast(substr(id, instr(id, '#') + 1) as integer)`,
    { mode: 'stored' }
  ).notNull(),
})

export const branches = sqliteTable("branches", {
  name: text().notNull(),
  hasRemote: int("has_remote", { mode: "boolean" }).notNull(),
  isWorktree: int("is_worktree", { mode: "boolean" }).notNull(),
  pullRequestId: text("pull_request_id")
    .references(() => pullRequests.id, { onDelete: "set null" }),
  workspace: text("workspace")
    .notNull()
    .references(() => workspaces.slug, { onDelete: "cascade" })
}, (table) => [
  primaryKey({ columns: [table.name, table.workspace] }),
])

export const session = sqliteTable("sessions", {
  name: text().primaryKey(),
  workspace: text("workspace")
    .references(() => workspaces.slug, { onDelete: "cascade" }),
  branch: text("branch"),
})
