local ModManager = GLOBAL.ModManager
local KnownModIndex = GLOBAL.KnownModIndex

Assets = {}

SUPPORTED_HUD_MODS = {
    "workshop-2250176974", -- Roseate HUD
    "workshop-2226345952", -- Nautical HUD
}

ENABLED_HUD_MODS = {}
CURREENT_HUD_MOD = "workshop-2226345952"

for _, mod_id in ipairs(SUPPORTED_HUD_MODS) do
    if KnownModIndex:IsModEnabled(mod_id) then
        table.insert(ENABLED_HUD_MODS, mod_id)
        modimport('assets/' .. mod_id .. '.lua')
    end
end

if #ENABLED_HUD_MODS == 0 then
    print("[HUD]: No supported HUD mods are enabled.")
    return
end

function ProcessAtlasPath(atlas, replacement)
    -- 处理包含../mods/workshop-前缀的情况
    if atlas:find("mods/workshop") then
        print(111)
        return atlas:gsub("workshop%-%d+", replacement, 1)
    -- 处理不包含workshop-且不包含../的情况
    elseif not atlas:find("workshop%-") and not atlas:find("%.%.%/") then
        return "../mods/"..replacement.."/"..atlas
    end
    -- 其他情况保持原样
    return atlas
end

local Image = require("widgets/image")
local _SetTexture = Image.SetTexture
Image.SetTexture = function(self, atlas, tex, ...)
    print("HUDDDDDDDDDDDDDDDDDDDD")
    atlas_ = ProcessAtlasPath(atlas, CURREENT_HUD_MOD)
    atlas_ = GLOBAL.softresolvefilepath(atlas_)
    print("atlas:", atlas)
    print("atlas_:", atlas_)
    print("tex:", tex)
    atlas = atlas_ or atlas
    return _SetTexture(self, atlas, tex, ...)
end

local function reloadAllTexture(widget)
    if widget == nil then
        return
    end

    if widget.atlas and widget.texture then
        if widget.SetTexture then
            widget:SetTexture(widget.atlas, widget.texture)
        end
    end
    
    if widget.children then
        for k, v in pairs(widget.children) do
            reloadAllTexture(v)
        end
    end
end



local function applyHUD(mod_id)
    local pt_cftmenu = GLOBAL.ThePlayer.HUD.controls.craftingmenu:GetPosition()
    GLOBAL.ThePlayer.HUD.controls.craftingmenu:MoveTo(pt_cftmenu, GLOBAL.Vector3(-800, 0, pt_cftmenu.z), 0.3)
    local pt_inv = GLOBAL.ThePlayer.HUD.controls.inv:GetPosition()
    GLOBAL.ThePlayer.HUD.controls.inv:MoveTo(pt_cftmenu, GLOBAL.Vector3(0, -200, pt_cftmenu.z), 0.3)

    GLOBAL.ThePlayer:DoTaskInTime(0.3, function()
        CURREENT_HUD_MOD = mod_id
        -- reloadAllTexture(GLOBAL.ThePlayer.HUD) -- 性能较差，可能导致卡顿
        reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.craftingmenu)
        reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.inv)
        reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.clock)
        -- reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.status)
    end)
    
    GLOBAL.ThePlayer:DoTaskInTime(0.5, function()
        local pt = GLOBAL.ThePlayer.HUD.controls.craftingmenu:GetPosition()
        GLOBAL.ThePlayer.HUD.controls.craftingmenu:MoveTo(pt, pt_cftmenu, 0.5)
        local pt = GLOBAL.ThePlayer.HUD.controls.inv:GetPosition()
        GLOBAL.ThePlayer.HUD.controls.inv:MoveTo(pt, pt_inv, 0.5)
    end)
end

local function OnKeyPressed(key)
    if key == 104 and not HIDE_HUD then
        if hud then
            applyHUD("workshop-2250176974")
        else
            applyHUD("workshop-2226345952")
        end
		hud = not hud
	end
end

local function OnRawKey(key, down)
  	if (key and not down) then
      	OnKeyPressed(key)
  	end
end

local function ControlsPostConstruct(inst)
	inst.handler = GLOBAL.TheInput:AddKeyHandler(function(key, down) OnRawKey(key, down) end )
end
AddClassPostConstruct("widgets/controls", ControlsPostConstruct)