-- HUD mod 仍由游戏注册并挂载资源；只跳过受控 HUD 的 Lua 入口执行。
local initialize = GLOBAL.ModManager.InitializeModMain
GLOBAL.ModManager.InitializeModMain = function(self, mod_id, modenv, mainfile, ...)
    if HUD_ENABLED[mod_id] then
        print("[HUD]: Skipping HUD mod code: " .. mod_id .. " / " .. tostring(mainfile))
        return true
    end
    return initialize(self, mod_id, modenv, mainfile, ...)
end
