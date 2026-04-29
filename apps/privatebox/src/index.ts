#!/usr/bin/env bun

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { runConfigure } from "./commands/configure.js";
import { runEdit } from "./commands/edit.js";
import { runApply } from "./commands/apply.js";
import { runDestroy } from "./commands/destroy.js";
import { runDelete } from "./commands/delete.js";
import { runUp } from "./commands/up.js";
import { runDown } from "./commands/down.js";
import { runListConfigs, runListInstances } from "./commands/list.js";
import { runGetConfig, runGetInstance } from "./commands/get.js";
import { runConnect } from "./commands/connect.js";
import { fuzzySelectConfig, fuzzySelectInstance } from "./tui/fuzzy.js";

function getVersion(): string {
  try {
    const pkg = JSON.parse(
      readFileSync(
        join(dirname(fileURLToPath(import.meta.url)), "..", "package.json"),
        "utf-8"
      )
    );
    return pkg.version ?? "0.1.0";
  } catch {
    return "0.1.0";
  }
}

function printHelp(): void {
  console.log(`PrivateBox — Manage ephemeral AWS EC2 instances

Usage:
  privatebox <command> [options]

Commands:
  configure [--from <name>] <name>  Create a new private box config
  apply [name] [--ssh-config]       Reconcile cloud resources to latest config
  create [name] [--ssh-config]      Alias for apply
  up [name]                         Start a stopped instance
  down [name]                       Stop a running instance
  connect [name]                    Connect using the configured command
  destroy [name]                    Destroy all cloud resources
  delete [name]                     Delete a config file (requires destroy first)
  edit [name]                       Edit an existing config
  list configs|cfg|instances|inst   List configs or instances
  get config [name]                 Show a single config's details
  get instance [name]               Show instance state (IP, status, uptime, etc.)

Options:
  --help, -h     Show this help
  --version, -v  Show version
`);
}

function firstPositional(args: string[]): string | null {
  return args.find((arg) => !arg.startsWith("--")) ?? null;
}

async function requireSelectedName(
  args: string[],
  select: () => Promise<string | null>
): Promise<string> {
  const name = firstPositional(args);
  if (name) return name;
  const selected = await select();
  if (!selected) process.exit(1);
  return selected;
}

function hasFlag(args: string[], flag: string): boolean {
  return args.includes(flag);
}

async function handleConfigure(args: string[]): Promise<void> {
  let fromName: string | undefined;
  let name: string | undefined;
  let skipAmi = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--from" && i + 1 < args.length) {
      fromName = args[++i];
    } else if (args[i] === "--skip-ami") {
      skipAmi = true;
    } else if (!name && !args[i].startsWith("--")) {
      name = args[i];
    }
  }

  if (!name) {
    console.error("Error: <name> is required.\n");
    console.error("Usage: privatebox configure [--from <source>] [--skip-ami] <name>");
    process.exit(1);
  }

  await runConfigure({ fromName, name, skipAmi });
}

async function main() {
  const [command, ...args] = Bun.argv.slice(2);

  if (!command) {
    printHelp();
    process.exit(0);
  }

  if (command === "--help" || command === "-h") {
    printHelp();
    process.exit(0);
  }

  if (command === "--version" || command === "-v") {
    console.log(getVersion());
    process.exit(0);
  }

  switch (command) {
    case "configure":
      await handleConfigure(args);
      return;

    case "apply":
    case "create":
      await runApply(
        await requireSelectedName(args, () => fuzzySelectConfig("Select config to apply:")),
        { sshConfig: hasFlag(args, "--ssh-config") }
      );
      return;

    case "edit":
      await runEdit(
        await requireSelectedName(args, () => fuzzySelectConfig("Select config to edit:"))
      );
      return;

    case "destroy":
      await runDestroy(
        await requireSelectedName(args, () => fuzzySelectInstance("Select instance to destroy:"))
      );
      return;

    case "delete":
      await runDelete(
        await requireSelectedName(args, () => fuzzySelectConfig("Select config to delete:"))
      );
      return;

    case "up":
      await runUp(
        await requireSelectedName(args, () => fuzzySelectInstance("Select instance to start:"))
      );
      return;

    case "down":
      await runDown(
        await requireSelectedName(args, () => fuzzySelectInstance("Select instance to stop:"))
      );
      return;

    case "connect":
      await runConnect(
        await requireSelectedName(args, () => fuzzySelectInstance("Select instance to connect:"))
      );
      return;

    case "list": {
      const sub = args[0];
      if (sub === "configs" || sub === "cfg") {
        await runListConfigs();
        return;
      }
      if (sub === "instances" || sub === "instance" || sub === "inst") {
        await runListInstances();
        return;
      }
      console.error(`Error: unknown list subcommand "${sub ?? ""}".\n`);
      console.error("Usage: privatebox list configs|cfg|instances|inst");
      process.exit(1);
    }

    case "get": {
      const [sub, ...rest] = args;
      if (sub === "config") {
        await runGetConfig(
          await requireSelectedName(rest, () => fuzzySelectConfig("Select config to show:"))
        );
        return;
      }
      if (sub === "instance") {
        await runGetInstance(
          await requireSelectedName(rest, () => fuzzySelectInstance("Select instance to show:"))
        );
        return;
      }
      console.error(`Error: unknown get subcommand "${sub ?? ""}".\n`);
      console.error("Usage: privatebox get config <name> | instance <name>");
      process.exit(1);
    }

    default:
      console.error(`Unknown command: ${command}`);
      printHelp();
      process.exit(1);
  }
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
});
