/**
 * Chezmoi Guard Extension
 *
 * Intercepts write/edit/bash operations on chezmoi-managed files and redirects
 * them to the chezmoi source directory. Automatically applies changes after.
 *
 * For write/edit: transparently rewrites the path to the chezmoi source file.
 * For bash: detects common file-writing patterns and blocks with a message
 * suggesting to use the edit/write tool instead (since bash can't be transparently
 * redirected to a different path).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { homedir } from "node:os";

const HOME = homedir();

// ---------------------------------------------------------------------------
// Path helpers
// ---------------------------------------------------------------------------

function resolvePath(p: string, cwd: string): string {
	if (p.startsWith("@")) p = p.slice(1);
	p = p.replace(/^~\//, HOME + "/");
	if (!p.startsWith("/")) p = resolve(cwd, p);
	return p;
}

function isUnderHome(p: string): boolean {
	return p.startsWith(HOME + "/");
}

/** Heuristic: is this likely a user config/dotfile that should be tracked? */
function looksLikeDotfile(p: string): boolean {
	const rel = p.slice(HOME.length + 1);
	// ~/.config/..., ~/.local/...
	if (rel.startsWith(".config/") || rel.startsWith(".local/")) return true;
	// ~/.bashrc, ~/.gitconfig, ~/.profile, etc.
	if (/^\.[\w-]+$/.test(rel)) return true;
	// ~/.ssh/..., ~/.gnupg/..., etc.
	if (/^\.\w+\//.test(rel) && !rel.startsWith(".cache/") && !rel.startsWith(".npm/")) return true;
	return false;
}

// ---------------------------------------------------------------------------
// Chezmoi helpers
// ---------------------------------------------------------------------------

const sourcePathCache = new Map<string, string | null>();

function chezmoiSourcePath(target: string): string | null {
	if (sourcePathCache.has(target)) return sourcePathCache.get(target)!;
	try {
		const result = execSync(`chezmoi source-path ${JSON.stringify(target)} 2>/dev/null`, {
			encoding: "utf8",
			timeout: 5000,
		}).trim();
		const value = result || null;
		sourcePathCache.set(target, value);
		return value;
	} catch {
		sourcePathCache.set(target, null);
		return null;
	}
}

function chezmoiApply(target: string): string | null {
	try {
		return execSync(`chezmoi apply ${JSON.stringify(target)} 2>&1`, {
			encoding: "utf8",
			timeout: 10000,
		}).trim();
	} catch (e: any) {
		return e.stderr?.toString() || e.message;
	}
}

function chezmoiAdd(target: string): string | null {
	try {
		return execSync(`chezmoi add ${JSON.stringify(target)} 2>&1`, {
			encoding: "utf8",
			timeout: 10000,
		}).trim();
	} catch (e: any) {
		return e.stderr?.toString() || e.message;
	}
}

/** Clear cached source-path for a target (e.g. after `chezmoi add`). */
function invalidateCache(target: string): void {
	sourcePathCache.delete(target);
}

// ---------------------------------------------------------------------------
// Bash command parsing: extract likely write targets
// ---------------------------------------------------------------------------

/**
 * Extract file paths that a bash command is likely to write to.
 * Covers: > file, >> file, tee file, cp/mv ... dst, sed -i file, install ... dst
 * Returns absolute paths.
 */
function extractBashWriteTargets(command: string, cwd: string): string[] {
	const paths: string[] = [];

	// Redirect: > file, >> file
	const redirectMatch = command.match(/[<>]{1,2}\s*(?:&\d+\s*)?['"]?([^\s;&|>'"]+)['"]?/g);
	if (redirectMatch) {
		for (const m of redirectMatch) {
			const p = m.replace(/^[<>]+\s*/, "").replace(/^['"]|['"]$/g, "");
			if (p && !p.startsWith("&")) paths.push(resolvePath(p, cwd));
		}
	}

	// tee / tee -a file
	const teeMatch = command.match(/\btee\s+(?:-[aAp]+\s+)*['"]?([^\s;&|>'"]+)['"]?/g);
	if (teeMatch) {
		for (const m of teeMatch) {
			const p = m.replace(/^\s*tee\s+(?:-[aAp]+\s+)*/, "").replace(/^['"]|['"]$/g, "");
			if (p) paths.push(resolvePath(p, cwd));
		}
	}

	// cp / mv ... dst (last argument)
	const cpmvMatch = command.match(/\b(?:cp|mv|install)\s+(?:-[a-zA-Z]+\s+)*['"]?([^\s;&|>'"]+)['"]?\s*$/);
	if (cpmvMatch) {
		const p = cpmvMatch[1].replace(/^['"]|['"]$/g, "");
		if (p) paths.push(resolvePath(p, cwd));
	}

	// sed -i file (last argument after -i and its optional suffix)
	const sedMatch = command.match(/\bsed\s+(?:-[a-zA-Z]+\s+)*-i(?:\S*)\s+['"]?([^'"\s]+)['"]?\s*$/);
	if (sedMatch) {
		// This is tricky — sed -i 's/...//' file  vs  sed -i file 's/...//'
		// We grab the last non-option token
		const lastToken = command.trim().split(/\s+/).pop();
		if (lastToken) paths.push(resolvePath(lastToken.replace(/^['"]|['"]$/g, ""), cwd));
	}

	return paths.filter(isUnderHome);
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	// Track redirected tool calls so we can auto-apply after tool_result
	// toolCallId -> targetPath  (or "__new__:<path>" for new files)
	const pending = new Map<string, string>();

	// ---- write / edit ----

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") return undefined;

		const rawPath = event.input.path as string;
		if (!rawPath) return undefined;

		const targetPath = resolvePath(rawPath, ctx.cwd);
		if (!isUnderHome(targetPath)) return undefined;

		const sourcePath = chezmoiSourcePath(targetPath);

		if (sourcePath) {
			// Managed — redirect to source
			event.input.path = sourcePath;
			pending.set(event.toolCallId, targetPath);
			if (ctx.hasUI) {
				ctx.ui.notify(`chezmoi: → source ${sourcePath}`, "info");
			}
		} else if (!existsSync(targetPath)) {
			// New file — mark for post-create tracking prompt
			pending.set(event.toolCallId, `__new__:${targetPath}`);
		}

		return undefined;
	});

	// ---- bash ----

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		if (!command) return undefined;

		const targets = extractBashWriteTargets(command, ctx.cwd);

		for (const targetPath of targets) {
			const sourcePath = chezmoiSourcePath(targetPath);
			if (sourcePath) {
				// Block — can't transparently redirect bash writes
				return {
					block: true,
					reason:
						`"${targetPath}" is managed by chezmoi (source: ${sourcePath}).\n` +
						`Use the edit or write tool on the source file instead:\n` +
						`  edit(path: "${sourcePath}", ...)\n` +
						`Then apply with: chezmoi apply ${targetPath}`,
				};
			}
		}

		return undefined;
	});

	// ---- post-execution: apply / ask to track ----

	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") return undefined;

		const tracked = pending.get(event.toolCallId);
		if (!tracked) return undefined;
		pending.delete(event.toolCallId);

		// --- New file: ask about tracking ---
		if (tracked.startsWith("__new__:")) {
			const targetPath = tracked.slice(8);

			if (!looksLikeDotfile(targetPath)) return undefined;
			if (!ctx.hasUI) return undefined;

			const answer = await ctx.ui.confirm(
				"Chezmoi",
				`Track new file with chezmoi?\n${targetPath}`,
			);
			if (answer) {
				const err = chezmoiAdd(targetPath);
				invalidateCache(targetPath);
				if (err) {
					ctx.ui.notify(`chezmoi add failed: ${err}`, "error");
				} else {
					ctx.ui.notify(`chezmoi: tracking ${targetPath}`, "info");
				}
			}
			return undefined;
		}

		// --- Managed file: auto-apply ---
		const targetPath = tracked;
		const err = chezmoiApply(targetPath);

		if (err && ctx.hasUI) {
			ctx.ui.notify(`chezmoi apply: ${err}`, "warning");
		} else if (ctx.hasUI) {
			ctx.ui.notify(`chezmoi: applied ${targetPath}`, "info");
		}

		return undefined;
	});
}
