CREATE TABLE `pull_requests` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`updated_at` integer NOT NULL,
	`repo` text GENERATED ALWAYS AS (substr(id, 1, instr(id, '#') - 1)) STORED NOT NULL,
	`pr_number` integer GENERATED ALWAYS AS (cast(substr(id, instr(id, '#') + 1) as integer)) STORED NOT NULL
);
--> statement-breakpoint
ALTER TABLE `branches` DROP COLUMN `has_pull_request`;
--> statement-breakpoint
ALTER TABLE `branches` ADD COLUMN `pull_request_id` text REFERENCES `pull_requests`(`id`) ON DELETE set null ON UPDATE no action;
