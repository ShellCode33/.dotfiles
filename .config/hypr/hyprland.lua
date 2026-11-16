-- Personal Hyprland configuration, migrated from hyprland.conf.
local programs = { terminal = "kitty", menu = "bemenu-run" }

hl.config({
  general = { resize_on_border = false, allow_tearing = false, layout = "master" },
  xwayland = { enabled = false },
  master = { new_status = "master" },
})

require("hyprland-theming")
require("hyprland-io")
require("hyprland-bindings")(programs)
require("hyprland-rules")
require("hyprland-autostart")(programs)
