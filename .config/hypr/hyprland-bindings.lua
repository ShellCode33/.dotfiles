-- Keybindings migrated from hyprland-bindings.conf.
return function(programs)
    hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(programs.terminal))
    hl.bind("SUPER + X", hl.dsp.exec_cmd(programs.menu))
    hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
    -- Monocle mode: maximize and let newly focused windows take over.
    -- Replaces the helper script's removed new_window_takes_over_fullscreen option.
    hl.bind("SUPER + F", function()
        local window = hl.get_active_window()
        if not window then
            return
        end
        local entering = window.fullscreen_client ~= 1
        hl.config({
            misc = {
                on_focus_under_fullscreen = entering and 1 or 2,
                exit_window_retains_fullscreen = entering and 1 or 0,
            },
        })
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
    end)
    hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
    hl.bind("SUPER + h", hl.dsp.focus({ direction = "left" }))
    hl.bind("SUPER + l", hl.dsp.focus({ direction = "right" }))
    hl.bind("SUPER + j", hl.dsp.layout("cyclenext"))
    hl.bind("SUPER + k", hl.dsp.layout("cycleprev"))
    hl.bind("SUPER + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
    hl.bind("SUPER + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
    hl.bind("SUPER + SHIFT + j", hl.dsp.layout("swapnext"))
    hl.bind("SUPER + SHIFT + k", hl.dsp.layout("swapprev"))
    hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
    hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
    hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
    hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
    hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }))
    hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "6" }))
    hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }))
    hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "8" }))
    hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "9" }))
    hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
    hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
    hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
    hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
    hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
    hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
    hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
    hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
    hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
    hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))
    hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
    hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
    hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
    hl.bind(
        "XF86AudioRaiseVolume",
        hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        { repeating = true, locked = true }
    )
    hl.bind(
        "XF86AudioLowerVolume",
        hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        { repeating = true, locked = true }
    )
    hl.bind(
        "XF86MonBrightnessUp",
        hl.dsp.exec_cmd("brightnessctl s 10%+ && ddcutil setvcp 10 + 10"),
        { repeating = true, locked = true }
    )
    hl.bind(
        "XF86MonBrightnessDown",
        hl.dsp.exec_cmd("brightnessctl s 10%- && ddcutil setvcp 10 - 10"),
        { repeating = true, locked = true }
    )
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
    hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"))
end
