function nvim
  if test (uname -s) = "Linux"
      set PREFIX (if set -q XDG_DATA_HOME; echo $XDG_DATA_HOME; else; echo $HOME'/.local';end)
      $PREFIX/nvim/nvim-linux-x86_64/bin/nvim $argv
  else
      /usr/bin/env nvim $argv
  end
end
