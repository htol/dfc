export const DEFAULT_TIMEOUT_SECONDS = 30;
export const MAX_TIMEOUT_SECONDS = 3600;

const SSH_EXECUTABLE = "/usr/bin/ssh";

export function buildPtyRunArgs(
  host: string,
  command: string,
  timeoutSeconds = DEFAULT_TIMEOUT_SECONDS,
): string[] {
  if (!host || host.startsWith("-") || /[\s\x00-\x1f\x7f]/u.test(host)) {
    throw new Error("SSH host must be non-empty and contain no options, whitespace, or control characters");
  }
  if (!command.trim()) {
    throw new Error("SSH command must be non-empty");
  }
  if (
    !Number.isInteger(timeoutSeconds) ||
    timeoutSeconds < 1 ||
    timeoutSeconds > MAX_TIMEOUT_SECONDS
  ) {
    throw new Error(`SSH timeout must be an integer between 1 and ${MAX_TIMEOUT_SECONDS} seconds`);
  }

  return [
    "--timeout",
    `${timeoutSeconds}s`,
    "--",
    SSH_EXECUTABLE,
    "-o",
    "BatchMode=yes",
    "--",
    host,
    command,
  ];
}

export function normalizeTerminalOutput(output: string): string {
  return output.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}
