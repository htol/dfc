function tt
    if test (count $argv) -eq 0
        echo "Usage: tt <command> [args...]"
        echo "Commands:"
        echo "  rsync    - rsync with progress bar"
        echo "  pkg      - list and search installed packages"
        echo "  vea      - activate Python virtual environment"
        return 1
    end

    set subcommand $argv[1]
    set args $argv[2..-1]

    switch $subcommand
        case rsync
            if test (count $args) -lt 2
                echo "Usage: tt rsync <source_path> <destination_path>"
                return 1
            end
            rsync -avz --progress --info=progress2,name0 $args
        case pkg
            yay -Qq | fzf --preview 'yay -Qil {}' --layout=reverse --bind 'enter:execute(yay -Qil {} | less)'
        case venv
            source .venv/bin/activate.fish
        case env
            # If no file is specified, use .env by default
            set -l env_file $argv[2]
            if test -z "$env_file"
                set env_file .env
            end

            # Check if the file exists
            if not test -f "$env_file"
                echo "Error: File '$env_file' not found." >&2
                return 1
            end

            echo "Loading variables from $env_file..."

            while read -l line
                # Trim leading/trailing spaces and tabs
                set -l trimmed (string trim -- $line)

                # Skip empty lines
                if test -z "$trimmed"
                    continue
                end

                # Skip comments (the only allowed exception)
                if string match -qr '^#' $trimmed
                    continue
                end

                # STRICT VALIDATION: Only allow NAME=VALUE format
                # Name: only letters, digits and underscores; cannot start with a digit
                # Value: any text after the '=' sign
                if string match -qr '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$' $trimmed
                    # Extract name and value via regex groups
                    set -l var_name (string match -rg '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$' $trimmed)[1]
                    set -l var_value (string match -rg '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$' $trimmed)[2]

                    # Safely strip quotes (only if they wrap the entire string on both sides)
                    # Quotes inside the value are left untouched (as they should be)
                    if string match -qr '^"[^"]*"$' $var_value
                        set var_value (string sub -s 2 -e -1 $var_value)
                    else if string match -qr "^'[^']*'\$" $var_value
                        set var_value (string sub -s 2 -e -1 $var_value)
                    end

                    # Export the variable to the current session
                    set -gx $var_name $var_value

                else
                    # FOUND SOMETHING INVALID
                    echo "SECURITY ERROR: Invalid line detected in '$env_file':" >&2
                    echo "  -> $line" >&2
                    echo "Only variables (VAR=value) and comments (#) are allowed." >&2
                    return 1
                end
            end < "$env_file"

            echo "Variables loaded successfully."
            return 0
        case '*'
            echo "Unknown command: $subcommand"
            return 1
    end
end
