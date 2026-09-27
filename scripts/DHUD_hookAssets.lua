-- 原版 HUD 将分类贴图合并在同一个 atlas 中。
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

local originAtlases = {
    "images/avatars.xml",
    "images/crafting_menu.xml",
    "images/frontend.xml",
    "images/hud.xml",
    "images/hud2.xml",
    "images/ui.xml",
}

local function atlasContains(atlas, tex)
    local resolved = GLOBAL.softresolvefilepath(atlas, false, "")
    if resolved and GLOBAL.TheSim:AtlasContains(resolved, tex) then
        return resolved
    end
    return nil
end

local function getOriginTextureAtlas(atlas, tex)
    local preferred = getOriginAtlasPath(atlas) or getUnprefixedAtlasPath(atlas)
    local resolved = atlasContains(preferred, tex)
    if resolved then
        return resolved
    end

    -- 模组贴图的目录或文件名可能与原版不同，按 tex 名再查找原版 HUD atlas。
    for _, candidate in ipairs(originAtlases) do
        if candidate ~= preferred then
            resolved = atlasContains(candidate, tex)
            if resolved then
                return resolved
            end
        end
    end
    return nil
end

local function ProcessAtlasPath(atlas, tex, replacement)
    if replacement == nil or replacement == "" then
        return atlas
    end
    if replacement == "origin" then
        return getOriginTextureAtlas(atlas, tex) or atlas
    end

    local candidate
    if atlas:find("mods/workshop") then
        -- 来自另一 HUD 的路径：尝试同名文件在目标 HUD 中的版本。
        candidate = atlas:gsub("workshop%-%d+", replacement, 1)
    elseif not atlas:find("workshop%-") and not atlas:find("%.%.%/") then
        candidate = "../mods/"..replacement.."/"..atlas
    end

    if candidate then
        local resolved = atlasContains(candidate, tex)
        if resolved then
            return resolved
        end
    end

    -- 从原版合并 atlas 回退后，下一次切换仍要能找到 HUD 的单贴图 atlas。
    -- 不同 HUD 对同一张图也可能使用不同文件名，因此还按 tex 名尝试一次。
    local origin = getOriginAtlasPath(atlas) or getUnprefixedAtlasPath(atlas)
    local folder = origin:match("^images/([%w_]+)%.xml$")
    local name = tex:match("^([%w_%-]+)%.tex$")
    if folder and name then
        local resolved = atlasContains("../mods/"..replacement.."/images/"..folder.."/"..name..".xml", tex)
        if resolved then
            return resolved
        end
    end
    return getOriginTextureAtlas(atlas, tex) or atlas
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
    local newatlas = ProcessAtlasPath(atlas, tex, CURRENT_HUD_MOD)
    return _SetTexture(self, newatlas, tex, ...)
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
    if buildname:find("^dhud_origin_") then
        originbuildname = buildname:gsub("^dhud_origin_", "", 1)
    elseif buildname:find("^workshop%-%d+_") then
        originbuildname = buildname:gsub("workshop%-%d+_", "", 1)
    else
        originbuildname = buildname
    end
    if CURRENT_HUD_MOD == "origin" then
        return ORIGIN_BUILD_OVERRIDE[originbuildname] or originbuildname
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

-- Bank 决定动画变换，必须与原版 build 配套，不能沿用 HUD 的同名 bank。
local logicalBanks = GLOBAL.setmetatable({}, { __mode = "k" })
local actualBanks = GLOBAL.setmetatable({}, { __mode = "k" })
local _SetBank = GLOBAL.AnimState.SetBank
local function resolveBank(bank, build)
    local mapping = ORIGIN_BANK_OVERRIDE[build]
    return mapping and mapping[bank] or bank
end
GLOBAL.AnimState.SetBank = function(self, bank, ...)
    logicalBanks[self] = bank
    local resolved = resolveBank(bank, self:GetBuild())
    actualBanks[self] = resolved
    return _SetBank(self, resolved, ...)
end

local _SetBuild = GLOBAL.AnimState.SetBuild
GLOBAL.AnimState.SetBuild = function(self, buildname, ...)
    if buildname then
        local newbuild = processBuildOverride(buildname)
        if logicalBanks[self] then
            local bank = resolveBank(logicalBanks[self], newbuild)
            if actualBanks[self] ~= bank then
                _SetBank(self, bank)
                actualBanks[self] = bank
            end
        end
        return _SetBuild(self, newbuild, ...)
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

local function updateAllBuilds(widget)
    if widget == nil then
        return
    end
    updateBuild(widget)
    if widget.children then
        for _, child in pairs(widget.children) do
            updateAllBuilds(child)
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
local currentHudEnabled = CURRENT_HUD_MOD == "origin"
for _, mod_id in ipairs(ENABLED_HUD_MODS) do
    if mod_id == CURRENT_HUD_MOD then
        currentHudEnabled = true
        break
    end
end
if not currentHudEnabled then
    CURRENT_HUD_MOD = "origin"
end

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
        -- 状态栏有很多子组件；只更新边框会留下旧 HUD 的 anim / icon 等 build。
        updateAllBuilds(controls.status)
        
        updateBuild(controls.clock._rim)
        updateBuild(controls.clock._anim)
        updateBuild(controls.clock._moonanim)
        -- 切换 bank 后重新播放当前时段的循环装饰，不能只换 build。
        local clock = controls.clock
        if clock._anim and clock._phase then
            clock._anim:GetAnimState():PlayAnimation("idle_"..clock._phase, true)
        end
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
