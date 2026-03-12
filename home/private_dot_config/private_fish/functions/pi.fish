function pi --description "Run pi (from PATH or npx)"
    if command -v pi >/dev/null 2>&1
        command pi $argv
    else if command -v npx >/dev/null 2>&1
        npx pi $argv
    else
        echo "Error: pi not found in PATH or via npx" >&2
        return 1
    end
end
