if status is-interactive

  . ~/.config/common_env

  # Print a new line after any command
  source ~/.config/fish/functions/postexec_newline.fish

  if [ -f /opt/homebrew/bin/brew ]
      eval (/opt/homebrew/bin/brew shellenv)
  end

  # if functions -q theme_gruvbox
  #   theme_gruvbox dark soft
  # end

  if command -q mise
    mise activate fish | source
  end

  set CDPATH . ~/ ~/repos ~/.config


    begin
        if [ -f /bin/hostname ]
            set HOSTNAME (/bin/hostname)
        else if [ -f /bin/hostnamectl ]
            set HOSTNAME (/bin/hostnamectl hostname)
        else
            set HOSTNAME 'localhost'
        end
        # keychain: load SSH keys into a persistent ssh-agent.
        # keychain 3.0+ --eval detects $SHELL and emits fish syntax; older
        # versions emit sh only, so fall back to the generated <host>-fish file.
        if [ -f /usr/bin/keychain ] && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]
            set -l __kc (keychain --dir $KEYCHAIN_DIR --quiet --eval id_rsa id_ed25519 2>/dev/null)
            if string match -q 'set -*' -- $__kc
                eval $__kc
            else if test -f $KEYCHAIN_DIR/$HOSTNAME-fish
                source $KEYCHAIN_DIR/$HOSTNAME-fish
            end
            set -e __kc
        end
    end

  if [ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]
    fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  end

  alias serveron "ipmitool -H 192.168.55.3 -U ADMIN chassis power on"
  alias lg lazygit
end
