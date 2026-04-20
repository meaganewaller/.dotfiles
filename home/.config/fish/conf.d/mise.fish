# Activate mise if it's available
if command -v mise >/dev/null 2>&1
  mise activate fish --shims | source
  mise activate fish | source
end
