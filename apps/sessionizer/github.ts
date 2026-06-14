import { Result, TaggedError } from "better-result";

export const GitHubError = TaggedError("GitHubError")<{
  message: string;
  cause?: unknown;
}>();

export type RepoInfo = {
  slug: string;
  name: string;
  owner: string;
  defaultBranch: string;
};

export type PullRequest = {
  id: string;
  title: string;
  branch: string;
  updatedAt: Date;
  state: string | null;
};

const GITHUB_API = "https://api.github.com";

type GitHubRepo = {
  full_name: string;
  name: string;
  owner: { login: string };
  default_branch: string;
};

type GitHubPull = {
  number: number;
  title: string;
  head: { ref: string };
  state: "open" | "closed";
  draft: boolean;
  merged_at: string | null;
  updated_at: string;
};

let authUserLogin: string | undefined;

async function getAuthUser(token: string): Promise<string> {
  if (authUserLogin) return authUserLogin;
  const res = await fetch(`${GITHUB_API}/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Failed to get authenticated user: ${res.status} ${body}`);
  }
  const data = (await res.json()) as { login: string };
  authUserLogin = data.login;
  return data.login;
}

async function fetchRepos(
  url: string,
  token: string,
): Promise<GitHubRepo[]> {
  const all: GitHubRepo[] = [];
  let page = 1;

  while (true) {
    const res = await fetch(`${url}&page=${page}`, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
    });
    if (!res.ok) {
      const body = await res.text();
      throw new Error(`GitHub API ${res.status}: ${body}`);
    }
    const data = (await res.json()) as GitHubRepo[];
    if (data.length === 0) break;
    all.push(...data);
    page++;
  }

  return all;
}

function mapPRState(pr: GitHubPull): string | null {
  if (pr.draft) return "draft";
  if (pr.state === "open") return "open";
  if (pr.merged_at) return "merged";
  return "closed";
}

export async function listRepositories(
  owner: string,
): Promise<Result<RepoInfo[], InstanceType<typeof GitHubError>>> {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return Result.err(
      new GitHubError({
        message: "GITHUB_TOKEN environment variable is required",
      }),
    );
  }

  return Result.tryPromise({
    try: async () => {
      const authUser = await getAuthUser(token);
      let data: GitHubRepo[];

      if (owner === authUser) {
        data = await fetchRepos(
          `${GITHUB_API}/user/repos?affiliation=owner&per_page=100`,
          token,
        );
      } else {
        try {
          data = await fetchRepos(
            `${GITHUB_API}/orgs/${owner}/repos?per_page=100`,
            token,
          );
        } catch {
          data = await fetchRepos(
            `${GITHUB_API}/users/${owner}/repos?per_page=100`,
            token,
          );
        }
      }

      return data.map((r) => ({
        slug: r.full_name,
        name: r.name,
        owner: r.owner.login,
        defaultBranch: r.default_branch,
      }));
    },
    catch: (cause) =>
      new GitHubError({
        message: `Failed to list repositories for ${owner}`,
        cause,
      }),
  });
}

export async function listPullRequests(
  owner: string,
  repo: string,
): Promise<Result<PullRequest[], InstanceType<typeof GitHubError>>> {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return Result.err(
      new GitHubError({
        message: "GITHUB_TOKEN environment variable is required",
      }),
    );
  }

  return Result.tryPromise({
    try: async () => {
      const res = await fetch(
        `${GITHUB_API}/repos/${owner}/${repo}/pulls?state=all&per_page=100&sort=updated&direction=desc`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
          },
        },
      );
      if (!res.ok) {
        const body = await res.text();
        throw new Error(`GitHub API ${res.status}: ${body}`);
      }
      const data = (await res.json()) as GitHubPull[];
      return data.map((pr) => ({
        id: `${owner}/${repo}#${pr.number}`,
        title: pr.title,
        branch: pr.head.ref,
        updatedAt: new Date(pr.updated_at),
        state: mapPRState(pr),
      }));
    },
    catch: (cause) =>
      new GitHubError({
        message: `Failed to list pull requests for ${owner}/${repo}`,
        cause,
      }),
  });
}
