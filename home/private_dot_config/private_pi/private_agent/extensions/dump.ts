import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { writeFileSync } from "fs";

export default function(pi: ExtensionAPI) {
    pi.registerCommand("dump", {
        description: "Some debug information to dump",
        handler: async (args, ctx) => {
            // JSON.stringify(obj, (k,v) => typeof v === "function" ? "[fn]" : v, 2)
            // cat /tmp/pi-debug.json
            // jq . /tmp/pi-debug.json
            // jq '.systemPromptOptions.skills' /tmp/pi-debug.json
            // jq '.tools[] | {name, source: .sourceInfo.source}' /tmp/pi-debug.json
            writeFileSync("/tmp/pi-debug.json", JSON.stringify({
                cwd: ctx.cwd,
                trusted: ctx.isProjectTrusted(),
                systemPromptOptions: ctx.getSystemPromptOptions(),
                tools: pi.getAllTools(),
            }, null, 2));
        },
    });
}
