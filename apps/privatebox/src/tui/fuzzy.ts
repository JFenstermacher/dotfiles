import {
  type Component,
  type Focusable,
  CURSOR_MARKER,
  TUI,
  ProcessTerminal,
  fuzzyFilter,
  matchesKey,
  Key,
  truncateToWidth,
} from "@mariozechner/pi-tui";

export interface FuzzyFinderItem {
  value: string;
  label: string;
  description?: string;
}

class FuzzyFinder implements Component, Focusable {
  focused = false;
  private query = "";
  private cursor = 0;
  private items: FuzzyFinderItem[];
  private filtered: FuzzyFinderItem[];
  private selectedIndex = 0;
  private maxVisible: number;
  private prompt: string;

  onSelect?: (item: FuzzyFinderItem) => void;
  onCancel?: () => void;

  constructor(
    items: FuzzyFinderItem[],
    prompt: string,
    maxVisible = 10
  ) {
    this.items = items;
    this.filtered = [...items];
    this.prompt = prompt;
    this.maxVisible = maxVisible;
  }

  invalidate(): void {
    // No cached render state
  }

  private refilter(): void {
    if (!this.query) {
      this.filtered = [...this.items];
    } else {
      this.filtered = fuzzyFilter(
        this.items,
        this.query,
        (item) => item.label + " " + (item.description ?? "")
      );
    }
    this.selectedIndex = Math.min(
      this.selectedIndex,
      Math.max(0, this.filtered.length - 1)
    );
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.enter)) {
      const item = this.filtered[this.selectedIndex];
      if (item && this.onSelect) {
        this.onSelect(item);
      }
      return;
    }

    if (
      matchesKey(data, Key.escape) ||
      matchesKey(data, Key.ctrl("c"))
    ) {
      if (this.onCancel) {
        this.onCancel();
      }
      return;
    }

    if (matchesKey(data, Key.up)) {
      this.selectedIndex =
        this.selectedIndex === 0
          ? Math.max(0, this.filtered.length - 1)
          : this.selectedIndex - 1;
      return;
    }

    if (matchesKey(data, Key.down)) {
      this.selectedIndex =
        this.selectedIndex >= this.filtered.length - 1
          ? 0
          : this.selectedIndex + 1;
      return;
    }

    if (matchesKey(data, Key.backspace)) {
      if (this.query.length > 0 && this.cursor > 0) {
        this.query =
          this.query.slice(0, this.cursor - 1) +
          this.query.slice(this.cursor);
        this.cursor--;
        this.refilter();
      }
      return;
    }

    if (matchesKey(data, Key.delete)) {
      if (this.cursor < this.query.length) {
        this.query =
          this.query.slice(0, this.cursor) +
          this.query.slice(this.cursor + 1);
        this.refilter();
      }
      return;
    }

    if (matchesKey(data, Key.home) || matchesKey(data, Key.ctrl("a"))) {
      this.cursor = 0;
      return;
    }

    if (matchesKey(data, Key.end) || matchesKey(data, Key.ctrl("e"))) {
      this.cursor = this.query.length;
      return;
    }

    if (matchesKey(data, Key.left)) {
      this.cursor = Math.max(0, this.cursor - 1);
      return;
    }

    if (matchesKey(data, Key.right)) {
      this.cursor = Math.min(this.query.length, this.cursor + 1);
      return;
    }

    // Ignore escape sequences (arrow keys etc. that weren't matched above)
    if (data.startsWith("\x1b[")) return;

    // Printable characters
    if (data.length >= 1) {
      // Filter out control characters
      const chars = data
        .split("")
        .filter((c) => c.charCodeAt(0) >= 32 && c.charCodeAt(0) !== 127)
        .join("");
      if (chars.length > 0) {
        this.query =
          this.query.slice(0, this.cursor) + chars + this.query.slice(this.cursor);
        this.cursor += chars.length;
        this.refilter();
      }
    }
  }

  render(width: number): string[] {
    const lines: string[] = [];

    // Prompt line with fake cursor
    const before = this.query.slice(0, this.cursor);
    const at = this.query.slice(this.cursor, this.cursor + 1) || " ";
    const after = this.query.slice(this.cursor + 1);
    const promptLine = `${this.prompt} ${before}${CURSOR_MARKER}\x1b[7m${at}\x1b[27m${after}`;
    lines.push(truncateToWidth(promptLine, width));

    // Separator
    lines.push("─".repeat(Math.min(width, 40)));

    if (this.filtered.length === 0) {
      lines.push("  No matches");
      return lines;
    }

    const maxVis = Math.min(this.maxVisible, this.filtered.length);
    const half = Math.floor(maxVis / 2);
    const start = Math.max(
      0,
      Math.min(this.selectedIndex - half, this.filtered.length - maxVis)
    );
    const end = Math.min(start + maxVis, this.filtered.length);

    for (let i = start; i < end; i++) {
      const item = this.filtered[i];
      const isSelected = i === this.selectedIndex;
      const prefix = isSelected ? "> " : "  ";
      let text = prefix + item.label;
      if (item.description) {
        text += `  ${item.description}`;
      }
      lines.push(truncateToWidth(text, width));
    }

    // Scroll info
    if (start > 0 || end < this.filtered.length) {
      const info = `  (${this.selectedIndex + 1}/${this.filtered.length})`;
      lines.push(truncateToWidth(info, width));
    }

    return lines;
  }
}

export interface FuzzySelectOptions {
  prompt?: string;
  maxVisible?: number;
}

export async function fuzzySelect<T extends { value: string }>(
  items: T[],
  options: FuzzySelectOptions = {}
): Promise<T | null> {
  if (items.length === 0) {
    return null;
  }
  if (items.length === 1) {
    return items[0];
  }

  const prompt = options.prompt ?? ">";
  const maxVisible = options.maxVisible ?? 10;

  const finderItems: FuzzyFinderItem[] = items.map((item) =>
    "label" in item && typeof item.label === "string"
      ? (item as unknown as FuzzyFinderItem)
      : { value: item.value, label: item.value }
  );

  return new Promise<T | null>((resolve) => {
    const terminal = new ProcessTerminal();
    const tui = new TUI(terminal);

    const finder = new FuzzyFinder(finderItems, prompt, maxVisible);
    finder.onSelect = (selected) => {
      tui.stop();
      const original = items.find((i) => i.value === selected.value);
      resolve(original ?? null);
    };
    finder.onCancel = () => {
      tui.stop();
      resolve(null);
    };

    tui.addChild(finder);
    tui.setFocus(finder);
    tui.start();
  });
}

export async function fuzzySelectConfig(
  prompt = "Select config:"
): Promise<string | null> {
  const { listConfigs, loadConfig } = await import("../config/store.js");
  const names = listConfigs();
  if (names.length === 0) {
    console.error("No configs found. Run `privatebox configure <name>` first.");
    return null;
  }

  const items = names.map((name) => {
    try {
      const cfg = loadConfig(name);
      return {
        value: name,
        label: name,
        description: `${cfg.aws_region} · ${cfg.instance_type}`,
      };
    } catch {
      return { value: name, label: name, description: "(invalid config)" };
    }
  });

  const selected = await fuzzySelect(items, { prompt });
  return selected?.value ?? null;
}

export async function fuzzySelectInstance(
  prompt = "Select instance:"
): Promise<string | null> {
  const { listConfigs } = await import("../config/store.js");
  const { stackExists, readStackOutputs } = await import(
    "../pulumi/stack-manager.js"
  );
  const { loadConfig } = await import("../config/store.js");
  const { describeInstance } = await import("../utils/instance.js");

  const names = listConfigs();
  const instances: { value: string; label: string; description?: string }[] = [];

  for (const name of names) {
    if (!(await stackExists(name))) continue;
    try {
      const cfg = loadConfig(name);
      const outputs = readStackOutputs(name) ?? {};
      const region = (outputs.awsRegion as string | undefined) ?? cfg.aws_region;
      const instanceId = outputs.instanceId;
      let status = "unknown";
      if (instanceId && region) {
        status = (await describeInstance(cfg, instanceId)).state;
      }
      instances.push({
        value: name,
        label: name,
        description: `${region} · ${status}`,
      });
    } catch {
      instances.push({
        value: name,
        label: name,
        description: "(error reading stack)",
      });
    }
  }

  if (instances.length === 0) {
    console.error(
      "No instances found. Run `privatebox apply <name>` to create one."
    );
    return null;
  }

  const selected = await fuzzySelect(instances, { prompt });
  return selected?.value ?? null;
}
