#!/bin/bash

WORK_CONFIG="$HOME/.config/work/config.toml"
CHEZMOI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"

if [ ! -f "$CHEZMOI_CONFIG" ]; then
    exit 0
fi

has_work_config=false
if [ -f "$WORK_CONFIG" ]; then
    has_work_config=true
fi

chezmoi_is_work=$(awk -F'=' '/^[[:space:]]*is_work[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2}' "$CHEZMOI_CONFIG" 2>/dev/null)
chezmoi_is_work="${chezmoi_is_work:-false}"

if [ "$has_work_config" = "true" ] && [ "$chezmoi_is_work" = "false" ]; then
    echo "WARNING: ~/.config/work/config.toml exists but is_work=false in chezmoi config."
    echo "         Run 'chezmoi init' to regenerate."
    exit 1
elif [ "$has_work_config" = "false" ] && [ "$chezmoi_is_work" = "true" ]; then
    echo "WARNING: ~/.config/work/config.toml missing but is_work=true in chezmoi config."
    echo "         Run 'chezmoi init' to regenerate."
    exit 1
fi
