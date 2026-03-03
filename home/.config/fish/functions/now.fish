function now --description "Display current UTC date in ISO format with milliseconds"
  date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
end
