import { plugin as bunPlugin } from "bun";
import { existsSync, readFileSync, realpathSync } from "node:fs";
import { access } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

export type Result<T, E = Error> =
	| { ok: true; value: T }
	| { ok: false; error: E };

export interface RepositorySelector {
	forge?: string;
	owner: string;
	repo: string;
}

export interface RepositoryOptions {
	statePath?: string;
	workspaceRoot?: string;
	configPath?: string;
}

export interface RepositoryRecord {
	forge: "github";
	owner: string;
	repo: string;
	path: string;
	status: "checked out" | "not checked out";
	label: string;
}

export interface BranchInput {
	name: string;
	ref?: string;
}

export interface BranchOptions {
	cwd?: string;
	workspaceRoot?: string;
	worktreeRoot?: string;
	branchStatePath?: string;
}

export interface BranchRecord {
	forge: string;
	owner: string;
	repo: string;
	name: string;
	path: string;
	status: "checked out" | "not checked out";
	prNumber: number | null;
	prMerged: boolean;
	label: string;
}

export interface RepositoryCheckout {
	forge: "github";
	owner: string;
	repo: string;
	primary: string;
}

export interface RegentTab {
	name: string;
	commands: string[];
}

export interface RegentConfig {
	tabs: RegentTab[];
	forges: { github: string[] };
}

export interface RexOptions {
	client?: string;
	server?: string;
	executable?: string;
	jsonFlag?: boolean;
}

export interface RegentRuntime {
	repositoryCheckout: (
		input: RepositorySelector,
		options?: RepositoryOptions,
		create?: boolean,
	) => Promise<Result<string, Error>>;
	addRepository: (
		input: RepositorySelector,
		options?: RepositoryOptions,
	) => Promise<Result<RepositoryRecord, Error>>;
	addBranch: (
		input: BranchInput,
		options?: BranchOptions,
	) => Promise<Result<BranchRecord, Error>>;
	listBranches: (options?: BranchOptions) => Promise<Result<BranchRecord[], Error>>;
	inferRepository: (
		options?: BranchOptions,
	) => Promise<Result<RepositoryCheckout, Error>>;
	loadConfig: (path?: string) => Promise<Result<RegentConfig, Error>>;
	openTabs: (
		sessionId: string,
		tabs: RegentTab[],
		cwd: string | undefined,
		options: RexOptions,
		checkExisting?: boolean,
	) => Promise<Result<void, Error>>;
	runRexJson: <T>(
		args: readonly string[],
		options?: RexOptions,
	) => Promise<Result<T | null, Error>>;
}

let cachedRuntime: Promise<RegentRuntime> | undefined;
const installedPluginRoots = new Set<string>();

export function hoddmimirRoot(): string {
	return (
		process.env.HODDMIMIR_ROOT ||
		join(homedir(), "dev", "workspaces", "github", "mimiskelda", "hoddmimir")
	);
}

function escapeRegExp(value: string): string {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function resolvePackageEntry(pkgDir: string): string | null {
	const pkgJsonPath = join(pkgDir, "package.json");
	if (!existsSync(pkgJsonPath)) return null;
	const pkg = JSON.parse(readFileSync(pkgJsonPath, "utf8")) as {
		exports?: unknown;
		module?: string;
		main?: string;
	};
	let rel: string | undefined;
	if (typeof pkg.exports === "string") {
		rel = pkg.exports;
	} else if (pkg.exports && typeof pkg.exports === "object") {
		const exp = pkg.exports as Record<string, unknown>;
		const dot = exp["."] ?? exp;
		if (typeof dot === "string") {
			rel = dot;
		} else if (dot && typeof dot === "object") {
			const obj = dot as Record<string, unknown>;
			const pick = obj.import ?? obj.default ?? obj.module;
			if (typeof pick === "string") {
				rel = pick;
			} else if (pick && typeof pick === "object") {
				const inner = pick as Record<string, unknown>;
				if (typeof inner.default === "string") rel = inner.default;
			}
		}
	}
	rel ??= pkg.module ?? pkg.main ?? "index.js";
	const resolved = join(pkgDir, rel);
	return existsSync(resolved) ? realpathSync(resolved) : null;
}

function resolveBareFrom(specifier: string, importer: string): string | null {
	let dir = dirname(importer);
	while (true) {
		const entry = resolvePackageEntry(join(dir, "node_modules", specifier));
		if (entry) return entry;
		const parent = dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

/**
 * Compiled standalone Bun executables (like `omp`) do not walk external
 * `node_modules` directories for bare specifiers imported from files outside
 * the binary. Register a narrowly scoped Bun `onLoad` hook for built
 * `hoddmimir/libs/ts/.../dist/*.js` files that rewrites bare imports
 * (`@mimiskelda/*`, `smol-toml`, etc.) to their realpaths in hoddmimir's
 * pnpm `node_modules`.
 */
function ensureHoddmimirResolver(root: string): void {
	const canonicalRoot = existsSync(root) ? realpathSync(root) : root;
	if (installedPluginRoots.has(canonicalRoot)) return;
	installedPluginRoots.add(canonicalRoot);

	const libsPrefix = join(canonicalRoot, "libs", "ts");
	const filter = new RegExp(`^${escapeRegExp(libsPrefix)}/.*\\.js$`);

	bunPlugin({
		name: `hoddmimir-node-modules:${canonicalRoot}`,
		setup(build) {
			build.onLoad({ filter }, (args) => {
				const source = readFileSync(args.path, "utf8");
				const rewritten = source.replace(
					/(from\s+)(['"])([^./'"][^'"]*)\2/g,
					(match, prefix: string, quote: string, spec: string) => {
						if (spec.startsWith("node:") || spec.startsWith("bun:")) return match;
						const resolved = resolveBareFrom(spec, args.path);
						return resolved ? `${prefix}${quote}${resolved}${quote}` : match;
					},
				);
				return { contents: rewritten, loader: "js" };
			});
		},
	});
}

async function importBuiltModule<T>(filePath: string): Promise<T> {
	try {
		await access(filePath);
	} catch {
		throw new Error(
			`Regent library artifact missing at ${filePath}. Build @mimiskelda/regent in ${hoddmimirRoot()} (pnpm --recursive --filter @mimiskelda/regent... run build).`,
		);
	}
	// Runtime-resolved path under HODDMIMIR_ROOT (not a static workspace dependency).
	return (await import(filePath)) as T;
}

/**
 * Dynamically load the built Regent and Rex workspace modules from hoddmimir.
 * Uses direct submodule entrypoints under dist/ so loading does not pull in
 * interactive TUI widgets unnecessarily.
 */
export function loadRegentRuntime(): Promise<RegentRuntime> {
	if (!cachedRuntime) {
		cachedRuntime = (async () => {
			const root = hoddmimirRoot();
			ensureHoddmimirResolver(root);
			const regentDist = join(root, "libs", "ts", "regent", "dist");
			const rexDist = join(root, "libs", "ts", "rex", "dist");
			const [repository, branch, config, tabs, rex] = await Promise.all([
				importBuiltModule<{
					repositoryCheckout: RegentRuntime["repositoryCheckout"];
					addRepository: RegentRuntime["addRepository"];
				}>(join(regentDist, "repository.js")),
				importBuiltModule<{
					addBranch: RegentRuntime["addBranch"];
					listBranches: RegentRuntime["listBranches"];
					inferRepository: RegentRuntime["inferRepository"];
				}>(join(regentDist, "branch.js")),
				importBuiltModule<{
					loadConfig: RegentRuntime["loadConfig"];
				}>(join(regentDist, "config.js")),
				importBuiltModule<{
					openTabs: RegentRuntime["openTabs"];
				}>(join(regentDist, "tabs.js")),
				importBuiltModule<{
					runRexJson: RegentRuntime["runRexJson"];
				}>(join(rexDist, "index.js")),
			]);
			return {
				repositoryCheckout: repository.repositoryCheckout,
				addRepository: repository.addRepository,
				addBranch: branch.addBranch,
				listBranches: branch.listBranches,
				inferRepository: branch.inferRepository,
				loadConfig: config.loadConfig,
				openTabs: tabs.openTabs,
				runRexJson: rex.runRexJson,
			};
		})().catch((error) => {
			cachedRuntime = undefined;
			throw error;
		});
	}
	return cachedRuntime;
}
