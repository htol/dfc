function psudo
  set is_admin (/usr/sbin/dseditgroup -q -o checkmember -m "$(/usr/bin/stat -f%Su /dev/console)" admin)
  if string match -q -r '^no.+$' $is_admin
    /Applications/Privileges.app/Contents/MacOS/PrivilegesCLI --add &&
    /usr/bin/sudo $argv
  else
    /usr/bin/sudo $argv
  end
end
