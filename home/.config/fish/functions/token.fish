function token --description "Generate a random token of specified length"
  set length $argv[1]

  if test -z "$length"
    set length 32
  end

  tr -dc A-Za-z0-9 < /dev/urandom | head -c $length
  echo
end
