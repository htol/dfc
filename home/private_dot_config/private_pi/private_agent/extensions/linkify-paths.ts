/**
 * Linkify Paths Extension
 *
 * Turns bare file paths in assistant markdown into file:// markdown links so
 * pi's renderer emits clickable OSC 8 hyperlinks. Display-only: the session
 * log and the model context keep the original text.
 *
 * Rules:
 * - candidates are absolute paths, ~/ ./ ../ prefixed paths, and relative
 *   paths containing a slash; they linkify only when they resolve to an
 *   existing file under the session cwd (or absolutely)
 * - a relative path that does not resolve directly falls back to a suffix
 *   search: `rg --files` under the session cwd, and the path linkifies only
 *   when exactly one listed file ends with "/<path>" — an ambiguous or
 *   missing match stays plain text rather than link somewhere wrong
 * - inline code spans that contain exactly such a path also become links —
 *   models habitually wrap paths in backticks; fenced code blocks and other
 *   code content stay untouched
 * - existing markdown links are skipped
 * - a trailing :line or :line-range stays in the link label only — the
 *   file:// scheme cannot carry a line number
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";
import { statSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const HOME = homedir();

// Chunks that must never be linkified: fenced code, inline code, markdown
// links (captures split out at odd indices).
const PROTECT_RE = /(```[\s\S]*?```|`[^`\n]+`|\[[^\]]*\]\([^)\s]*\))/;

// Path candidate core: prefixed paths (~/, ./, ../, /) may have a single
// segment because the prefix carries the slash; bare relative paths need at
// least one "/" between segments to stay clear of prose. Optional :line or
// :line-range suffix.
const PATH_CORE =
    String.raw`(?:(?:~\/|\.{1,2}\/|\/)[\w@+.-]+(?:\/[\w@+.-]+)*|[\w@+.-]+(?:\/[\w@+.-]+)+)(?::\d+(?:-\d+)?)?`;
// Prose matching: the lookbehind keeps URL hosts and flag-like tokens from
// matching; the lookahead stops at punctuation.
const PATH_RE = new RegExp(
    String.raw`(?<![\w.~\-/@=:])` + PATH_CORE + String.raw`(?=[\s)\]}'",;:!?<>|]|$)`,
    "g",
);
// Inline code spans are matched whole, so no lookaround is needed.
const CODE_PATH_RE = new RegExp(`^${PATH_CORE}$`);

export default function (pi: ExtensionAPI) {
    let cwd = process.cwd();
    pi.on("session_start", (_event, ctx) => {
        cwd = ctx.cwd;
    });

    pi.registerMarkdownTransformer((markdown, { messageType, isStreaming }) => {
        if (isStreaming || messageType !== "assistant") return markdown;
        return markdown
            .split(PROTECT_RE)
            .map((chunk, i) => (i % 2 === 0 ? linkify(chunk) : linkifyInlineCode(chunk)))
            .join("");
    });

    function linkifyInlineCode(chunk: string): string {
        // Markdown links and fenced code blocks pass through untouched.
        if (!chunk.startsWith("`") || chunk.startsWith("```")) return chunk;
        const inner = chunk.slice(1, -1);
        if (!CODE_PATH_RE.test(inner)) return chunk;
        return buildLink(inner) ?? chunk;
    }

    function linkify(text: string): string {
        return text.replace(PATH_RE, (match) => {
            let trailing = "";
            const stripped = match.replace(/\.+$/, (dots) => {
                trailing = dots;
                return "";
            });
            const link = buildLink(stripped);
            return link === null ? match : link + trailing;
        });
    }

    // Splits a trailing :line or :line-range off `text`, resolves the path
    // against the session cwd, and returns a markdown link (the line stays in
    // the label — the file:// scheme cannot carry it). A relative path that
    // does not resolve directly gets one suffix-search chance (see header);
    // returns null when nothing resolves uniquely to an existing file.
    function buildLink(text: string): string | null {
        let path = text;
        const lineMatch = path.match(/:\d+(?:-\d+)?$/);
        if (lineMatch) path = path.slice(0, -lineMatch[0].length);
        let absolute = toAbsolute(path);
        if (!isFile(absolute)) {
            absolute = findUniqueBySuffix(path) ?? "";
            if (!absolute) return null;
        }
        return `[${text}](${pathToFileURL(absolute).href})`;
    }

    function isFile(p: string): boolean {
        try {
            return statSync(p).isFile();
        } catch {
            return false;
        }
    }

    // Deep fallback for plain relative paths (no ~, /, . prefixes, no ".."
    // segments): list files under the session cwd via `rg --files` (respects
    // .gitignore, skips hidden files) and return the absolute path when
    // exactly one listed file ends with "/<path>". Any failure — rg missing,
    // timeout, no or multiple matches — returns null (no link).
    function findUniqueBySuffix(path: string): string | null {
        const segs = path.split("/");
        if (path.startsWith("~/") || path.startsWith("/") || segs.some((s) => s === ".." || s === ".")) {
            return null;
        }
        let files: string[];
        try {
            const out = execFileSync("rg", ["--files"], {
                cwd,
                timeout: 2000,
                maxBuffer: 32 * 1024 * 1024,
                encoding: "utf8",
            });
            files = out.split("\n");
        } catch {
            return null;
        }
        const needle = `/${path}`;
        const hits = files.filter((f) => f.endsWith(needle));
        return hits.length === 1 ? resolve(cwd, hits[0]) : null;
    }

    function toAbsolute(p: string): string {
        if (p.startsWith("~/")) return resolve(HOME, p.slice(2));
        if (isAbsolute(p)) return p;
        return resolve(cwd, p);
    }
}
