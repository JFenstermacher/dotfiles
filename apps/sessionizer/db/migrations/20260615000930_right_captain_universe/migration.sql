CREATE TABLE `branches` (
	`name` text NOT NULL,
	`has_remote` integer NOT NULL,
	`is_worktree` integer NOT NULL,
	`pull_request_id` text,
	`workspace` text NOT NULL,
	CONSTRAINT `branches_pk` PRIMARY KEY(`name`, `workspace`),
	CONSTRAINT `fk_branches_pull_request_id_pull_requests_id_fk` FOREIGN KEY (`pull_request_id`) REFERENCES `pull_requests`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_branches_workspace_workspaces_repo_slug_fk` FOREIGN KEY (`workspace`) REFERENCES `workspaces`(`repo_slug`) ON DELETE CASCADE
);
--> statement-breakpoint
CREATE TABLE `pull_requests` (
	`id` text PRIMARY KEY,
	`title` text NOT NULL,
	`updated_at` integer NOT NULL,
	`state` text,
	`repo` text GENERATED ALWAYS AS (substr(id, 1, instr(id, '#') - 1)) STORED NOT NULL,
	`pr_number` integer GENERATED ALWAYS AS (cast(substr(id, instr(id, '#') + 1) as integer)) STORED NOT NULL
);
--> statement-breakpoint
CREATE TABLE `sessions` (
	`name` text PRIMARY KEY,
	`workspace` text,
	`branch` text,
	CONSTRAINT `fk_sessions_workspace_workspaces_repo_slug_fk` FOREIGN KEY (`workspace`) REFERENCES `workspaces`(`repo_slug`) ON DELETE CASCADE
);
--> statement-breakpoint
CREATE TABLE `workspaces` (
	`repo_slug` text PRIMARY KEY,
	`path` text NOT NULL,
	`owner` text GENERATED ALWAYS AS (substr(repo_slug, 1, instr(repo_slug, '/') - 1)) STORED NOT NULL,
	`repo` text GENERATED ALWAYS AS (substr(repo_slug, instr(repo_slug, '/') + 1)) STORED NOT NULL,
	`is_checked_out` integer NOT NULL,
	`is_bare_repo` integer,
	`default_branch` text NOT NULL,
	`active_branch` text
);
