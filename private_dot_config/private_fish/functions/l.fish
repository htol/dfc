function l --wraps=ls --description 'List contents of directory using long format'
  if test (uname -s) = "Linux"  # Is this the Ubuntu system?
      ls -lhv --group-directories-first $argv
  else
      ls -lhv $argv
  end
end
