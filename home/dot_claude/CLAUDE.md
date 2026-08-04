## ***MUST DO***

- Always prefer `uv` to run python scripts in virtual enviroments. Install dependencies there if re required.
- If direct python call required use `python3` to execute scripts.
- Don't do 'git commit' or 'git push' if not directly asked for it.
- If `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`).
- Never skip git hooks (`--no-verify`).
- If hooks fail with missing module errors, use `uv run git commit`.
- Most user configs are managed by chezmoi (`~/.local/share/chezmoi`). Check and edit there first, then `chezmoi apply <target-file>` (not global apply). This file is itself managed (`home/dot_claude/CLAUDE.md`) — editing `~/.claude/CLAUDE.md` directly gets reverted on the next apply. Before editing any dotfile, check `chezmoi managed` / `chezmoi diff <target>`.
- The chezmoi repo has a PUBLIC remote (`origin` = `github.com/htol/dfc`). NEVER put work-related values in it — no internal hostnames, URLs, emails, registries, project or service names. Anything work-related goes in as a `.tmpl` gated on `.is_work`, with the actual values in `~/.config/work/config.toml` (a separate internal repo), wired into `[data]` via `home/.chezmoi.toml.tmpl` and gated in `home/.chezmoiignore`. After editing `.chezmoi.toml.tmpl`, run `chezmoi init` to regenerate `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply <target-file>`. Before writing to the chezmoi repo, grep the rendered text for internal identifiers; if unsure whether something counts as work-related, ask.
- Secrets never go into config files, dotfiles, or shell env files. On macOS use the keychain (`security add-generic-password ... -w` last, so it prompts and stays out of history and `ps`) and read them at runtime from a wrapper script. Let the user enter the secret themselves — never ask for a token's value in chat.
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
