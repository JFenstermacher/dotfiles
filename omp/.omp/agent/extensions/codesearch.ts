import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { loadRegentRuntime } from "./lib/regent.ts";

export interface ParsedGitHubTarget {
	owner: string;
	repo: string;
	ref?: string;
}

const OWNER_RE = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,38}$/;
const REPO_RE = /^[a-zA-Z0-9_.-]{1,100}$/;

/**
 * Parse a GitHub repository target from:
 * - `owner/repo` or `owner/repo.git`
 * - `https://github.com/owner/repo[/tree/ref|...]`
 * - `git@github.com:owner/repo[.git]`
 * - `ssh://git@github.com/owner/repo[.git]`
 */
export function parseGitHubTarget(raw: string): ParsedGitHubTarget | null {
	const trimmed = raw.trim().replace(/^['"<]+|['">]+$/g, "");
	if (!trimmed) return null;

	let owner: string | undefined;
	let repo: string | undefined;

	const sshMatch = trimmed.match(/^(?:ssh:\/\/)?git@github\.com[:/]([^/\s]+)\/([^/\s#?]+)/i);
	if (sshMatch) {
		owner = sshMatch[1];
		repo = sshMatch[2];
	} else {
		const urlMatch = trimmed.match(/^(?:https?:\/\/)?(?:www\.)?github\.com\/([^/\s]+)\/([^/\s#?]+)/i);
		if (urlMatch) {
			owner = urlMatch[1];
			repo = urlMatch[2];
		} else {
			const slugMatch = trimmed.match(/^([^/\s]+)\/([^/\s#?]+)$/);
			if (slugMatch) {
				owner = slugMatch[1];
				repo = slugMatch[2];
			}
		}
	}

	if (!owner || !repo) return null;
	repo = repo.replace(/\.git$/i, "");
	if (!OWNER_RE.test(owner) || !REPO_RE.test(repo) || repo === "." || repo === "..") {
		return null;
	}
	return { owner, repo };
}

interface RefreshOutcome {
	defaultBranch: string;
	currentBranch: string | null;
	refreshed: boolean;
	fastForwarded: boolean;
	searchMode: "working-tree" | "git-ref";
	searchRef: string;
	note?: string;
}

async function detectDefaultBranch(
	pi: ExtensionAPI,
	repoPath: string,
	signal?: AbortSignal,
): Promise<string> {
	const head = await pi.exec("git", ["-C", repoPath, "symbolic-ref", "--short", "refs/remotes/origin/HEAD"], {
		signal,
	});
	if (head.code === 0) {
		const trimmed = head.stdout.trim();
		if (trimmed.startsWith("origin/")) {
			return trimmed.slice("origin/".length);
		}
	}
	for (const candidate of ["main", "master"]) {
		const check = await pi.exec(
			"git",
			["-C", repoPath, "show-ref", "--verify", "--quiet", `refs/remotes/origin/${candidate}`],
			{ signal },
		);
		if (check.code === 0) return candidate;
	}
	return "main";
}

async function refreshCheckout(
	pi: ExtensionAPI,
	repoPath: string,
	signal?: AbortSignal,
): Promise<RefreshOutcome> {
	const defaultBranch = await detectDefaultBranch(pi, repoPath, signal);
	const currentRes = await pi.exec("git", ["-C", repoPath, "branch", "--show-current"], { signal });
	const currentBranch = currentRes.code === 0 ? currentRes.stdout.trim() || null : null;

	const fetchRes = await pi.exec("git", ["-C", repoPath, "fetch", "origin", defaultBranch], { signal });
	const refreshed = fetchRes.code === 0;
	const searchRef = `origin/${defaultBranch}`;

	if (!refreshed) {
		return {
			defaultBranch,
			currentBranch,
			refreshed: false,
			fastForwarded: false,
			searchMode: "working-tree",
			searchRef,
			note: `git fetch origin ${defaultBranch} failed (${fetchRes.stderr.trim() || `exit ${fetchRes.code}`}); using existing local checkout.`,
		};
	}

	if (currentBranch === defaultBranch) {
		const pullRes = await pi.exec("git", ["-C", repoPath, "pull", "--ff-only", "origin", defaultBranch], { signal });
		if (pullRes.code === 0) {
			return {
				defaultBranch,
				currentBranch,
				refreshed: true,
				fastForwarded: true,
				searchMode: "working-tree",
				searchRef,
			};
		}
		return {
			defaultBranch,
			currentBranch,
			refreshed: true,
			fastForwarded: false,
			searchMode: "git-ref",
			searchRef,
			note: `Checked out on ${currentBranch}, but fast-forward failed (${pullRes.stderr.trim() || `exit ${pullRes.code}`}). Leave the working tree untouched and search ${searchRef} with git grep / git show.`,
		};
	}

	return {
		defaultBranch,
		currentBranch,
		refreshed: true,
		fastForwarded: false,
		searchMode: "git-ref",
		searchRef,
		note: `Checkout is on branch "${currentBranch ?? "(detached HEAD)"}", not "${defaultBranch}". Do NOT switch branches; inspect ${searchRef} via git -C "${repoPath}" grep / ls-tree / show.`,
	};
}

export default function codesearchExtension(pi: ExtensionAPI) {
	const z = pi.zod;
	pi.setLabel("Regent Codesearch");

	pi.registerTool({
		name: "codesearch_checkout",
		label: "Codesearch Checkout",
		description:
			"Ensure a GitHub repository is cloned locally via Regent into ~/dev/workspaces/github/{owner}/{repo} (without overwriting existing checkouts) and optionally refresh its default branch so you can search and read it locally with read/grep/glob instead of fetching from the internet.",
		loadMode: "essential",
		approval: "read",
		parameters: z.object({
			repo: z
				.string()
				.describe(
					"GitHub repository as owner/repo, github.com URL, or SSH URL (e.g. 'owner/repo' or 'https://github.com/owner/repo').",
				),
			refresh: z
				.boolean()
				.optional()
				.describe("Fetch origin's default branch and fast-forward when on that branch (default true)."),
		}),
		async execute(_toolCallId, params, signal, onUpdate) {
			const parsed = parseGitHubTarget(params.repo);
			if (!parsed) {
				throw new Error(
					`Could not parse GitHub repository from "${params.repo}". Expected owner/repo or a github.com URL.`,
				);
			}

			onUpdate?.({
				content: [{ type: "text", text: `Resolving local checkout for ${parsed.owner}/${parsed.repo} via Regent...` }],
				details: { owner: parsed.owner, repo: parsed.repo, phase: "checkout" },
			});

			const regent = await loadRegentRuntime();
			const checkout = await regent.repositoryCheckout(
				{ forge: "github", owner: parsed.owner, repo: parsed.repo },
				{},
				true,
			);
			if (!checkout.ok) {
				throw new Error(`Regent checkout failed for ${parsed.owner}/${parsed.repo}: ${checkout.error.message}`);
			}

			const repoPath = checkout.value;
			const shouldRefresh = params.refresh !== false;
			let refresh: RefreshOutcome | undefined;

			if (shouldRefresh && !signal?.aborted) {
				onUpdate?.({
					content: [{ type: "text", text: `Refreshing ${parsed.owner}/${parsed.repo} at ${repoPath}...` }],
					details: { owner: parsed.owner, repo: parsed.repo, path: repoPath, phase: "refresh" },
				});
				refresh = await refreshCheckout(pi, repoPath, signal);
			}

			const lines = [
				`Repository: ${parsed.owner}/${parsed.repo}`,
				`Local path: ${repoPath}`,
			];
			if (refresh) {
				lines.push(
					`Default branch: ${refresh.defaultBranch}`,
					`Current branch: ${refresh.currentBranch ?? "(detached HEAD)"}`,
					`Search mode: ${refresh.searchMode === "working-tree" ? `local files under ${repoPath}` : `git ref ${refresh.searchRef} (do not switch branches)`}`,
				);
				if (refresh.note) {
					lines.push(`Note: ${refresh.note}`);
				}
			} else {
				lines.push(`Search mode: local files under ${repoPath} (refresh skipped)`);
			}
			lines.push(
				`Use read/grep/glob against "${repoPath}" directly instead of remote web/GitHub search, and report paths relative to the repo root.`,
			);

			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: {
					owner: parsed.owner,
					repo: parsed.repo,
					path: repoPath,
					refresh,
				},
			};
		},
	});

	pi.registerCommand("codesearch", {
		description: "Clone/resolve a GitHub repo via Regent and search it locally",
		handler: async (args, ctx) => {
			const trimmed = args.trim();
			if (!trimmed) {
				ctx.ui.notify("Usage: /codesearch <owner/repo|github-url> [question or search query]", "warning");
				return;
			}

			const firstSpace = trimmed.search(/\s/);
			const firstToken = firstSpace === -1 ? trimmed : trimmed.slice(0, firstSpace);
			const rest = firstSpace === -1 ? "" : trimmed.slice(firstSpace + 1).trim();
			const parsed = parseGitHubTarget(firstToken);

			if (!parsed) {
				// Let the model extract owner/repo from natural language and invoke codesearch_checkout.
				pi.sendUserMessage(
					`Use the \`codesearch_checkout\` tool to clone/locate the relevant GitHub repository locally via Regent, then inspect it locally (never remote code search) to answer:\n\n${trimmed}`,
				);
				return;
			}

			ctx.ui.notify(`Ensuring local checkout for ${parsed.owner}/${parsed.repo}...`, "info");
			const regent = await loadRegentRuntime();
			const checkout = await regent.repositoryCheckout(
				{ forge: "github", owner: parsed.owner, repo: parsed.repo },
				{},
				true,
			);
			if (!checkout.ok) {
				ctx.ui.notify(`Regent checkout failed: ${checkout.error.message}`, "error");
				return;
			}

			const repoPath = checkout.value;
			const refresh = await refreshCheckout(pi, repoPath);

			const searchHint =
				refresh.searchMode === "working-tree"
					? `Search and read files directly under \`${repoPath}\` using local tools (\`grep\`, \`glob\`, \`read\`, \`find\`).`
					: `The checkout is on branch \`${refresh.currentBranch ?? "detached HEAD"}\` (do NOT switch branches). Search \`${refresh.searchRef}\` using \`git -C "${repoPath}" grep\`, \`ls-tree\`, and \`show\`.`;

			const prompt = rest
				? `Local checkout of \`${parsed.owner}/${parsed.repo}\` is ready at \`${repoPath}\`. ${searchHint} Report paths relative to the repo root.\n\nRequest: ${rest}`
				: `Local checkout of \`${parsed.owner}/${parsed.repo}\` is ready at \`${repoPath}\`. ${searchHint} Summarize the repository layout so I can ask questions about it.`;

			pi.sendUserMessage(prompt);
		},
	});
}
