/**
 * /commit — stage current work, write a semantic commit, and push.
 *
 * Stages staged + unstaged + untracked changes, summarizes the index with the
 * current model, commits, then pushes. Default-branch pushes ask first.
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import { complete, type UserMessage } from "@earendil-works/pi-ai/compat";
import { BorderedLoader, type ExtensionAPI, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const DIFF_CHAR_LIMIT = 80_000;
const GIT_TIMEOUT_MS = 30_000;
const PUSH_TIMEOUT_MS = 60_000;

const COMMIT_SYSTEM_PROMPT = `You write git commit messages.

Rules:
- Use a conventional/semantic commit: type(optional-scope): summary
- Types: feat, fix, refactor, chore, docs, test, style, perf, ci, build
- Subject is imperative, present tense, no trailing period, 72 characters or fewer
- Add a short body after a blank line only when the change needs context
- Do not mention files unless the scope is unclear without them
- Output ONLY the commit message. No quotes, no markdown fences, no preamble.`;

type GitResult = {
	stdout: string;
	stderr: string;
	code: number;
};

function notify(ctx: ExtensionCommandContext, message: string, type: "info" | "warning" | "error" = "info") {
	if (ctx.hasUI) {
		ctx.ui.notify(message, type);
	}
}

async function git(pi: ExtensionAPI, args: string[], cwd: string, timeout = GIT_TIMEOUT_MS): Promise<GitResult> {
	const result = await pi.exec("git", args, { cwd, timeout });
	return { stdout: result.stdout, stderr: result.stderr, code: result.code };
}

function formatGitError(result: GitResult): string {
	return (result.stderr || result.stdout || "unknown git error").trim();
}

async function requireRepo(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const result = await git(pi, ["rev-parse", "--show-toplevel"], cwd);
	if (result.code !== 0) {
		return undefined;
	}
	return result.stdout.trim();
}

function isWorkingTreeClean(status: string): boolean {
	return status.trim().length === 0;
}

async function getCurrentBranch(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const result = await git(pi, ["branch", "--show-current"], cwd);
	const branch = result.stdout.trim();
	return result.code === 0 && branch.length > 0 ? branch : undefined;
}

async function getRemoteDefaultBranch(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const abbrev = await git(pi, ["rev-parse", "--abbrev-ref", "origin/HEAD"], cwd);
	if (abbrev.code === 0) {
		const name = abbrev.stdout.trim().replace(/^origin\//, "");
		if (name.length > 0) {
			return name;
		}
	}

	const symbolic = await git(pi, ["symbolic-ref", "refs/remotes/origin/HEAD"], cwd);
	if (symbolic.code === 0) {
		const name = symbolic.stdout.trim().replace(/^refs\/remotes\/origin\//, "");
		if (name.length > 0) {
			return name;
		}
	}

	return undefined;
}

async function isDefaultBranch(pi: ExtensionAPI, cwd: string, branch: string): Promise<boolean> {
	const remoteDefault = await getRemoteDefaultBranch(pi, cwd);
	if (remoteDefault) {
		return branch === remoteDefault;
	}
	return branch === "main" || branch === "master";
}

async function getPreferredRemote(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const result = await git(pi, ["remote"], cwd);
	if (result.code !== 0) {
		return undefined;
	}

	const remotes = result.stdout
		.split("\n")
		.map((line) => line.trim())
		.filter(Boolean);

	if (remotes.includes("origin")) {
		return "origin";
	}
	return remotes[0];
}

async function hasUpstream(pi: ExtensionAPI, cwd: string): Promise<boolean> {
	const result = await git(pi, ["rev-parse", "--abbrev-ref", "@{upstream}"], cwd);
	return result.code === 0 && result.stdout.trim().length > 0;
}

async function collectCommitContext(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	const [stat, diff, log] = await Promise.all([
		git(pi, ["diff", "--cached", "--stat"], cwd),
		git(pi, ["diff", "--cached"], cwd),
		git(pi, ["log", "-8", "--oneline"], cwd),
	]);

	const parts = ["## Staged diffstat", stat.stdout.trim() || "(empty)"];

	let patch = diff.stdout.trim();
	if (patch.length > DIFF_CHAR_LIMIT) {
		patch = `${patch.slice(0, DIFF_CHAR_LIMIT)}\n\n[diff truncated]`;
	}
	parts.push("## Staged diff", patch || "(empty)");

	if (log.code === 0 && log.stdout.trim()) {
		parts.push("## Recent commits", log.stdout.trim());
	}

	const context = parts.join("\n\n");
	return context.trim().length > 0 ? context : undefined;
}

function normalizeCommitMessage(raw: string): string | undefined {
	let text = raw.trim();
	if (!text) {
		return undefined;
	}

	text = text.replace(/^```(?:\w+)?\s*\n?/, "").replace(/\n?```$/, "").trim();
	text = text.replace(/^(?:here(?:'s| is)(?: the)? commit message:?\s*)/i, "").trim();

	const lines = text.split("\n");
	while (lines.length > 0 && (lines[0].startsWith("#") || lines[0].trim() === "")) {
		lines.shift();
	}

	const message = lines.join("\n").trim();
	return message.length > 0 ? message : undefined;
}

async function generateWithModel(
	ctx: ExtensionCommandContext,
	prompt: string,
	signal?: AbortSignal,
): Promise<string> {
	if (!ctx.model) {
		throw new Error("No model selected");
	}

	const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model);
	if (!auth.ok || !auth.apiKey) {
		throw new Error(auth.ok ? `No API key for ${ctx.model.provider}` : auth.error);
	}

	const userMessage: UserMessage = {
		role: "user",
		content: [{ type: "text", text: prompt }],
		timestamp: Date.now(),
	};

	const response = await complete(
		ctx.model,
		{ systemPrompt: COMMIT_SYSTEM_PROMPT, messages: [userMessage] },
		{
			apiKey: auth.apiKey,
			headers: auth.headers,
			env: auth.env,
			signal,
			cacheRetention: "none",
			sessionId: uuidv7(),
		},
	);

	if (response.stopReason === "aborted") {
		throw new Error("aborted");
	}

	if (response.stopReason === "error") {
		const errorText = response.content
			.filter((block): block is { type: "text"; text: string } => block.type === "text")
			.map((block) => block.text)
			.join("\n")
			.trim();
		throw new Error(errorText || "Model returned an error");
	}

	const text = response.content
		.filter((block): block is { type: "text"; text: string } => block.type === "text")
		.map((block) => block.text)
		.join("\n");

	const message = normalizeCommitMessage(text);
	if (!message) {
		throw new Error("Model returned an empty commit message");
	}
	return message;
}

async function generateCommitMessage(
	ctx: ExtensionCommandContext,
	diffContext: string,
): Promise<string | undefined> {
	const prompt = `Write a commit message for these changes.\n\n${diffContext}`;

	if (ctx.mode === "tui") {
		try {
			return await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(tui, theme, "Writing commit message...");
				loader.onAbort = () => done(null);

				generateWithModel(ctx, prompt, loader.signal)
					.then(done)
					.catch((error: unknown) => {
						const message = error instanceof Error ? error.message : "Failed to write commit message";
						if (message !== "aborted") {
							notify(ctx, message, "error");
						}
						done(null);
					});

				return loader;
			});
		} catch {
			return undefined;
		}
	}

	try {
		return await generateWithModel(ctx, prompt);
	} catch (error) {
		const message = error instanceof Error ? error.message : "Failed to write commit message";
		notify(ctx, message, "error");
		return undefined;
	}
}

async function pushBranch(
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	cwd: string,
	branch: string,
): Promise<void> {
	const remote = await getPreferredRemote(pi, cwd);
	if (!remote) {
		notify(ctx, `Committed on ${branch}, but no remotes are configured`, "warning");
		return;
	}

	const upstream = await hasUpstream(pi, cwd);
	const args = upstream ? ["push"] : ["push", "-u", remote, "HEAD"];
	const result = await git(pi, args, cwd, PUSH_TIMEOUT_MS);

	if (result.code !== 0) {
		notify(ctx, `Commit succeeded, but push failed: ${formatGitError(result)}`, "error");
		return;
	}

	notify(ctx, `Pushed ${branch} to ${remote}`, "info");
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("commit", {
		description: "Stage current changes, commit with a generated message, and push",
		handler: async (_args, ctx) => {
			const repoRoot = await requireRepo(pi, ctx.cwd);
			if (!repoRoot) {
				notify(ctx, "Not a git repository", "error");
				return;
			}

			const status = await git(pi, ["status", "--porcelain"], repoRoot);
			if (status.code !== 0) {
				notify(ctx, formatGitError(status), "error");
				return;
			}

			if (isWorkingTreeClean(status.stdout)) {
				notify(ctx, "Nothing to commit", "info");
				return;
			}

			const add = await git(pi, ["add", "-A"], repoRoot);
			if (add.code !== 0) {
				notify(ctx, `Failed to stage changes: ${formatGitError(add)}`, "error");
				return;
			}

			const staged = await git(pi, ["diff", "--cached", "--quiet"], repoRoot);
			if (staged.code === 0) {
				notify(ctx, "Nothing to commit after staging", "info");
				return;
			}

			const diffContext = await collectCommitContext(pi, repoRoot);
			if (!diffContext) {
				notify(ctx, "Could not read staged changes", "error");
				return;
			}

			const message = await generateCommitMessage(ctx, diffContext);
			if (!message) {
				notify(ctx, "Commit cancelled", "info");
				return;
			}

			const commit = await git(pi, ["commit", "-m", message], repoRoot);
			if (commit.code !== 0) {
				notify(ctx, `Commit failed: ${formatGitError(commit)}`, "error");
				return;
			}

			const subject = message.split("\n")[0] ?? message;
			notify(ctx, `Committed: ${subject}`, "info");

			const branch = await getCurrentBranch(pi, repoRoot);
			if (!branch) {
				notify(ctx, "Committed, but HEAD is detached so nothing was pushed", "warning");
				return;
			}

			if (await isDefaultBranch(pi, repoRoot, branch)) {
				if (!ctx.hasUI) {
					notify(ctx, `Committed on default branch ${branch}. Push skipped without confirmation.`, "warning");
					return;
				}

				const shouldPush = await ctx.ui.confirm(
					"Push default branch?",
					`You're on ${branch}, the default branch. Push to remote?`,
				);
				if (!shouldPush) {
					notify(ctx, "Committed locally. Push skipped.", "info");
					return;
				}
			}

			await pushBranch(pi, ctx, repoRoot, branch);
		},
	});
}
