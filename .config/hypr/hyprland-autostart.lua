-- Run once per compositor session, never on config reload.
return function(programs)
    hl.on("hyprland.start", function()
        hl.exec_cmd(programs.terminal)
        hl.exec_cmd("waybar")
        hl.exec_cmd("systemctl --user start hypridle.service")
        hl.exec_cmd("hyprpaper")
        hl.exec_cmd("kanshi")
        hl.exec_cmd("betterbird")
        hl.exec_cmd("keepassxc")
        hl.exec_cmd("firefox")
    end)
end
