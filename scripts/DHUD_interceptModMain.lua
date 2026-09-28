-- HUD mod 仍由游戏注册并挂载资源；只跳过受控 HUD 的 Lua 入口执行。
local managed = {}
for _, mod_id in ipairs(ENABLED_HUD_MODS) do
    if mod_id ~= "origin" then
        managed[mod_id] = true
    end
end

local manager = GLOBAL.ModManager
local initialize = manager.InitializeModMain
manager.InitializeModMain = function(self, mod_id, modenv, mainfile, ...)
    if managed[mod_id] then
        print("[HUD]: Skipping HUD mod code: " .. mod_id .. " / " .. tostring(mainfile))
        return true
    end
    return initialize(self, mod_id, modenv, mainfile, ...)
end
