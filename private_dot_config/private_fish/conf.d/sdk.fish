function sdk
        bash -c "source $HOME/.local/sdkman/bin/sdkman-init.sh && sdk $argv"
end

for ITEM in $HOME/.local/sdkman/candidates/* ;
        set -gx PATH $PATH $ITEM/current/bin
end
