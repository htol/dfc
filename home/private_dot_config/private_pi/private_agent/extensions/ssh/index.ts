import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import {
  formatSize,
  truncateTail,
  type ExtensionAPI,
  type TruncationResult,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

import {
  buildPtyRunArgs,
  DEFAULT_TIMEOUT_SECONDS,
  MAX_TIMEOUT_SECONDS,
  normalizeTerminalOutput,
} from "./args.ts";

type SshToolDetails = {
  exitCode: number;
  truncation?: TruncationResult;
  fullOutputPath?: string;
};

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "ssh",
    label: "SSH",
    description:
      "Execute a command over SSH while allocating a PTY for the local OpenSSH process. Does not allocate a remote PTY. Output is limited to Pi's standard 2000-line/50KB tool limit.",
    promptSnippet: "Execute commands over SSH with a local PTY",
    promptGuidelines: [
      "Use ssh instead of bash for agent-initiated SSH commands so the local OpenSSH process receives a PTY.",
    ],
    parameters: Type.Object({
      host: Type.String({ description: "SSH destination, such as a host alias or user@host" }),
      command: Type.String({ description: "Command to execute on the remote host" }),
      timeout: Type.Optional(
        Type.Integer({
          description: `Timeout in seconds (default: ${DEFAULT_TIMEOUT_SECONDS}, max: ${MAX_TIMEOUT_SECONDS})`,
          minimum: 1,
          maximum: MAX_TIMEOUT_SECONDS,
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const timeout = params.timeout ?? DEFAULT_TIMEOUT_SECONDS;
      const args = buildPtyRunArgs(params.host, params.command, timeout);
      const result = await pi.exec("pty-run", args, {
        signal,
        timeout: (timeout + 2) * 1000,
      });

      let rawOutput = result.stdout;
      if (result.stderr) {
        rawOutput += `${rawOutput && !rawOutput.endsWith("\n") ? "\n" : ""}${result.stderr}`;
      }
      rawOutput = normalizeTerminalOutput(rawOutput);

      const truncation = truncateTail(rawOutput);
      let output = truncation.content;
      let fullOutputPath: string | undefined;

      if (truncation.truncated) {
        const outputDirectory = await mkdtemp(join(tmpdir(), "pty-run-"));
        fullOutputPath = join(outputDirectory, "output.log");
        await writeFile(fullOutputPath, rawOutput, "utf8");
        output +=
          `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines ` +
          `(${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). ` +
          `Full output: ${fullOutputPath}]`;
      }

      const renderedOutput = output || "(no output)";
      if (signal?.aborted) {
        throw new Error(`${renderedOutput}\n\nSSH command aborted`);
      }
      if (result.killed) {
        throw new Error(`${renderedOutput}\n\npty-run was terminated`);
      }
      if (result.code !== 0) {
        throw new Error(`${renderedOutput}\n\npty-run exited with code ${result.code}`);
      }

      const details: SshToolDetails = {
        exitCode: result.code,
        truncation: truncation.truncated ? truncation : undefined,
        fullOutputPath,
      };
      return {
        content: [{ type: "text", text: renderedOutput }],
        details,
      };
    },
  });
}
