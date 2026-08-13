import assert from "node:assert/strict";
import test from "node:test";

import {
  buildPtyRunArgs,
  DEFAULT_TIMEOUT_SECONDS,
  normalizeTerminalOutput,
} from "./args.ts";

test("buildPtyRunArgs constructs a direct batch-mode SSH invocation", () => {
  assert.deepEqual(buildPtyRunArgs("host", "ls", 12), [
    "--timeout",
    "12s",
    "--",
    "/usr/bin/ssh",
    "-o",
    "BatchMode=yes",
    "--",
    "host",
    "ls",
  ]);
});

test("buildPtyRunArgs uses the default timeout", () => {
  assert.equal(DEFAULT_TIMEOUT_SECONDS, 30);
  assert.equal(buildPtyRunArgs("host", "ls")[1], "30s");
});

test("buildPtyRunArgs rejects an option-like host", () => {
  assert.throws(() => buildPtyRunArgs("-V", "ls"), /host/i);
});

test("buildPtyRunArgs rejects whitespace in a host", () => {
  assert.throws(() => buildPtyRunArgs("user@bad host", "ls"), /host/i);
});

test("buildPtyRunArgs rejects an empty command", () => {
  assert.throws(() => buildPtyRunArgs("host", ""), /command/i);
});

test("buildPtyRunArgs rejects an out-of-range timeout", () => {
  assert.throws(() => buildPtyRunArgs("host", "ls", 3601), /timeout/i);
});

test("normalizeTerminalOutput converts PTY carriage returns", () => {
  assert.equal(normalizeTerminalOutput("one\r\ntwo\rthree\n"), "one\ntwo\nthree\n");
});
