function tt
    if test (count $argv) -eq 0
        echo "Usage: tt <command> [args...]"
        echo "Commands:"
        echo "  rsync    - rsync with progress bar"
        echo "  pkg      - list and search installed packages"
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
        case '*'
            echo "Unknown command: $subcommand"
            return 1
    end
end
