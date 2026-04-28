import chalk from "chalk";
import type { EngineEvent } from "@pulumi/pulumi/automation";
import {
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
  type Component,
} from "@mariozechner/pi-tui";

function termWidth(maxWidth = 100): number {
  return Math.max(30, Math.min(process.stdout.columns ?? 100, maxWidth));
}

function padToWidth(text: string, width: number): string {
  const visible = visibleWidth(text);
  if (visible === width) return text;
  if (visible > width) return truncateToWidth(text, width);
  return text + " ".repeat(width - visible);
}

function rule(width: number, left: string, fill: string, right: string): string {
  return chalk.gray(left + fill.repeat(Math.max(0, width - 2)) + right);
}

export type CardRow =
  | { label: string; value: unknown }
  | { text: string }
  | { blank: true };

export class KeyValueCard implements Component {
  constructor(
    private title: string,
    private rows: CardRow[],
    private options: { maxLabelWidth?: number } = {}
  ) {}

  invalidate(): void {}

  render(width: number): string[] {
    width = Math.max(30, width);
    const innerWidth = Math.max(1, width - 4);
    const titleText = ` ${this.title} `;
    const titleRuleWidth = Math.max(0, width - 2 - visibleWidth(titleText));
    const lines = [
      chalk.gray("┌") + chalk.gray("─") + chalk.bold(titleText) + chalk.gray("─".repeat(titleRuleWidth)) + chalk.gray("┐"),
    ];

    const labels = this.rows
      .filter((row): row is { label: string; value: unknown } => "label" in row)
      .map((row) => visibleWidth(row.label));
    const maxLabel = Math.max(0, ...labels);
    const labelWidth = Math.min(
      this.options.maxLabelWidth ?? 18,
      Math.max(8, maxLabel)
    );

    for (const row of this.rows) {
      if ("blank" in row) {
        lines.push(chalk.gray("│") + " ".repeat(width - 2) + chalk.gray("│"));
        continue;
      }

      if ("text" in row) {
        const wrapped = wrapTextWithAnsi(row.text, innerWidth);
        for (const wrappedLine of wrapped.length > 0 ? wrapped : [""]) {
          lines.push(
            chalk.gray("│") +
              " " +
              padToWidth(wrappedLine, innerWidth) +
              " " +
              chalk.gray("│")
          );
        }
        continue;
      }

      const label = chalk.gray(padToWidth(row.label, labelWidth));
      const value = String(row.value ?? "n/a");
      const valueWidth = Math.max(1, innerWidth - labelWidth - 2);
      const wrapped = wrapTextWithAnsi(value, valueWidth);

      for (let i = 0; i < Math.max(1, wrapped.length); i++) {
        const renderedLabel = i === 0 ? label : " ".repeat(labelWidth);
        const renderedValue = padToWidth(wrapped[i] ?? "", valueWidth);
        lines.push(
          chalk.gray("│") +
            " " +
            renderedLabel +
            chalk.gray(": ") +
            renderedValue +
            " " +
            chalk.gray("│")
        );
      }
    }

    lines.push(rule(width, "└", "─", "┘"));
    return lines;
  }
}

export class Table implements Component {
  constructor(private headers: string[], private rows: string[][]) {}

  invalidate(): void {}

  render(width: number): string[] {
    if (this.rows.length === 0) return [chalk.gray("(no data)")];

    const colCount = this.headers.length;
    const gap = 2;
    const minWidth = 3;
    const widths = this.headers.map((header, i) => {
      const rowMax = this.rows.reduce(
        (max, row) => Math.max(max, visibleWidth(row[i] ?? "")),
        0
      );
      return Math.max(minWidth, visibleWidth(header), rowMax);
    });

    const total = () => widths.reduce((sum, w) => sum + w, 0) + gap * (colCount - 1);
    while (total() > width && Math.max(...widths) > minWidth) {
      let widest = 0;
      for (let i = 1; i < widths.length; i++) {
        if (widths[i] > widths[widest]) widest = i;
      }
      widths[widest]--;
    }

    const format = (text: string, colWidth: number) => padToWidth(text, colWidth);
    const join = (cells: string[]) => cells.join(" ".repeat(gap));

    const lines = [
      chalk.bold(join(this.headers.map((header, i) => format(header, widths[i])))),
      chalk.gray(widths.map((w) => "─".repeat(w)).join(" ".repeat(gap))),
    ];

    for (const row of this.rows) {
      lines.push(join(this.headers.map((_, i) => format(row[i] ?? "", widths[i]))));
    }

    return lines;
  }
}

export function printComponent(component: Component, maxWidth = 100): void {
  for (const line of component.render(termWidth(maxWidth))) {
    console.log(line);
  }
}

export function displayCard(title: string, rows: CardRow[], maxWidth = 100): void {
  printComponent(new KeyValueCard(title, rows), maxWidth);
}

export function onEngineEvent(event: EngineEvent): void {
  if (event.diagnosticEvent?.message) {
    const sev = event.diagnosticEvent.severity;
    const msg = event.diagnosticEvent.message.trim();
    if (sev === "error") {
      console.error(`  ${chalk.red("ERROR:")} ${truncateToWidth(msg, 200)}`);
    } else if (msg.length > 0) {
      // Pulumi can emit extremely large debug diagnostics for RegisterResource
      // responses. Keep CLI output readable and avoid unbounded memory/output
      // growth during long updates.
      console.log(`  ${truncateToWidth(msg, 200)}`);
    }
  } else if (event.resourcePreEvent?.metadata) {
    const meta = event.resourcePreEvent.metadata;
    const op = meta.op ?? "same";
    if (op !== "same") {
      const urn = meta.urn ?? "unknown";
      const shortUrn = urn.split("::").pop() ?? urn;
      console.log(`  ${chalk.cyan(`[${op}]`)} ${shortUrn}`);
    }
  }
}

export function displayTable(headers: string[], rows: string[][]): void {
  printComponent(new Table(headers, rows), 120);
}

export function displaySuccess(message: string): void {
  console.log(chalk.green("✔") + " " + message);
}
