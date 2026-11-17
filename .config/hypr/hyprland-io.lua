-- Monitor placement is managed by kanshi after startup.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({ input = { kb_layout = "us", follow_mouse = 1 } })
hl.device({
    name = "keychron-keychron-k3-pro",
    kb_layout = "us, us",
    kb_variant = "basic, intl",
    kb_options = "grp:win_space_toggle",
})
