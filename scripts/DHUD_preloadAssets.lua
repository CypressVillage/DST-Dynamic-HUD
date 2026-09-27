Assets = {}

SUPPORTED_HUD_MODS = {
    "workshop-3456159081", -- Archive HUD
    -- "workshop-3285344272", -- Celestial HUD Fixed 原作者删除/隐藏
    "workshop-3381333362", -- Merrymaker HUD
    "workshop-3548608555", -- Mystery HUD
    "workshop-2226345952", -- Nautical HUD
    "workshop-1992293314", -- Nightmare HUD
    "workshop-3173870597", -- Redux HUD
    "workshop-2250176974", -- Roseate HUD
    "workshop-2954087809", -- Soul Infused HUD
    "workshop-1824509831", -- The Battle Arena HUD
    "workshop-1583765151", -- Victorian HUD
    
    "workshop-2571443104", -- Celestial HUD *
    -- "workshop-2854270129", -- Clean HUD * 会影响其他HUD，废弃
    "workshop-2284894693", -- Pig Ruins HUD * 
    "workshop-2329943377", -- The Lunar HUD * 
    "workshop-2238885511", -- The Verdant HUD *
}

-- 原版 HUD 不需要单独启用的模组，始终作为可切换目标。
ENABLED_HUD_MODS = { "origin" }
BUILD_OVERRIDE = {}

-- 原版动画也使用独立的 build 名，避免与已启用 HUD 的同名 build 冲突。
modimport('assets/origin.lua')
modimport('buildoverride/origin.lua')
modimport('buildoverride/origin_banks.lua')

for _, mod_id in ipairs(SUPPORTED_HUD_MODS) do
    if GLOBAL.KnownModIndex:IsModEnabled(mod_id) then
        table.insert(ENABLED_HUD_MODS, mod_id)
        modimport('assets/' .. mod_id .. '.lua')
        modimport('buildoverride/' .. mod_id .. '.lua')
    end
end

if #ENABLED_HUD_MODS == 1 then
    print("[HUD]: No supported HUD mods are enabled; only the origin HUD is available.")
end
