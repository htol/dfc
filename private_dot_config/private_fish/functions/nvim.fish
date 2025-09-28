function nvim
  set PREFIX (if set -q XDG_DATA_HOME; echo $XDG_DATA_HOME; else; echo $HOME'/.local';end)
  set CMD $PREFIX/nvim/nvim-linux-x86_64/bin/nvim
  if test -f $CMD
    $CMD $argv
  else
    /usr/bin/env nvim $argv
  end
end
