## ***MUST DO***

- Always prefer `uv` to run python scripts in virtual enviroments. Install dependencies there if re required.
- If direct python call required use `python3` to execute scripts.
- Don't do 'git commit' or 'git push' if not directly asked for it.
- If `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`).
- Never skip git hooks (`--no-verify`).
- If hooks fail with missing module errors, use `uv run git commit`.
- Most user configs are managed by chezmoi (`~/.local/share/chezmoi`). Check and edit there first, then `chezmoi apply <target-file>` (not global apply).
- Always show todos before any task.
- For GitLab, Atlassian (Jira/Confluence), Sourcegraph, Glean, and Grafana — the ONLY allowed path is Toolbox MCP: call `mcp__Toolbox-Preview__search_tools` to find the tool, then `mcp__Toolbox-Preview__call_tool` to run it. NEVER use `glab`/`gh`/other CLI tools, WebFetch, or curl for these services without asking the user first.
- All external communication (Jira comments, MR/PR titles/descriptions, Slack messages, commit messages, code comments, docs) MUST be in English, regardless of the language used in chat — unless the user explicitly asks for a different language.

## ***Tool Usage***

- Never use cat, head, tail, or sed via Bash to read files — always use the Read tool instead
- Never use find or ls via Bash to search for files — use Glob instead
- Never use grep or rg to search file contents — use Grep instead

- Prefer tools that don't require Bash permission prompts whenever possible
- When using Bash, avoid compound commands (&&, ||, ;, pipes) and command substitutions ($()) — these don't match individual command permissions and trigger extra prompts. Use separate sequential tool calls instead.
- If a Bash command unexpectedly triggers a permission prompt, flag it and suggest an update to this guidance or to settings.json permissions to prevent it in the future.
