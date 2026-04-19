---
name: chezmoi
description: "MUST load before ANY write operation (edit, write, create, delete) on dotfiles or config files under home directory, especially ~/.config and ~/.local. Most such files are chezmoi-managed — editing targets directly is silently overwritten. Provides correct workflow: source-path → edit source → apply."
---

# Chezmoi Dotfiles Management

## Overview

User configuration files are managed by **chezmoi**. The chezmoi source directory is at `~/.local/share/chezmoi/home`.
The user has a custom nvim plugin that detects managed files and opens the source file instead, then applies on save.

**Since this agent edits files directly (not through nvim), it MUST follow the workflow below.**

## Decision Tree

```
Before editing any file under ~/ (especially ~/.config, ~/.local):
│
├─ Is it managed by chezmoi?
│   └─ chezmoi source-path <target>   # returns path = managed, error = not managed
│
├─ YES (managed):
│   1. Get source: SOURCE=$(chezmoi source-path <target>)
│   2. Edit SOURCE file (may have .tmpl extension — preserve templates!)
│   3. Apply: chezmoi apply <target>
│
├─ NO (not managed):
│   1. Edit target file normally
│   2. Ask user: should this be tracked by chezmoi?
│   3. If yes: chezmoi add <target>
│
└─ NEW FILE (doesn't exist yet):
    1. Create target file
    2. Ask user: should this be tracked?
    3. If yes: chezmoi add <target>
```

## Commands Reference

### Check if managed

```bash
chezmoi source-path ~/.config/some/file
# Returns source path if managed, exit code 1 if not.

# Alternative (exit-code only, no output):
chezmoi managed ~/.config/some/file && echo "managed" || echo "not managed"
```

### Edit a managed file

```bash
SOURCE=$(chezmoi source-path ~/.config/some/file)
# Edit $SOURCE with the edit/write tool
chezmoi apply ~/.config/some/file
```

**Always specify the target path when applying.** Never run bare `chezmoi apply` — it applies ALL pending changes and can overwrite unrelated files.

### Create and track a new file

```bash
# Create the target file first
chezmoi add ~/.config/new/file
```

### Remove from chezmoi (keep target file)

```bash
chezmoi forget ~/.config/some/file
```

### Delete completely (chezmoi + target)

```bash
chezmoi destroy ~/.config/some/file
```

### Emergency: sync accidental target edits back to source

If you accidentally edited a **target** file instead of the source, use `chezmoi re-add` as a last resort:

```bash
chezmoi re-add ~/.config/some/file
```

**This should NOT happen in normal workflow.** Always edit source files.

## Templates (.tmpl)

Source files may have a `.tmpl` extension and contain Go template syntax (`{{ ... }}`).

- **Never strip or modify template directives** unless explicitly asked
- **Template variables** like `{{ .chezmoi.hostname }}` or `{{ .chezmoi.os }}` are intentional
- If unsure, check the original source before editing

## Verification

```bash
chezmoi diff ~/.config/some/file   # Show pending changes for specific file
chezmoi status                     # List ALL files that differ
```

## Committing Changes

**Always ask the user before committing.** Provide a description of changes first.

Commit only related changes from the current session:

```bash
chezmoi git add -- files-with-changes
chezmoi git commit -- -m "description of changes"
```

> **Note:** `chezmoi git` passes arguments to the underlying git command. Use `--` to separate chezmoi's arguments from git's arguments. For example, `chezmoi git commit -- -m "msg"`, `chezmoi git log -- --oneline -5`, etc.

## Error Handling

| Situation | Action |
|-----------|--------|
| `chezmoi source-path` fails | File is NOT managed — edit target directly |
| `chezmoi apply` reports conflict | Check `chezmoi diff` to understand the conflict before proceeding |
| Source file has `.tmpl` extension | Preserve all `{{ }}` template syntax |
| Unsure if file is managed | Run `chezmoi managed` or `chezmoi source-path` — never guess |
