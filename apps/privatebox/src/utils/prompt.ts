// ── Shared prompt utilities ─────────────────────────────────────────────────

import { createInterface } from "node:readline";

export function prompt(question: string): Promise<string> {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer: string) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

export function promptYesNo(question: string): Promise<boolean> {
  return prompt(`${question} [y/N] `).then((a) => a.toLowerCase() === "y");
}
