-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- By default wezterm uses xterm-256color, but undercurls require custom terminfo data
config.term = "wezterm"

-- For example, changing the color scheme:
config.color_scheme = "Gruvbox dark, hard (base16)"

-- Hide the tabs at the top
config.enable_tab_bar = false

-- Disable ligatures, I fucking hate them
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Remove the default padding
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- Navigate scrollbuffer using keyboard
config.keys = {
	{ key = "k", mods = "ALT", action = wezterm.action.ScrollByLine(-1) },
	{ key = "j", mods = "ALT", action = wezterm.action.ScrollByLine(1) },
	{ key = "u", mods = "ALT", action = wezterm.action.ScrollByPage(-0.5) },
	{ key = "d", mods = "ALT", action = wezterm.action.ScrollByPage(0.5) },
}

-- Scrolling using mouse wheel is a bit too fast for me
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(-2),
		alt_buffer = true,
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(2),
		alt_buffer = true,
	},
}

-- and finally, return the configuration to wezterm
return config
