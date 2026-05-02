function httpbin --wraps='docker run -p 80:80 kennethreitz/httpbin' --description 'alias httpbin docker run -p 80:80 kennethreitz/httpbin'
  docker run -p 80:80 kennethreitz/httpbin $argv; 
end
