import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export function expandHome(path: string): string {
  return path.startsWith("~") ? join(homedir(), path.slice(1)) : path;
}

export function fileUrlPath(value: string): string {
  if (!value.startsWith("file://")) {
    throw new Error(`Expected file:// URL, got: ${value}`);
  }
  return expandHome(value.slice(7));
}

export function readFileUrl(value: string): string {
  return readFileSync(fileUrlPath(value), "utf-8");
}
