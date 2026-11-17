-- Window rules migrated from hyprland-rules.conf.
hl.window_rule({
    name = "ignore-maximize-requests",
    suppress_event = "maximize",
    match = { class = ".*" },
})

hl.window_rule({
    name = "xwayland-fix",
    no_focus = true,
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
})

hl.window_rule({
    name = "firefox-pip",
    float = true,
    pin = true,
    size = "(monitor_w*0.33) (monitor_h*0.33)",
    move = "((monitor_w*1)-window_w-1) ((monitor_h*1)-window_h-1)",
    match = { class = "firefox", title = "Picture-in-Picture" },
})

hl.window_rule({
    name = "betterbird-notifications",
    float = true,
    pin = true,
    size = "(monitor_w*0.33) (monitor_h*0.33)",
    move = "(10) ((monitor_h*1)-window_h-10)",
    match = { class = "eu.betterbird.Betterbird", title = ".*Reminder" },
})

hl.window_rule({
    name = "flameshot-floating",
    float = true,
    match = { class = "flameshot" },
})
