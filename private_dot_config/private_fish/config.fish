if status is-interactive

  . ~/.config/common_env

  # Print a new line after any command
  source ~/.config/fish/functions/postexec_newline.fish

  if [ -f /opt/homebrew/bin/brew ]
      eval (/opt/homebrew/bin/brew shellenv)
  end

  if functions -q theme_gruvbox
    theme_gruvbox dark soft
  end

  if [ -f /usr/bin/keychain ]
    keychain --dir $KEYCHAIN_DIR --agents ssh id_rsa id_ed25519
  end

  set CDPATH . ~/ ~/repos ~/go/src ~/winrepos ~/.config


  begin
      if [ -f /bin/hostname ]
          set HOSTNAME (/bin/hostname)
      else if [ -f /bin/hostnamectl ]
          set HOSTNAME (/bin/hostnamectl hostname)
      else
          set HOSTNAME 'localhost'
      end
    if test -f $KEYCHAIN_DIR/$HOSTNAME-fish
        source $KEYCHAIN_DIR/$HOSTNAME-fish
    end
  end

  fnm env --shell=fish | source

  if [ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]
       export PATH="$PATH:'/Applications/Visual Studio Code.app/Contents/Resources/app/bin'"
  end

  alias serveron "ipmitool -H 192.168.55.3 -U ADMIN chassis power on"
end

# opencode
fish_add_path /home/tol/.opencode/bin
