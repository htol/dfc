## ***MUST DO***

- Use 'python3' to execute scripts.
- Don't do 'git commit' or 'git push' if not directly asked for it.
- If `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`).
- Never skip git hooks (`--no-verify`).
- If hooks fail with missing module errors, use `uv run git commit`.
- In python project use venv/.venv via uv. Install dependencies from '*requirements*.txt' files if required.
- When running uv commands use `uv run` (not direct tool paths like `.venv/bin/...`).
- Most user configs are managed by chezmoi (`~/.local/share/chezmoi`). Check and edit there first, then `chezmoi apply <target-file>` (not global apply).
