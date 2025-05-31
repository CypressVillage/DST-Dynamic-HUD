Assets = {}

SUPPORTED_HUD_MODS = {
    "workshop-3456159081", -- Archive HUD
    -- "workshop-2571443104", -- Celestial HUD
    -- "workshop-3285344272", -- Celestial HUD Fixed
    "workshop-3381333362", -- Merrymaker HUD
    "workshop-2226345952", -- Nautical HUD
    "workshop-1992293314", -- Nightmare HUD
    "workshop-3173870597", -- Redux HUD
    "workshop-2250176974", -- Roseate HUD
    "workshop-2954087809", -- Soul Infused HUD
    "workshop-1824509831", -- The Battle Arena HUD
    "workshop-1583765151", -- Victorian HUD

    -- "workshop-2854270129", -- Clean HUD *
    -- "workshop-2284894693", -- Pig Ruins HUD * 
    -- "workshop-2329943377", -- The Lunar HUD * 
    -- "workshop-2238885511", -- The Verdant HUD *
}

ENABLED_HUD_MODS = {}
BUILD_OVERRIDE = {}

for _, mod_id in ipairs(SUPPORTED_HUD_MODS) do
    if GLOBAL.KnownModIndex:IsModEnabled(mod_id) then
        table.insert(ENABLED_HUD_MODS, mod_id)
        modimport('assets/' .. mod_id .. '.lua')
        modimport('buildoverride/' .. mod_id .. '.lua')
    end
end

if #ENABLED_HUD_MODS == 0 then
    print("[HUD]: No supported HUD mods are enabled.")
    return
end