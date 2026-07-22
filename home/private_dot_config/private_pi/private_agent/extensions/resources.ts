import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

export default function(pi: ExtensionAPI) {
    pi.registerCommand("resources", {
        description: "Show all discovered resources",
        handler: async (_, ctx) => {
            try {
                const opts = ctx.getSystemPromptOptions();

                const skills = (opts.skills ?? []).map(
                    ({ name, baseDir, description }) => `${name} - ${baseDir}\n    ${description}`
                );

                const tools = (pi.getAllTools() ?? []).map(
                    ({ name, sourceInfo: { source }, description }) => `${name} - ${source}\n    ${description}`
                );

                const envInfo = [
                    `cwd: ${ctx.cwd}`,
                    `trusted: ${ctx.isProjectTrusted() ? "yes" : "no"}`,
                    `context files: ${(opts.contextFiles?.map(f => f.path).join(', ')) || "none"}`
                ];


                let cfg: { skills?: string[], extensions?: string[], packages?: string[] } = {}
                try {
                    cfg = JSON.parse(
                        readFileSync(
                            join(getAgentDir(), "settings.json"), "utf-8")
                    );

                } catch { }

                const settings = [
                    `skills: ${cfg.skills?.join(', ') || "none"}`,
                    `extensions: ${cfg.extensions?.join(', ') || "none"}`,
                    `packages: ${cfg.packages?.join(', ') || "none"}`
                ];

                const directories = [
                    `extensions: ${listDir("extensions")}`,
                    `themes: ${listDir("themes")}`,
                    `prompts: ${listDir("prompts")}`,
                ];

                const out: string[] = [];
                out.push(...section("SKILLS", skills));
                out.push(...section("TOOLS", tools));
                out.push(...section("ENVIRONMENT", envInfo));
                out.push(...section("SETTINGS (settings.json)", settings));
                out.push(...section("DIRECTORIES", directories));
                ctx.ui.notify(out.join('\n'), "info");
            } catch (e) {
                ctx.ui.notify(`/resources failed: ${e instanceof Error ? e.message : String(e)}`, "error")
            }
        } // handler
    });
}

function section(name: string, lines: string[]): string[] {
    return [
        `=== ${name} ===`,
        lines.length ? lines.join('\n') : "none", ""]
}

function listDir(name: string): string {
    const dir = join(getAgentDir(), name);
    if (!existsSync(dir)) return "none";
    return readdirSync(dir).join(', ') || "none";
}

function truncate(s: string, n: number): string {
    return s.length > n ? s.slice(0, n) + "..." : s;
}
