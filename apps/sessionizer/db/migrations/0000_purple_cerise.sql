CREATE TABLE `branches` (
	`name` text NOT NULL,
	`has_remote` integer NOT NULL,
	`is_worktree` integer NOT NULL,
	`has_pull_request` integer NOT NULL,
	`workspace` text NOT NULL,
	PRIMARY KEY(`name`, `workspace`),
	FOREIGN KEY (`workspace`) REFERENCES `workspaces`(`repo_slug`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `sessions` (
	`name` text PRIMARY KEY NOT NULL,
	`workspace` text,
	`branch` text,
	FOREIGN KEY (`workspace`) REFERENCES `workspaces`(`repo_slug`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `workspaces` (
	`repo_slug` text PRIMARY KEY NOT NULL,
	`path` text NOT NULL,
	`owner` text GENERATED ALWAYS AS (substr(repo_slug, 1, instr(repo_slug, '/') - 1)) STORED NOT NULL,
	`repo` text GENERATED ALWAYS AS (substr(repo_slug, instr(repo_slug, '/') + 1)) STORED NOT NULL,
	`is_checked_out` integer NOT NULL,
	`is_bare_repo` integer,
	`default_branch` text NOT NULL,
	`active_branch` text
);
