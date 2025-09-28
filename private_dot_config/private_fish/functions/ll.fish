function ll --wraps=ls --description 'List contents of directory using long format for all files'
  if test (uname -s) = "linux-gnu"  # Is this the Ubuntu system?
      ls -alhv --group-directories-first $argv
  else
      ls -alhv $argv
  end
end
