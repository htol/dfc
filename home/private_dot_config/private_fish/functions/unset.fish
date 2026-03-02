function unset --description 'Unset env variable. Alias for `set -e` for bash compatibility.'
    for var in $argv
        set -e $var
    end
end
