import { eq, and } from "drizzle-orm";
import { workspaces, branches, session, pullRequests } from "./db/schema.ts";
import { createDb, databasePath } from "./db/client.ts";
import type { DbClient } from "./db/client.ts";
import type { Config } from "./config.ts";
import type { Workspace, Worktree } from "./workspaces.ts";

export class State {
  config: Config;
  db!: DbClient;

  constructor(config: Config) {
    this.config = config;
  }

  init(): { dbPath: string } {
    this.db = createDb(this.config);
    return { dbPath: databasePath(this.config) };
  }

  // ─── Workspaces ──────────────────────────────────────────────────────────

  listWorkspaces(): string[] {
    return this.db
      .select({ slug: workspaces.slug })
      .from(workspaces)
      .all()
      .map((r) => r.slug);
  }

  getWorkspace(slug: string): Workspace | null {
    const row = this.db
      .select()
      .from(workspaces)
      .where(eq(workspaces.slug, slug))
      .get();
    if (!row) return null;

    return {
      path: row.path,
      owner: row.owner,
      repo: row.repo,
      isCheckedOut: row.isCheckedOut,
      isBareRepo: row.isBareRepo ?? false,
      defaultBranch: row.defaultBranch,
      activeBranch: row.activeBranch ?? undefined,
      worktrees: row.isBareRepo ? this.listBranches(slug) : undefined,
    };
  }

  insertWorkspace(workspace: Workspace): void {
    const slug = `${workspace.owner}/${workspace.repo}`;
    this.db
      .insert(workspaces)
      .values({
        slug,
        path: workspace.path,
        isCheckedOut: workspace.isCheckedOut,
        isBareRepo: workspace.isBareRepo,
        defaultBranch: workspace.defaultBranch,
        activeBranch: workspace.activeBranch ?? null,
      })
      .run();

    if (workspace.worktrees) {
      for (const wt of workspace.worktrees) {
        this.insertBranch(slug, wt, true);
      }
    }
  }

  removeWorkspace(slug: string): void {
    this.db.delete(workspaces).where(eq(workspaces.slug, slug)).run();
  }

  updateActiveBranch(slug: string, activeBranch: string | undefined): void {
    this.db
      .update(workspaces)
      .set({ activeBranch: activeBranch ?? null })
      .where(eq(workspaces.slug, slug))
      .run();
  }

  updateWorkspaceCheckout(
    slug: string,
    updates: Partial<Pick<Workspace, "isCheckedOut" | "isBareRepo" | "defaultBranch" | "activeBranch">>,
  ): void {
    const dbUpdates: Record<string, unknown> = {};
    if (updates.isCheckedOut !== undefined) dbUpdates.isCheckedOut = updates.isCheckedOut;
    if (updates.isBareRepo !== undefined) dbUpdates.isBareRepo = updates.isBareRepo;
    if (updates.defaultBranch !== undefined) dbUpdates.defaultBranch = updates.defaultBranch;
    if (updates.activeBranch !== undefined) dbUpdates.activeBranch = updates.activeBranch ?? null;

    this.db
      .update(workspaces)
      .set(dbUpdates)
      .where(eq(workspaces.slug, slug))
      .run();
  }

  // ─── Pull Requests ────────────────────────────────────────────────────────

  upsertPullRequest(pr: {
    id: string;
    title: string;
    updatedAt: Date;
    state: string | null;
  }): void {
    this.db
      .insert(pullRequests)
      .values(pr)
      .onConflictDoUpdate({
        target: pullRequests.id,
        set: {
          title: pr.title,
          updatedAt: pr.updatedAt,
          state: pr.state,
        },
      })
      .run();
  }

  clearPullRequestsForRepo(repoSlug: string): void {
    this.db
      .delete(pullRequests)
      .where(eq(pullRequests.repo, repoSlug))
      .run();
  }

  linkBranchPR(workspaceSlug: string, branchName: string, pullRequestId: string | null): void {
    this.db
      .update(branches)
      .set({ pullRequestId })
      .where(
        and(
          eq(branches.workspace, workspaceSlug),
          eq(branches.name, branchName),
        ),
      )
      .run();
  }

  unlinkAllBranchPRs(workspaceSlug: string): void {
    this.db
      .update(branches)
      .set({ pullRequestId: null })
      .where(eq(branches.workspace, workspaceSlug))
      .run();
  }

  // ─── Branches ─────────────────────────────────────────────────────────────

  replaceBranches(workspaceSlug: string, items: { name: string; hasRemote: boolean; isWorktree: boolean }[]): void {
    this.db
      .delete(branches)
      .where(eq(branches.workspace, workspaceSlug))
      .run();

    for (const br of items) {
      this.db
        .insert(branches)
        .values({
          name: br.name,
          hasRemote: br.hasRemote,
          isWorktree: br.isWorktree,
          workspace: workspaceSlug,
        })
        .run();
    }
  }

  // ─── Branches / Worktrees ────────────────────────────────────────────────

  listBranches(workspaceSlug: string): Worktree[] {
    return this.db
      .select({
        name: branches.name,
        hasRemote: branches.hasRemote,
      })
      .from(branches)
      .where(eq(branches.workspace, workspaceSlug))
      .all();
  }

  listBranchDetails(workspaceSlug: string): { name: string; hasRemote: boolean; isWorktree: boolean; hasPR: boolean }[] {
    return this.db
      .select({
        name: branches.name,
        hasRemote: branches.hasRemote,
        isWorktree: branches.isWorktree,
        pullRequestId: branches.pullRequestId,
      })
      .from(branches)
      .where(eq(branches.workspace, workspaceSlug))
      .all()
      .map((r) => ({
        name: r.name,
        hasRemote: r.hasRemote,
        isWorktree: r.isWorktree,
        hasPR: r.pullRequestId != null,
      }));
  }

  insertBranch(workspaceSlug: string, branch: Worktree, isWorktree = false): void {
    this.db
      .insert(branches)
      .values({
        name: branch.name,
        hasRemote: branch.hasRemote,
        isWorktree,
        workspace: workspaceSlug,
      })
      .onConflictDoUpdate({
        target: [branches.name, branches.workspace],
        set: {
          isWorktree,
          hasRemote: branch.hasRemote,
        },
      })
      .run();
  }

  removeBranch(workspaceSlug: string, branchName: string): void {
    this.db
      .delete(branches)
      .where(
        and(
          eq(branches.workspace, workspaceSlug),
          eq(branches.name, branchName),
        ),
      )
      .run();
  }

  syncBranches(workspaceSlug: string, current: Worktree[], isWorktree = false): void {
    const existing = this.db
      .select({ name: branches.name })
      .from(branches)
      .where(eq(branches.workspace, workspaceSlug))
      .all()
      .map((r) => r.name);

    const currentNames = new Set(current.map((w) => w.name));
    const existingNames = new Set(existing);

    for (const br of current) {
      if (!existingNames.has(br.name)) {
        this.insertBranch(workspaceSlug, br, isWorktree);
      }
    }

    for (const name of existing) {
      if (!currentNames.has(name)) {
        this.removeBranch(workspaceSlug, name);
      }
    }
  }

  // ─── Merged PR cleanup

  listMergedPRBranches(): { workspace: string; name: string; isWorktree: boolean }[] {
    const mergedPRs = this.db
      .select({ id: pullRequests.id })
      .from(pullRequests)
      .where(eq(pullRequests.state, "merged"))
      .all();

    const results: { workspace: string; name: string; isWorktree: boolean }[] = [];

    for (const pr of mergedPRs) {
      const rows = this.db
        .select({
          workspace: branches.workspace,
          name: branches.name,
          isWorktree: branches.isWorktree,
        })
        .from(branches)
        .where(eq(branches.pullRequestId, pr.id))
        .all();

      results.push(...rows);
    }

    return results;
  }

  // ─── Debug helpers ─────────────────────────────────────────────────────────

  /** Build a full state dump from the database. */
  dump(): Record<string, Workspace> {
    const allSlugs = this.listWorkspaces();
    const result: Record<string, Workspace> = {};
    for (const slug of allSlugs) {
      const ws = this.getWorkspace(slug);
      if (ws) result[slug] = ws;
    }
    return result;
  }

  /** Clear all sessions from the database. */
  clearSessions(): void {
    this.db.delete(session).run();
  }

  /** Clear all workspaces from the database. */
  clear(): void {
    this.db.delete(workspaces).run();
  }
}
