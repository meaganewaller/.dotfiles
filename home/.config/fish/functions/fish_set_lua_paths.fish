function fish_set_lua_paths
  set -xU LUA_PATH (luarocks path --lr-path)
  set -xU LUA_CPATH (luarocks path --lr-cpath)
end
