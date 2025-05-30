local ModManager = GLOBAL.ModManager
local KnownModIndex = GLOBAL.KnownModIndex

Assets = {}

SUPPORTED_HUD_MODS = {
    "workshop-2250176974", -- Roseate HUD
    "workshop-2226345952", -- Nautical HUD
    "workshop-1583765151", -- Victorian HUD
}

ENABLED_HUD_MODS = {}
CURREENT_HUD_MOD = "workshop-2226345952"
BUILD_OVERRIDE = {}

for _, mod_id in ipairs(SUPPORTED_HUD_MODS) do
    if KnownModIndex:IsModEnabled(mod_id) then
        table.insert(ENABLED_HUD_MODS, mod_id)
        modimport('assets/' .. mod_id .. '.lua')
        modimport('buildoverride/' .. mod_id .. '.lua')
    end
end

if #ENABLED_HUD_MODS == 0 then
    print("[HUD]: No supported HUD mods are enabled.")
    return
end

function ProcessAtlasPath(atlas, replacement)
    -- 处理包含../mods/workshop-前缀的情况
    if atlas:find("mods/workshop") then
        -- print(111)
        return atlas:gsub("workshop%-%d+", replacement, 1)
    -- 处理不包含workshop-且不包含../的情况
    elseif not atlas:find("workshop%-") and not atlas:find("%.%.%/") then
        return "../mods/"..replacement.."/"..atlas
    end
    -- 其他情况保持原样
    return atlas
end

local Image = require("widgets/image")
local _SetTexture = Image.SetTexture -- 这个必须在其他mod执行后执行？
Image.SetTexture = function(self, atlas, tex, ...)
    atlas_ = ProcessAtlasPath(atlas, CURREENT_HUD_MOD)
    atlas_ = GLOBAL.softresolvefilepath(atlas_)
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

local function processBuildOverride(buildname)
    if buildname:find("workshop") then
        buildname = buildname:gsub("workshop%-%d+_", "", 1)
    end
    if CURREENT_HUD_MOD and BUILD_OVERRIDE[CURREENT_HUD_MOD] then
        local build_override = BUILD_OVERRIDE[CURREENT_HUD_MOD][buildname]
        if build_override then
            return build_override
        end
    end
    return buildname
end

local _SetBuild = GLOBAL.AnimState.SetBuild
GLOBAL.AnimState.SetBuild = function(self, buildname, ...)
    if buildname then
        local newbuild = processBuildOverride(buildname)
        if newbuild ~= buildname then
            return _SetBuild(self, newbuild, ...)
        end
    end
    return _SetBuild(self, buildname, ...)
end

local _OverrideSymbol = GLOBAL.AnimState.OverrideSymbol
GLOBAL.AnimState.OverrideSymbol = function(self, symbol, buildname, ...)
    if buildname then
        local newbuild = processBuildOverride(buildname)
        if newbuild ~= buildname then
            return _OverrideSymbol(self, symbol, newbuild, ...)
        end
    end
    return _OverrideSymbol(self, symbol, buildname, ...)
end

local function updateBuild(inst)
    if inst and inst.GetAnimState then
        local buildname = inst:GetAnimState():GetBuild()
        if buildname then
            local newbuild = processBuildOverride(buildname)
            if newbuild ~= buildname then
                inst:GetAnimState():SetBuild(newbuild)
            end
        end
    end
end

local function applyHUD(mod_id)
    local controls = GLOBAL.ThePlayer.HUD.controls

    local pt_cftmenu = controls.craftingmenu:GetPosition()
    controls.craftingmenu:MoveTo(pt_cftmenu, GLOBAL.Vector3(-800, 0, pt_cftmenu.z), 0.3)

    local pt_inv = controls.inv:GetPosition()
    controls.inv:MoveTo(pt_inv, GLOBAL.Vector3(0, -200, pt_inv.z), 0.3)

    local pt_mapcontrols = controls.mapcontrols:GetPosition()
    controls.mapcontrols:MoveTo(pt_mapcontrols, GLOBAL.Vector3(200, 0, pt_mapcontrols.z), 0.3)

    local pt_containerroot_side = controls.containerroot_side:GetPosition()
    controls.containerroot_side:MoveTo(pt_containerroot_side, GLOBAL.Vector3(250, 0, pt_containerroot_side.z), 0.3)
    
    local pt_topright_root = controls.topright_root:GetPosition()
    controls.topright_root:MoveTo(pt_topright_root, GLOBAL.Vector3(300, 0, pt_topright_root.z), 0.3)


    GLOBAL.ThePlayer:DoTaskInTime(0.3, function()
        CURREENT_HUD_MOD = mod_id
        -- reloadAllTexture(GLOBAL.ThePlayer.HUD) -- 性能较差，可能导致卡顿
        reloadAllTexture(controls.craftingmenu)        -- 制作栏
        reloadAllTexture(controls.inv)                 -- 物品栏
        reloadAllTexture(controls.mapcontrols)         -- 右下地图
        reloadAllTexture(controls.containerroot_side)  -- 右侧背包
        -- reloadAllTexture(controls.clock)
        reloadAllTexture(controls.topright_root)
        -- reloadAllTexture(controls.status)

        updateBuild(controls.clock._rim)
        updateBuild(controls.clock._anim)
        updateBuild(controls.clock._moonanim)
        -- updateBuild(controls.status.resurrectbuttonfx)
        -- updateBuild(controls.status.circleframe)
        -- updateBuild(controls.status.brain.anim)
        -- updateBuild(controls.status.brain.backing)
        -- updateBuild(controls.status.brain.circular_meter)
        -- updateBuild(controls.status.brain.circleframe) -- 图标
        -- updateBuild(controls.status.brain.anim_bonus)

        -- updateBuild(controls.status.brain.topperanim)
        -- updateBuild(controls.status.brain.circleframe)
        updateBuild(controls.status.stomach.circleframe) -- 饱食度边框
        updateBuild(controls.status.heart.circleframe2) -- 血量边框
        controls.status.brain.circleframe2:GetAnimState():ClearOverrideSymbol("frame_circle")
        controls.status.brain.circleframe2:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle") -- 理智边框

        for _, container in pairs(controls.containers) do
            updateBuild(container.bganim)
        end
    end)
    
    GLOBAL.ThePlayer:DoTaskInTime(0.5, function()
        local pt = controls.craftingmenu:GetPosition()
        controls.craftingmenu:MoveTo(pt, pt_cftmenu, 0.5)

        local pt = controls.inv:GetPosition()
        controls.inv:MoveTo(pt, pt_inv, 0.5)

        local pt = controls.mapcontrols:GetPosition()
        controls.mapcontrols:MoveTo(pt, pt_mapcontrols, 0.5)

        local pt = controls.containerroot_side:GetPosition()
        controls.containerroot_side:MoveTo(pt, pt_containerroot_side, 0.5)
        
        local pt = controls.topright_root:GetPosition()
        controls.topright_root:MoveTo(pt, pt_topright_root, 0.5)

    end)
end

local function OnKeyPressed(key)
    if key == 104 and not HIDE_HUD then
        if hud then
            applyHUD("workshop-2250176974")
        else
            applyHUD("workshop-1583765151")
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

HUD_EVENTS_PRIORITY = {
    AREA_CHANGE = {
        ON_DEFAULT_AREA = 1,
        ON_BOAT = 6,
    },
    TIME_CHANGE = {
        DAY = 5,
        NIGHT = 4,
        DUSK = 3,
        DAWN = 2,
    },
    EVENT_NIGHTMIRE = 1,
}

EVENT_PRIORITY = {}
for event_type, _ in pairs(HUD_EVENTS_PRIORITY) do
    if type(HUD_EVENTS_PRIORITY[event_type]) == "table" then
        for sub_event_type, priority in pairs(HUD_EVENTS_PRIORITY[event_type]) do
            EVENT_PRIORITY[sub_event_type] = 0
        end
    else
        EVENT_PRIORITY[event_type] = 0
    end
end

HUD_ = {
    ON_DEFAULT_AREA = "workshop-1583765151", -- Victorian HUD
    ON_BOAT = "workshop-2226345952", -- Nautical HUD
}

local function OnHUDEvent()
    -- find max priority
    local event
    local max_priority = 0
    for event_type, priority in pairs(EVENT_PRIORITY) do
        if priority > max_priority then
            max_priority = priority
            event = event_type
        end
    end
    -- apply HUD based on event
    if event then
        local mod_id = HUD_[event]
        if mod_id then
            applyHUD(mod_id)
        else
            print("[HUD]: No HUD mod found for event: " .. event)
        end
    else
        print("[HUD]: No active HUD events found.")
    end
end

local function updateEventPrioriity(event_type, event)
    if event_type == "AREA_CHANGE" then
        for area_event, priority in pairs(HUD_EVENTS_PRIORITY.AREA_CHANGE) do
            if area_event == event then
                EVENT_PRIORITY[area_event] = priority
            else
                EVENT_PRIORITY[area_event] = 0
            end
        end
    elseif event_type == "TIME_CHANGE" then
        for time_event, priority in pairs(HUD_EVENTS_PRIORITY.TIME_CHANGE) do
            if time_event == event then
                EVENT_PRIORITY[time_event] = priority
            else
                EVENT_PRIORITY[time_event] = 0
            end
        end
    else
        EVENT_PRIORITY[event] = HUD_EVENTS_PRIORITY[event] or 0
    end
end

local function updateHUDbyEvent(event_type, event)
    updateEventPrioriity(event_type, event)
    OnHUDEvent()
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("got_on_platform", function()
        updateHUDbyEvent("AREA_CHANGE", "ON_BOAT")
    end)
    inst:ListenForEvent("got_off_platform", function()
        updateHUDbyEvent("AREA_CHANGE", "ON_DEFAULT_AREA")
    end)
end)