import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { loadRegentRuntime, type RegentRuntime } from "./lib/regent.ts";

export const SEMANTIC_PREFIXES = [
	"feat",
	"fix",
	"chore",
	"refactor",
	"docs",
	"ci",
	"build",
	"test",
	"perf",
	"style",
	"featb",
	"fixb",
] as const;

export type SemanticPrefix = (typeof SEMANTIC_PREFIXES)[number];

interface RexWindowInfo {
	window_id: string;
	label?: string;
	focused_block_id?: string;
	layers?: Array<{
		blocks?: Array<{ block_id?: string }>;
	}>;
}

interface RexWindowList {
	windows?: RexWindowInfo[];
}

interface RexSessionCreated {
	session_id?: string;
}

interface RexProcessResponse {
	foreground?: { name?: string; argv0?: string; pid?: number } | null;
	child?: { name?: string; argv0?: string; pid?: number } | null;
	last_exit?: unknown;
}

interface RexProgramStatusResponse {
	records?: Array<{
		app?: string;
		effective_app?: string;
		state?: string;
	}>;
}

interface DispatchOutcome {
	effort: string;
	semanticPrefix: SemanticPrefix;
	branchName: string;
	worktreePath: string;
	sessionId: string;
	sessionLabel: string;
	agentWindowId: string;
	agentBlockId: string;
	agentReady: boolean;
	dispatchedPrompt: string;
}

export function sanitizeEffortSlug(raw: string): string {
	const cleaned = raw
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.replace(/-{2,}/g, "-");
	return cleaned.slice(0, 64).replace(/-+$/g, "");
}

export function isSemanticPrefix(value: string): value is SemanticPrefix {
	return (SEMANTIC_PREFIXES as readonly string[]).includes(value);
}

/**
 * Format branch name as `<effort>/<semantic-prefix>`, appending `-2`, `-3`, ...
 * to `<effort>` if a collision exists in existing branch names.
 */
export function resolveUniqueBranchName(
	effortRaw: string,
	prefix: SemanticPrefix,
	existingBranches: ReadonlySet<string>,
): { effort: string; branchName: string } {
	const baseEffort = sanitizeEffortSlug(effortRaw);
	if (!baseEffort) {
		throw new Error(`Invalid effort slug: "${effortRaw}"`);
	}
	let effort = baseEffort;
	let candidate = `${effort}/${prefix}`;
	let suffix = 2;
	while (existingBranches.has(candidate)) {
		effort = `${baseEffort}-${suffix}`;
		candidate = `${effort}/${prefix}`;
		suffix += 1;
	}
	return { effort, branchName: candidate };
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
	if (signal?.aborted) {
		return Promise.reject(new Error("Aborted"));
	}
	const { promise, resolve, reject } = Promise.withResolvers<void>();
	const onAbort = () => {
		clearTimeout(timer);
		reject(new Error("Aborted"));
	};
	const timer = setTimeout(() => {
		signal?.removeEventListener("abort", onAbort);
		resolve();
	}, ms);
	timer.unref?.();
	signal?.addEventListener("abort", onAbort, { once: true });
	return promise;
}

function firstBlockId(window: RexWindowInfo): string | undefined {
	if (window.focused_block_id) return window.focused_block_id;
	for (const layer of window.layers ?? []) {
		for (const block of layer.blocks ?? []) {
			if (block.block_id) return block.block_id;
		}
	}
	return undefined;
}

function isOmpProcess(proc: RexProcessResponse | null): boolean {
	if (!proc) return false;
	const fg = proc.foreground?.name ?? proc.foreground?.argv0 ?? "";
	const child = proc.child?.name ?? proc.child?.argv0 ?? "";
	return /(?:^|\/)omp$/i.test(fg) || /(?:^|\/)omp$/i.test(child);
}

/**
 * Wait until omp is running and has rendered its prompt in the target Rex block.
 * Checks process state, OSC 7501 program_status, and screen capture.
 */
async function waitForOmpReady(
	pi: ExtensionAPI,
	regent: RegentRuntime,
	sessionId: string,
	blockId: string,
	timeoutMs: number,
	signal?: AbortSignal,
): Promise<boolean> {
	const deadline = Date.now() + timeoutMs;
	let ompSeenAt: number | undefined;

	while (Date.now() < deadline) {
		if (signal?.aborted) return false;

		const [procRes, statusRes] = await Promise.all([
			regent.runRexJson<RexProcessResponse>(
				["block", "call", "-s", sessionId, "-b", blockId, "process"],
				{ jsonFlag: false },
			),
			regent.runRexJson<RexProgramStatusResponse>(
				["block", "call", "-s", sessionId, "-b", blockId, "program_status"],
				{ jsonFlag: false },
			),
		]);

		const hasOmpStatus =
			statusRes.ok &&
			Boolean(
				statusRes.value?.records?.some(
					(rec) =>
						rec.app === "omp" ||
						rec.effective_app === "omp",
				),
			);
		if (hasOmpStatus) {
			return true;
		}

		if (procRes.ok && isOmpProcess(procRes.value)) {
			if (ompSeenAt === undefined) {
				ompSeenAt = Date.now();
			}
			// Check capture for omp's composer border/prompt line so we don't type before TUI mounts.
			const cap = await pi.exec(
				"rex",
				["capture", "-s", sessionId, "-b", blockId, "--trim"],
				{ signal, timeout: 5000 },
			);
			if (cap.code === 0 && (cap.stdout.includes("╰─") || cap.stdout.includes("❯"))) {
				// Brief settle so input loop is attached after initial frame draw.
				await sleep(250, signal);
				return true;
			}
			// Fallback if omp uses a different theme/prompt glyph after running for a few seconds.
			if (Date.now() - ompSeenAt >= 4000) {
				return true;
			}
		}

		await sleep(300, signal);
	}

	return false;
}

async function sendPromptToRexPane(
	regent: RegentRuntime,
	sessionId: string,
	blockId: string,
	text: string,
	signal?: AbortSignal,
): Promise<void> {
	// Prefer a bracketed paste event via `block.event` so multiline prompts do not
	// prematurely submit on embedded newlines, then press Enter to submit.
	const payload = JSON.stringify({
		session_id: sessionId,
		block_id: blockId,
		event: {
			type: "paste",
			payload: { text },
		},
	});
	const pasted = await regent.runRexJson<unknown>(
		["api", "call", "-s", sessionId, "block.event", payload],
		{ jsonFlag: false },
	);
	if (!pasted.ok) {
		// Fall back to `rex send` if paste event is unsupported by the connected server.
		const sent = await regent.runRexJson<unknown>(
			["send", "-s", sessionId, "-b", blockId, "--", text],
			{ jsonFlag: false },
		);
		if (!sent.ok) {
			throw new Error(`Failed to write prompt to Rex pane ${blockId}: ${sent.error.message}`);
		}
	}

	await sleep(150, signal);
	const submitted = await regent.runRexJson<unknown>(
		["send-key", "-s", sessionId, "-b", blockId, "enter"],
		{ jsonFlag: false },
	);
	if (!submitted.ok) {
		throw new Error(`Prompt was pasted into ${blockId}, but pressing Enter failed: ${submitted.error.message}`);
	}
}

async function dispatchWork(
	pi: ExtensionAPI,
	params: {
		cwd: string;
		effort: string;
		semanticPrefix: SemanticPrefix;
		prompt: string;
		ref?: string;
		agentTabName?: string;
	},
	signal?: AbortSignal,
	onStatus?: (message: string) => void,
): Promise<DispatchOutcome> {
	const regent = await loadRegentRuntime();

	// 1. Infer repository and gather existing branches to avoid collisions.
	const repoRes = await regent.inferRepository({ cwd: params.cwd });
	if (!repoRes.ok) {
		throw new Error(`Cannot infer Regent repository from ${params.cwd}: ${repoRes.error.message}`);
	}

	const existingRes = await regent.listBranches({ cwd: params.cwd });
	const existingNames = new Set<string>(
		existingRes.ok ? existingRes.value.map((b) => b.name) : [],
	);
	const { effort, branchName } = resolveUniqueBranchName(
		params.effort,
		params.semanticPrefix,
		existingNames,
	);

	// 2. Create the branch + worktree via Regent's addBranch library call.
	onStatus?.(`Creating branch and worktree ${branchName}...`);
	const added = await regent.addBranch(
		{
			name: branchName,
			...(params.ref ? { ref: params.ref } : {}),
		},
		{ cwd: params.cwd },
	);
	if (!added.ok) {
		throw new Error(`regent branch add failed for "${branchName}": ${added.error.message}`);
	}
	const worktreePath = added.value.path;
	const sessionLabel = `${added.value.owner}/${added.value.repo}@${branchName}`;

	// 3. Create the Rex session in the new worktree (without switching focus) and open Regent's configured tabs.
	onStatus?.(`Creating Rex session ${sessionLabel}...`);
	const created = await regent.runRexJson<RexSessionCreated>([
		"session",
		"new",
		sessionLabel,
		"--cwd",
		worktreePath,
	]);
	if (!created.ok) {
		throw new Error(`Worktree created at ${worktreePath}, but Rex session creation failed: ${created.error.message}`);
	}
	const sessionId = created.value?.session_id;
	if (!sessionId) {
		throw new Error(`Worktree created at ${worktreePath}, but Rex did not return a session_id`);
	}

	const configRes = await regent.loadConfig();
	if (!configRes.ok) {
		throw new Error(`Created Rex session ${sessionId}, but could not load Regent config: ${configRes.error.message}`);
	}

	const agentTabName = params.agentTabName?.trim() || "agent";
	const tabs = [...configRes.value.tabs];
	if (!tabs.some((tab) => tab.name.trim().toLowerCase() === agentTabName.toLowerCase())) {
		tabs.push({ name: agentTabName, commands: ["omp"] });
	}

	onStatus?.(`Opening configured tabs in ${sessionLabel}...`);
	const opened = await regent.openTabs(sessionId, tabs, worktreePath, {}, false);
	if (!opened.ok) {
		throw new Error(`Created Rex session ${sessionId}, but opening tabs failed: ${opened.error.message}`);
	}

	// 4. Locate the agent window & pane block ID.
	const windowsRes = await regent.runRexJson<RexWindowList>(["window", "ls", "-s", sessionId]);
	if (!windowsRes.ok || !Array.isArray(windowsRes.value?.windows)) {
		throw new Error(
			`Created Rex session ${sessionId}, but could not list its windows: ${
				windowsRes.ok ? "missing windows array" : windowsRes.error.message
			}`,
		);
	}
	const agentWindow = windowsRes.value.windows.find(
		(win) => win.label?.trim().toLowerCase() === agentTabName.toLowerCase(),
	);
	if (!agentWindow) {
		throw new Error(`Created Rex session ${sessionId}, but could not find "${agentTabName}" window`);
	}
	const agentBlockId = firstBlockId(agentWindow);
	if (!agentBlockId) {
		throw new Error(`Found "${agentTabName}" window (${agentWindow.window_id}), but it has no terminal block`);
	}

	// 5. Wait for omp inside the new pane to become ready, then paste + submit the prompt.
	onStatus?.(`Waiting for omp in ${sessionLabel} (${agentTabName}) to become ready...`);
	const agentReady = await waitForOmpReady(pi, regent, sessionId, agentBlockId, 20_000, signal);

	const dispatchedPrompt = `(${params.semanticPrefix}) ${params.prompt.trim()}`;
	onStatus?.(`Sending prompt to ${sessionLabel}...`);
	await sendPromptToRexPane(regent, sessionId, agentBlockId, dispatchedPrompt, signal);

	return {
		effort,
		semanticPrefix: params.semanticPrefix,
		branchName,
		worktreePath,
		sessionId,
		sessionLabel,
		agentWindowId: agentWindow.window_id,
		agentBlockId,
		agentReady,
		dispatchedPrompt,
	};
}

interface Classification {
	effort: string;
	semanticPrefix: SemanticPrefix;
}

async function classifyTaskWithModel(
	ctx: ExtensionContext,
	taskText: string,
): Promise<Classification | null> {
	if (!ctx.runEphemeralTurn) return null;

	const promptText = [
		"Classify the following software engineering task and propose a concise branch name.",
		`Choose semanticPrefix from: ${SEMANTIC_PREFIXES.join(", ")}.`,
		"Choose effort as a short 2-6 word lowercase kebab-case slug describing the work (e.g. 'pin-new-versions-in-workflow', 'add-auth', 'fix-session-picker').",
		"The branch name will be `<effort>/<semanticPrefix>`.",
		'Respond ONLY with a single JSON object of the form {"effort":"...","semanticPrefix":"..."} and nothing else.',
		"",
		`Task: ${taskText}`,
	].join("\n");

	try {
		const { replyText } = await ctx.runEphemeralTurn({
			promptText,
			tools: false,
			maxTokens: 256,
		});
		const jsonMatch = replyText.match(/\{[\s\S]*\}/);
		if (!jsonMatch) return null;
		const parsed = JSON.parse(jsonMatch[0]) as { effort?: unknown; semanticPrefix?: unknown };
		if (typeof parsed.effort !== "string" || typeof parsed.semanticPrefix !== "string") {
			return null;
		}
		const effort = sanitizeEffortSlug(parsed.effort);
		const prefix = parsed.semanticPrefix.trim().toLowerCase();
		if (!effort || !isSemanticPrefix(prefix)) {
			return null;
		}
		return { effort, semanticPrefix: prefix };
	} catch {
		return null;
	}
}

export default function dispatchExtension(pi: ExtensionAPI) {
	const z = pi.zod;
	pi.setLabel("Regent Dispatch");

	pi.registerTool({
		name: "regent_dispatch",
		label: "Regent Dispatch",
		description:
			"Create a new git branch and worktree via Regent (`<effort>/<semantic-prefix>`, e.g. `pin-new-versions-in-workflow/ci` or `add-auth/feat`), start its Rex session with configured tabs (including the `agent` pane running omp) without switching focus, and write the task prompt into that agent pane.",
		loadMode: "essential",
		approval: "exec",
		parameters: z.object({
			effort: z
				.string()
				.describe(
					"Short 2-6 word kebab-case slug naming the effort (first segment of `<effort>/<semantic-prefix>`, e.g. 'add-auth' or 'pin-new-versions-in-workflow').",
				),
			semantic_prefix: z
				.enum(SEMANTIC_PREFIXES)
				.describe(
					"Conventional semantic prefix for the work (second segment of `<effort>/<semantic-prefix>`, e.g. 'feat', 'fix', 'ci', 'chore', 'refactor', 'docs', 'featb', 'fixb').",
				),
			prompt: z
				.string()
				.describe("The full task prompt to write into the new Rex session's agent pane."),
			ref: z
				.string()
				.optional()
				.describe("Optional git ref to branch from (defaults to origin/main)."),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const outcome = await dispatchWork(
				pi,
				{
					cwd: ctx.cwd,
					effort: params.effort,
					semanticPrefix: params.semantic_prefix,
					prompt: params.prompt,
					ref: params.ref,
				},
				signal,
				(text) => {
					onUpdate?.({
						content: [{ type: "text", text }],
						details: { phase: text },
					});
				},
			);

			const summary = [
				`Dispatched work to new Regent worktree + Rex session.`,
				`Branch: ${outcome.branchName}`,
				`Worktree: ${outcome.worktreePath}`,
				`Rex session: ${outcome.sessionLabel} (${outcome.sessionId})`,
				`Agent pane: ${outcome.agentBlockId} (window ${outcome.agentWindowId})`,
				`Agent ready check: ${outcome.agentReady ? "confirmed" : "timed out waiting for prompt; text was still sent"}`,
				`Prompt: ${outcome.dispatchedPrompt}`,
			].join("\n");

			return {
				content: [{ type: "text", text: summary }],
				details: outcome,
			};
		},
	});

	pi.registerCommand("dispatch", {
		description:
			"Evaluate a task, create a `<effort>/<semantic-prefix>` branch worktree via Regent, start its Rex session, and write the task to its agent pane",
		handler: async (args, ctx) => {
			const taskText = args.trim();
			if (!taskText) {
				ctx.ui.notify("Usage: /dispatch <task description>", "warning");
				return;
			}

			// Try direct ephemeral classification first so /dispatch can execute cleanly
			// without polluting the current conversation turn when supported.
			ctx.ui.notify("Evaluating task and choosing branch name...", "info");
			const classification = await classifyTaskWithModel(ctx, taskText);

			if (!classification) {
				// Fall back to handing off to the main model with the regent_dispatch tool.
				pi.sendUserMessage(
					[
						"Evaluate the following task, choose a concise kebab-case `<effort>` slug and a conventional `<semantic-prefix>` (`feat`, `fix`, `chore`, `refactor`, `docs`, `ci`, `build`, `test`, `perf`, `style`, `featb`, `fixb`) so the branch is `<effort>/<semantic-prefix>` (e.g. `pin-new-versions-in-workflow/ci` or `add-auth/feat`), and call `regent_dispatch` to create the worktree and dispatch the task to the new Rex session's agent pane.",
						"",
						`Task: ${taskText}`,
					].join("\n"),
				);
				return;
			}

			try {
				const outcome = await dispatchWork(
					pi,
					{
						cwd: ctx.cwd,
						effort: classification.effort,
						semanticPrefix: classification.semanticPrefix,
						prompt: taskText,
					},
					undefined,
					(msg) => ctx.ui.notify(msg, "info"),
				);

				const report = [
					`Dispatched \`${outcome.branchName}\``,
					`- Worktree: \`${outcome.worktreePath}\``,
					`- Rex session: \`${outcome.sessionLabel}\` (\`${outcome.sessionId}\`)`,
					`- Agent pane: \`${outcome.agentBlockId}\`${outcome.agentReady ? "" : " (timed out waiting for omp ready banner; prompt still sent)"}`,
					`- Prompt: ${outcome.dispatchedPrompt}`,
				].join("\n");

				pi.sendMessage(
					{
						customType: "regent-dispatch",
						content: report,
						display: true,
						attribution: "agent",
						excludeFromContext: true,
					},
					{ triggerTurn: false },
				);
				ctx.ui.notify(`Dispatched ${outcome.branchName} → ${outcome.sessionLabel}`, "info");
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Dispatch failed: ${message}`, "error");
				pi.sendMessage(
					{
						customType: "regent-dispatch-error",
						content: `Dispatch failed for \`${classification.effort}/${classification.semanticPrefix}\`: ${message}`,
						display: true,
						attribution: "agent",
						excludeFromContext: true,
					},
					{ triggerTurn: false },
				);
			}
		},
	});
}
