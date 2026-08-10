# Global agent instructions

Single source of truth for all coding agents. `$CLAUDE_CONFIG_DIR/CLAUDE.md`,
`$CODEX_HOME/AGENTS.md` and `$PI_CODING_AGENT_DIR/AGENTS.md` are symlinks to this file; those three
variables are exported from `~/.config/common_env` and point into `~/.config`. This file is managed
by chezmoi at `home/dot_agents/AGENTS.md` — edit there and run `chezmoi apply ~/.agents/AGENTS.md`.

## MUST DO

- Prefer `uv` to run Python scripts in virtual environments. Install required dependencies there.
- If a direct Python call is required, use `python3`.
- Do not run `git commit` or `git push` unless directly asked.
- If `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`).
- Never skip Git hooks (`--no-verify`).
- If hooks fail with missing-module errors, use `uv run git commit`.
- Most user configs are managed by chezmoi (`~/.local/share/chezmoi`). Check and edit there first,
  then `chezmoi apply <target-file>` — never a global apply. Before editing any dotfile, check
  `chezmoi managed` and `chezmoi diff <target>`.
- The chezmoi repository has a PUBLIC remote (`origin` = `github.com/htol/dfc`). NEVER put
  work-related values in it — no internal hostnames, URLs, emails, registries, project or service
  names. Anything work-related goes in as a `.tmpl` gated on `.is_work`, with the actual values in
  `~/.config/work/config.toml` (a separate internal repo), wired into `[data]` via
  `home/.chezmoi.toml.tmpl` and gated in `home/.chezmoiignore`. After editing `.chezmoi.toml.tmpl`,
  run `chezmoi init` to regenerate `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply
  <target-file>`. Before writing to the chezmoi repository, grep the rendered text for internal
  identifiers; if unsure whether something counts as work-related, ask.
- Secrets never go into config files, dotfiles, or shell environment files. On macOS use Keychain
  (`security add-generic-password ... -w` with `-w` last, so it prompts and stays out of shell
  history and `ps`) and read them at runtime from a wrapper script. Let the user enter the secret
  themselves — never ask for a token's value in chat.
- Always show TODOs before any task.
- For GitLab, Atlassian (Jira/Confluence), Sourcegraph, Glean and Grafana, the ONLY allowed path is
  Toolbox MCP: discover the tool first, then call it. NEVER use `glab`/`gh`/other CLI tools, web
  fetching, or `curl` for these services without asking the user first.
- All external communication (Jira comments, MR/PR titles and descriptions, Slack messages, commit
  messages, code comments, docs) MUST be in English, regardless of the language used in chat —
  unless the user explicitly asks for a different language.

## Tool usage

- Prefer the harness's dedicated file and search tools over shell equivalents whenever one fits:
  read files with the read tool rather than `cat`/`head`/`tail`/`sed`, locate files with the
  glob/file-search tool rather than `find`/`ls`, and search contents with the grep tool rather than
  `grep`/`rg`.
- When no such tool exists and the shell is the only option, use `rg` and `rg --files`.
- Prefer tools that do not require permission prompts whenever possible.
- Avoid compound shell commands (`&&`, `||`, `;`, pipes) and command substitutions (`$(...)`) when
  separate sequential calls are practical — they do not match individual command permissions and
  trigger extra prompts.
- If a shell command unexpectedly triggers a permission prompt, flag it and suggest a narrowly
  scoped update to this file or to the agent's permission settings to prevent it in the future.

## Skills

- Shared skills live in `~/.agents/skills` (installer-managed, see `~/.agents/.skill-lock.json`).
  Install new shared skills there, not into an agent-specific directory.
- Codex and pi discover that directory natively at user level. Claude Code only reads
  `~/.claude/skills`, where the installer maintains one symlink per skill.
