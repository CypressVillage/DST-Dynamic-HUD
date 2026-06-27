-- 试图加载原始HUD的atlas路径
local function getOriginAtlasPath(atlas)
    if atlas:find("images/avatars/") then
        return "images/avatars.xml"
    elseif atlas:find("images/crafting_menu/") then
        return "images/crafting_menu.xml"
    elseif atlas:find("images/frontend/") then
        return "images/frontend.xml"
    elseif atlas:find("images/hud/") then
        return "images/hud.xml"
    elseif atlas:find("images/hud2/") then
        return "images/hud2.xml"
    elseif atlas:find("images/ui/") then
        return "images/ui.xml"
    else
        return nil
    end
end

local function getUnprefixedAtlasPath(atlas)
    return atlas:gsub("^%.%./mods/workshop%-%d+/", "", 1)
end

-- 该函数保证返回一个有效的atlas路径
local function ProcessAtlasPath(atlas, replacement)
    if replacement == nil or replacement == "" then
        return atlas
    end
    local atlas_ = atlas
    if replacement == "origin" then
        if not atlas:find("mods/workshop") then
            return atlas
        end
        atlas_ = getOriginAtlasPath(atlas) or getUnprefixedAtlasPath(atlas)
        return GLOBAL.softresolvefilepath(atlas_) or atlas
    else
        if atlas:find("mods/workshop") then
            -- 处理包含../mods/workshop-前缀的情况，即该build被本mod修改过
            -- ../mods/workshop-xxx/source.xml -> ../mods/workshop-yyy/source.xml
            atlas_ = atlas:gsub("workshop%-%d+", replacement, 1)
        elseif not atlas:find("workshop%-") and not atlas:find("%.%.%/") then
            -- 处理不包含workshop-且不包含../的情况，此时的build可能是HUD模组更改过的
            -- source.xml -> ../mods/workshop-xxx/source.xml
            atlas_ = "../mods/"..replacement.."/"..atlas
        end
        -- 如果是HUD模组没有更改过的build，此时会得到一个错误路径，交给softresolvefilepath处理
        atlas_ = GLOBAL.softresolvefilepath(atlas_, false, "")
        return atlas_ or getOriginAtlasPath(atlas) or atlas
    end
end

local Image = require("widgets/image")
local _SetTexture = Image.SetTexture -- 这个必须在其他mod执行后执行？
Image.SetTexture = function(self, atlas, tex, ...)
    if type(atlas) ~= "string" or type(tex) ~= "string" then
        return _SetTexture(self, atlas, tex, ...)
    end
    if atlas:find("modicon.xml") then
        return _SetTexture(self, atlas, tex, ...)
    end
    atlas_ = ProcessAtlasPath(atlas, CURRENT_HUD_MOD)
    print("[HUD]: SetTexture atlas: ", atlas, " -> ", atlas_)
    return _SetTexture(self, atlas_, tex, ...)
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
    if type(buildname) ~= "string" then
        return buildname
    end
    local originbuildname
    if buildname:find("workshop") then
        originbuildname = buildname:gsub("workshop%-%d+_", "", 1)
    else
        originbuildname = buildname
    end
    if CURRENT_HUD_MOD == "origin" then
        return originbuildname
    else
        if CURRENT_HUD_MOD and BUILD_OVERRIDE[CURRENT_HUD_MOD] then
            local build_override = BUILD_OVERRIDE[CURRENT_HUD_MOD][originbuildname]
            if build_override then
                return build_override
            end
        end
    end
    return originbuildname
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

local function storePositions()
    local controls = GLOBAL.ThePlayer.HUD.controls
    pt_topright_root = controls.topright_root:GetPosition()
    pt_containerroot_side = controls.containerroot_side:GetPosition()
    pt_bottomright_root = controls.bottomright_root:GetPosition()
    pt_bottom_root = controls.bottom_root:GetPosition()
    pt_left_root = controls.left_root:GetPosition()
end
shouldstoreposition = true

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

    if shouldstoreposition then
        storePositions()
        shouldstoreposition = false
    end
    if GetModConfigData("ENABLE_FLUENT_ANIM") then
        controls.topright_root:MoveTo(pt_topright_root, GLOBAL.Vector3(300, 0, pt_topright_root.z), 0.3)
        controls.containerroot_side:MoveTo(pt_containerroot_side, GLOBAL.Vector3(300, 0, pt_containerroot_side.z), 0.3)
        controls.bottomright_root:MoveTo(pt_bottomright_root, GLOBAL.Vector3(300, 0, pt_bottomright_root.z), 0.3)
        controls.bottom_root:MoveTo(pt_bottom_root, GLOBAL.Vector3(0, -200, pt_bottom_root.z), 0.3)
        controls.left_root:MoveTo(pt_left_root, GLOBAL.Vector3(-800, 0, pt_left_root.z), 0.3)
    end
    
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
        if controls.seasonclock then
            updateBuild(controls.seasonclock._rim)
            updateBuild(controls.seasonclock._anim)
        end
        
        updateBuild(controls.status.stomach.backing) -- 饱食度边框
        updateBuild(controls.status.stomach.circleframe)
        updateBuild(controls.status.heart.backing) -- 血量边框
        updateBuild(controls.status.heart.circleframe2)
        updateBuild(controls.status.brain.backing) -- 理智边框
        controls.status.brain.circleframe2:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle")
        updateBuild(controls.status.boatmeter.backing) -- 船只耐久边框
        controls.status.boatmeter.anim:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle")
        updateBuild(controls.status.moisturemeter.backing) -- 潮湿度边框
        updateBuild(controls.status.moisturemeter.circleframe)
        if controls.status.mightybadge then
            updateBuild(controls.status.mightybadge.backing) -- 大力士健身值边框
            updateBuild(controls.status.mightybadge.circleframe)
        end
        if controls.status.pethealthbadge then
            updateBuild(controls.status.pethealthbadge.backing) -- 阿比边框
            updateBuild(controls.status.pethealthbadge.circleframe)
        end
        if controls.status.werebadge then
            updateBuild(controls.status.werebadge.backing) -- 伍迪边框
        end
        if controls.status.inspirationbadge then
            updateBuild(controls.status.inspirationbadge.backing) -- 女武神激励值边框
            updateBuild(controls.status.inspirationbadge.circleframe)
        end

        for _, container in pairs(controls.containers) do
            updateBuild(container.bganim)
        end
    end)
    
    if GetModConfigData("ENABLE_FLUENT_ANIM") then
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
end
