import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GLM_INSTRUCTION = `
<language-policy>
Do NOT use Chinese characters in your output under any circumstances.
Write entirely in the same language the user uses e.g. English or Russian.
If you need to mention a Chinese term add transliteration and translate for it.
</language-policy>
`.trim();

const GENERAL_INSTRUCTION = `
<language-policy>
All code, comments, commit messages, documentation, and repository content must be in English only.
No exceptions.
</language-policy>
`.trim();

export default function(pi: ExtensionAPI) {
    pi.on("session_start", async (_event, ctx) => {
        ctx.ui.notify("Language guard loaded", "info");
    });

    pi.on("before_agent_start", async (event, ctx) => {
        const model = ctx.model;
        if (!model) return;

        const isGlm = model.id.toLowerCase().includes("glm");

        const parts = [GENERAL_INSTRUCTION];
        if (isGlm) parts.push(GLM_INSTRUCTION);

        return {
            systemPrompt: event.systemPrompt + "\n\n" + parts.join("\n\n"),
        };
    });
}
