local wez = require("wezterm")
local colors = require("colors")

local theme = colors["lavi"]

local M = {}

function M.setup()
	wez.on("update-status", function(window, pane)
		local stat = window:active_workspace()
		local left_background = theme.brights[1]
		local left_foreground = theme.brights[8]
		local nf = require("utils.nerdfont-icons") ---@class NerdFontIcons

		if window:active_key_table() then
			stat = window:active_key_table()
			left_background = theme.ansi[4]
		end

		if window:leader_is_active() then
			left_background = theme.ansi[2]
		end

		local basename = function(s)
			return string.gsub(s, "(.*[/\\])(.*)", "%2")
		end

		local cwd = pane:get_current_working_dir()

		if cwd then
			if type(cwd) == "userdata" then
				cwd = basename(cwd.file_path)
			else
				cwd = basename(cwd)
			end
		else
			cwd = ""
		end

		local cmd = pane:get_foreground_process_name()
		cmd = cmd and basename(cmd) or ""

		local time = wez.strftime("%l:%M%p")

		window:set_left_status(wez.format({
			{ Background = { Color = left_background } },
			{ Foreground = { Color = left_foreground } },
			{ Text = nf.Separators.TabBar.workspace .. " " .. stat .. nf.Separators.TabBar.heart },
			{ Foreground = { Color = left_background } },
			{ Background = { Color = theme.background } },
			{ Text = nf.Separators.TabBar.right },
			{ Text = " " },
		}))

		-- Right status
		window:set_right_status(wez.format({
			-- Wezterm has a built-in nerd fonts
			-- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
			{ Background = { Color = theme.background } },
			{ Foreground = { Color = left_background } },
			{ Text = wez.nerdfonts.md_folder .. "  " .. cwd },
			{ Text = " | " },
			{ Background = { Color = theme.background } },
			{ Foreground = { Color = "#e0af68" } },
			{ Text = wez.nerdfonts.fa_code .. "  " .. cmd },
			"ResetAttributes",
			{ Background = { Color = theme.background } },
			{ Text = " | " },
			{ Text = wez.nerdfonts.md_clock .. "  " .. time },
			{ Text = "  " },
		}))
	end)
end

return M
