-- Run once per compositor session, never on config reload.
return function(programs)
    hl.on("hyprland.start", function()
        hl.exec_cmd(programs.terminal)
        hl.exec_cmd("keepassxc")
        hl.exec_cmd("firefox")
        hl.exec_cmd("signal-desktop")
    end)
end
