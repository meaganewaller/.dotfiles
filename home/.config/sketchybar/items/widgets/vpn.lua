-- VPN status widget for sketchybar
-- Shows lock/unlock icon based on VPN connection status

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local vpn = sbar.add("item", "widgets.vpn", {
  position = "right",
  icon = {
    string = icons.vpn.unlocked,
    color = colors.c_vpn,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 17.0,
    },
  },
  label = { drawing = false },
  update_freq = 5,
  popup = { align = "right" },
})

local vpn_popup = sbar.add("item", {
  position = "popup." .. vpn.name,
  icon = { drawing = false },
  label = {
    string = "VPN Status",
    color = colors.text,
  },
  background = {
    color = colors.bar.bg,
    height = 24,
  },
})

-- Check VPN status
local function check_vpn_status()
  -- Check for common VPN interfaces and processes
  -- This checks for: utun interfaces (common for VPNs), Cisco AnyConnect, OpenVPN, etc.
  sbar.exec([[
    # Check for active VPN interfaces
    if ifconfig | grep -q "utun[0-9]"; then
      echo "connected"
      exit 0
    fi

    # Check for Cisco AnyConnect
    if pgrep -x "vpnagentd" > /dev/null 2>&1; then
      if /opt/cisco/secureclient/bin/vpn state 2>/dev/null | grep -q "Connected"; then
        echo "connected"
        exit 0
      fi
    fi

    # Check for OpenVPN
    if pgrep -x "openvpn" > /dev/null 2>&1; then
      echo "connected"
      exit 0
    fi

    # Check for WireGuard
    if command -v wg > /dev/null 2>&1 && wg show 2>/dev/null | grep -q "interface"; then
      echo "connected"
      exit 0
    fi

    # Check for Tailscale
    if command -v tailscale > /dev/null 2>&1; then
      if tailscale status 2>/dev/null | grep -q "offers exit node"; then
        echo "connected"
        exit 0
      fi
    fi

    echo "disconnected"
  ]], function(result)
    local connected = result:match("connected") ~= nil

    vpn:set({
      icon = {
        string = connected and icons.vpn.locked or icons.vpn.unlocked,
        color = connected and colors.success or colors.c_vpn,
      },
    })

    vpn_popup:set({
      label = connected and "VPN: Connected" or "VPN: Disconnected",
    })
  end)
end

-- Subscribe to routine updates
vpn:subscribe({ "routine", "forced", "system_woke" }, check_vpn_status)

-- Show popup on hover
vpn:subscribe("mouse.entered", function(env)
  vpn:set({ popup = { drawing = true } })
end)

vpn:subscribe("mouse.exited", function(env)
  vpn:set({ popup = { drawing = false } })
end)

-- Bracket for consistent styling
sbar.add("bracket", "widgets.vpn.bracket", { vpn.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.vpn.padding", {
  position = "right",
  width = settings.group_paddings,
})
