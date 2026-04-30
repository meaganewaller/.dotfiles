local wezterm = require("wezterm")
local nf = wezterm.nerdfonts

local M = {
  ["bash"] = nf.cod_terminal_bash,
	["btm"] = nf.mdi_chart_donut_variant,
	["cargo"] = nf.dev_rust,
	["curl"] = nf.mdi_flattr,
	["docker"] = nf.linux_docker,
	["docker-compose"] = nf.linux_docker,
  ["fish"] = nf.dev_terminal_fish,
	["gh"] = nf.dev_github_badge,
	["git"] = nf.fa_git,
	["go"] = nf.seti_go,
	["htop"] = nf.mdi_chart_donut_variant,
	["kubectl"] = nf.linux_docker,
	["kuberlr"] = nf.linux_docker,
	["lazydocker"] = nf.linux_docker,
	["lazygit"] = nf.oct_git_compare,
	["lua"] = nf.seti_lua,
	["make"] = nf.seti_makefile,
	["node"] = nf.mdi_hexagon,
	["nvim"] = nf.custom_vim,
	["psql"] = "󱤢",
	["ruby"] = nf.cod_ruby,
	["stern"] = nf.linux_docker,
	["sudo"] = nf.fa_hashtag,
	["usql"] = "󱤢",
	["vim"] = nf.dev_vim,
	["wget"] = nf.mdi_arrow_down_box,
	["zsh"] = nf.dev_terminal,
	["sh"] = nf.cod_terminal_bash,
	[".nh-wrapped"] = "󱄅",
}

return M