#!/bin/bash
set -euo pipefail

STATE_FILE="${HOME}/.local/share/chezmoi-managed.state"
current=$(chezmoi managed --include=files | sort)

if [[ -f "$STATE_FILE" ]]; then
    previous=$(sort "$STATE_FILE")
    orphans=$(comm -23 <(echo "$previous") <(echo "$current"))

    if [[ -n "$orphans" ]]; then
        echo "== Cleaning orphaned files (removed from chezmoi):"
        echo "$orphans" | while read -r f; do
            target="$HOME/$f"
            if [[ -f "$target" ]]; then
                rm -v "$target"
                dir=$(dirname "$target")
                while [[ "$dir" != "$HOME" && -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; do
                    rmdir -v "$dir"
                    dir=$(dirname "$dir")
                done
            fi
        done
    fi
fi

echo "$current" > "$STATE_FILE"
