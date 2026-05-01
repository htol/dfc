complete -c tt -d "Command umbrella"

# Subcommand completions
complete -c tt -f -n "__fish_use_subcommand" -a rsync -d "rsync with progress bar"
complete -c tt -f -n "__fish_use_subcommand" -a pkg -d "List and search installed packages"
complete -c tt -f -n "__fish_use_subcommand" -a ps -d "List processes with pid, user, and command"
complete -c tt -f -n "__fish_use_subcommand" -a venv -d "Activate Python virtual environment"
complete -c tt -f -n "__fish_use_subcommand" -a env -d "Load environment variables from file"

# rsync — path completions
complete -c tt -f -n "__fish_seen_subcommand_from rsync" -a "(__fish_complete_path)" -d "Source path"
complete -c tt -f -n "__fish_seen_subcommand_from rsync" -a "(__fish_complete_path)" -d "Destination path (local or remote: user@host:/path)"

# env — file completions
complete -c tt -f -n "__fish_seen_subcommand_from env" -a "(__fish_complete_path)" -d "Env file (.env by default)"

# Commands without arguments
complete -c tt -f -n "__fish_seen_subcommand_from pkg"
complete -c tt -f -n "__fish_seen_subcommand_from ps"
complete -c tt -f -n "__fish_seen_subcommand_from venv"
