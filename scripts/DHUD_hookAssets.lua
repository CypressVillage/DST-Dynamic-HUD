local function ProcessAtlasPath(atlas, replacement)
    if replacement == nil or replacement == "" then
        return atlas
    end
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
    if atlas:find("modicon.xml") then
        return _SetTexture(self, atlas, tex, ...)
    end
    atlas_ = ProcessAtlasPath(atlas, CURRENT_HUD_MOD)
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
    if CURRENT_HUD_MOD and BUILD_OVERRIDE[CURRENT_HUD_MOD] then
        local build_override = BUILD_OVERRIDE[CURRENT_HUD_MOD][buildname]
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

CURRENT_HUD_MOD = GetModConfigData("HUD_ON_DEFAULT_AREA")
function applyHUD(mod_id)
    local enabled = false
    for _, v in pairs(ENABLED_HUD_MODS) do
        if v == mod_id then
            enabled = true
            break
        end
    end
    if not enabled then
        print("[HUD]: HUD mod not enabled: " , mod_id)
        return
    end
    if CURRENT_HUD_MOD == mod_id then
        return
    end
    local controls = GLOBAL.ThePlayer.HUD.controls

    local pt_topright_root = controls.topright_root:GetPosition()
    controls.topright_root:MoveTo(pt_topright_root, GLOBAL.Vector3(300, 0, pt_topright_root.z), 0.3)
    
    local pt_containerroot_side = controls.containerroot_side:GetPosition()
    controls.containerroot_side:MoveTo(pt_containerroot_side, GLOBAL.Vector3(300, 0, pt_containerroot_side.z), 0.3)

    local pt_bottomright_root = controls.bottomright_root:GetPosition()
    controls.bottomright_root:MoveTo(pt_bottomright_root, GLOBAL.Vector3(300, 0, pt_bottomright_root.z), 0.3)
    
    local pt_bottom_root = controls.bottom_root:GetPosition()
    controls.bottom_root:MoveTo(pt_bottom_root, GLOBAL.Vector3(0, -200, pt_bottom_root.z), 0.3)

    local pt_left_root = controls.left_root:GetPosition()
    controls.left_root:MoveTo(pt_left_root, GLOBAL.Vector3(-800, 0, pt_left_root.z), 0.3)

    GLOBAL.ThePlayer:DoTaskInTime(0.3, function()
        CURRENT_HUD_MOD = mod_id
        -- reloadAllTexture(GLOBAL.ThePlayer.HUD) -- 性能较差，可能导致卡顿
        reloadAllTexture(controls.craftingmenu)        -- 制作栏
        reloadAllTexture(controls.inv)                 -- 物品栏
        reloadAllTexture(controls.mapcontrols)         -- 右下地图
        reloadAllTexture(controls.containerroot_side)  -- 右侧背包
        reloadAllTexture(controls.topright_root)       -- 右上角

        updateBuild(controls.clock._rim)
        updateBuild(controls.clock._anim)
        updateBuild(controls.clock._moonanim)

        updateBuild(controls.status.stomach.backing)
        updateBuild(controls.status.heart.backing)
        updateBuild(controls.status.brain.backing)

        updateBuild(controls.status.stomach.circleframe) -- 饱食度边框
        updateBuild(controls.status.heart.circleframe2) -- 血量边框
        controls.status.brain.circleframe2:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle") -- 理智边框
        controls.status.boatmeter.anim:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle") -- 船只耐久边框

        for _, container in pairs(controls.containers) do
            updateBuild(container.bganim)
        end
    end)

    GLOBAL.ThePlayer:DoTaskInTime(0.5, function()
        local pt = controls.topright_root:GetPosition()
        controls.topright_root:MoveTo(pt, pt_topright_root, 0.5)

        local pt = controls.containerroot_side:GetPosition()
        controls.containerroot_side:MoveTo(pt, pt_containerroot_side, 0.5)

        local pt = controls.bottomright_root:GetPosition()
        controls.bottomright_root:MoveTo(pt, pt_bottomright_root, 0.5)

        local pt = controls.bottom_root:GetPosition()
        controls.bottom_root:MoveTo(pt, pt_bottom_root, 0.5)

        local pt = controls.left_root:GetPosition()
        controls.left_root:MoveTo(pt, pt_left_root, 0.5)
    end)
end