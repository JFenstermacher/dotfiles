export const WORKSPACES_ROOT = `${process.env.HOME}/workspaces`

export type Worktree = {
  name: string
  hasRemote: boolean
}

export type Workspace = {
  path: string
  owner: string
  repo: string
  isCheckedOut: boolean
  isBareRepo: boolean
  activeBranch?: string
  defaultBranch: string
  worktrees?: Worktree[]
}
