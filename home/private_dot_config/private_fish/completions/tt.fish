complete -c tt -d "Command umbrella"

# Subcommand completion
complete -c tt -f -n "__fish_use_subcommand" -a rsync -d "rsync with progress bar"

# rsync path completions
complete -c tt -f -n "__fish_seen_subcommand_from rsync" -a "(__fish_complete_path)" -d "Source path"
complete -c tt -f -n "__fish_seen_subcommand_from rsync" -a "(__fish_complete_path)" -d "Destination path (local or remote: user@host:/path)"
