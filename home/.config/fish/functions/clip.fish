# Defined via `source`
function clip --wraps='xclip --selection clipbox' --wraps='xclip --selection clipboard' --wraps='xclip -selection clipboard' --description 'alias clip xclip -selection clipboard'
  xclip -selection clipboard $argv;
end
