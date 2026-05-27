#!/bin/bash
set -euo pipefail

WORK_CONFIG="$HOME/.config/work/config.toml"
CHEZMOI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"

if [ ! -f "$CHEZMOI_CONFIG" ]; then
    exit 0
fi

has_work_config=false
if [ -f "$WORK_CONFIG" ]; then
    has_work_config=true
fi

chezmoi_is_work=$(awk -F'=' '/^\s*is_work\s*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$CHEZMOI_CONFIG" 2>/dev/null)
chezmoi_is_work="${chezmoi_is_work:-false}"

if [ "$has_work_config" = "true" ] && [ "$chezmoi_is_work" = "false" ]; then
    echo "== Regenerating chezmoi config (is_work is stale)"
    chezmoi init
elif [ "$has_work_config" = "false" ] && [ "$chezmoi_is_work" = "true" ]; then
    echo "== Regenerating chezmoi config (is_work is stale)"
    chezmoi init
fi
