local path_utils = require("lua.utils.path")

return function(config)
  if path_utils.is_windows then
    return
  end

  config.unix_domains = {
    {
      name = "unix",
    },
  }
end
