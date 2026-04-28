import chalk from "chalk";
import {
  Key,
  Loader,
  ProcessTerminal,
  TUI,
  matchesKey,
  truncateToWidth,
  type Component,
} from "@mariozechner/pi-tui";
import type { EngineEvent } from "@pulumi/pulumi/automation";

class PulumiEventLog implements Component {
  private events: string[] = [];
  private resourceStates = new Map<string, string>();

  constructor(private maxEvents = 8) {}

  invalidate(): void {}

  addEvent(event: EngineEvent): void {
    const rendered = this.renderEvent(event);
    if (!rendered) return;

    this.events.push(rendered);
    if (this.events.length > this.maxEvents) {
      this.events.splice(0, this.events.length - this.maxEvents);
    }
  }

  summary(): string[] {
    if (this.resourceStates.size === 0) return [];
    return Array.from(this.resourceStates.entries())
      .slice(-8)
      .map(([name, op]) => `  ${chalk.cyan(`[${op}]`)} ${name}`);
  }

  render(width: number): string[] {
    const lines: string[] = [];
    const summary = this.summary();

    if (summary.length > 0) {
      lines.push(chalk.bold("Resources"));
      for (const line of summary) {
        lines.push(truncateToWidth(line, width));
      }
    }

    if (this.events.length > 0) {
      if (lines.length > 0) lines.push("");
      lines.push(chalk.bold("Recent events"));
      for (const event of this.events) {
        lines.push(truncateToWidth(event, width));
      }
    }

    return lines.length > 0 ? lines : [chalk.gray("Waiting for Pulumi events...")];
  }

  private renderEvent(event: EngineEvent): string | undefined {
    if (event.resourcePreEvent?.metadata) {
      const meta = event.resourcePreEvent.metadata;
      const op = meta.op ?? "same";
      if (op === "same") return undefined;
      const urn = meta.urn ?? "unknown";
      const shortUrn = urn.split("::").pop() ?? urn;
      this.resourceStates.set(shortUrn, op);
      return `${chalk.cyan(`[${op}]`)} ${shortUrn}`;
    }

    if (event.diagnosticEvent?.message) {
      const severity = event.diagnosticEvent.severity;
      const msg = event.diagnosticEvent.message.trim();
      if (!msg) return undefined;

      // Pulumi emits very large RegisterResource diagnostics. They are useful
      // in debug logs, but not in an interactive progress view.
      if (msg.startsWith("RegisterResource RPC")) return undefined;
      if (msg.startsWith("RegisterResourceOutputs RPC")) return undefined;
      if (msg.startsWith("Registering resource:")) return undefined;

      if (severity === "error") {
        return `${chalk.red("ERROR:")} ${msg}`;
      }
      if (severity === "warning") {
        return `${chalk.yellow("WARN:")} ${msg}`;
      }
      return chalk.gray(msg);
    }

    return undefined;
  }
}

class PulumiPhaseView implements Component {
  private title = "Pulumi";

  constructor(
    private loader: Loader,
    private log: PulumiEventLog,
    private hint: string
  ) {}

  invalidate(): void {
    this.loader.invalidate();
    this.log.invalidate();
  }

  setTitle(title: string): void {
    this.title = title;
  }

  render(width: number): string[] {
    const lines: string[] = [];
    const innerWidth = Math.max(20, width - 2);
    const title = ` ${this.title} `;
    lines.push(
      chalk.gray("┌") +
        chalk.gray("─") +
        chalk.bold(title) +
        chalk.gray("─".repeat(Math.max(0, width - 3 - title.length))) +
        chalk.gray("┐")
    );

    for (const line of this.loader.render(innerWidth)) {
      lines.push(chalk.gray("│") + truncateToWidth(line, innerWidth).padEnd(innerWidth) + chalk.gray("│"));
    }

    lines.push(chalk.gray("│") + " ".repeat(innerWidth) + chalk.gray("│"));

    for (const line of this.log.render(innerWidth)) {
      lines.push(chalk.gray("│") + truncateToWidth(line, innerWidth).padEnd(innerWidth) + chalk.gray("│"));
    }

    lines.push(chalk.gray("│") + " ".repeat(innerWidth) + chalk.gray("│"));
    lines.push(chalk.gray("│") + chalk.gray(truncateToWidth(this.hint, innerWidth).padEnd(innerWidth)) + chalk.gray("│"));
    lines.push(chalk.gray("└") + chalk.gray("─".repeat(Math.max(0, width - 2))) + chalk.gray("┘"));
    return lines;
  }
}

export async function runPulumiPhase<T>(
  title: string,
  initialMessage: string,
  operation: (onEvent: (event: EngineEvent) => void) => Promise<T>
): Promise<T> {
  // Raw-mode TUI is only appropriate for interactive terminals. In piped or CI
  // usage, fall back to a normal one-line message and let the caller handle
  // errors normally.
  if (!process.stdin.isTTY || !process.stdout.isTTY) {
    console.log(`\n${initialMessage}`);
    return operation(() => {});
  }

  const terminal = new ProcessTerminal();
  const tui = new TUI(terminal);
  const loader = new Loader(tui, chalk.cyan, chalk.gray, initialMessage);
  const log = new PulumiEventLog();
  const view = new PulumiPhaseView(loader, log, "Press Ctrl+C to abort");

  tui.addChild(view);
  tui.addInputListener((data) => {
    if (matchesKey(data, Key.ctrl("c"))) {
      tui.stop();
      process.kill(process.pid, "SIGINT");
      return { consume: true };
    }
    return undefined;
  });

  tui.start();
  loader.start();

  try {
    const result = await operation((event) => {
      log.addEvent(event);
      tui.requestRender();
    });
    loader.setMessage("Complete");
    tui.requestRender();
    return result;
  } finally {
    loader.stop();
    tui.stop();
  }
}
