function gi --description "Git init project"
  git init .
  touch .gitignore
  git add .gitignore
  git commit -m "chore: init project"
end
