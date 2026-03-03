function i --description "Check internet connection"
  set internet (curl -s -o /dev/null -w "%{http_code}" https://www.wikipedia.org/)

  if test $internet = "200"
    echo "Oh yeah :-)"
  else
    echo "Nope, sorry :-("
  end
end
