-- 原版 HUD 将分类贴图合并在同一个 atlas 中。
local function getOriginAtlasPath(atlas)
    if atlas:find("images/avatars/") then
        return "images/avatars.xml"
    elseif atlas:find("images/crafting_menu/") then
        return "images/crafting_menu.xml"
    elseif atlas:find("images/crafting_menu_icons/") then
        return "images/crafting_menu_icons.xml"
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
    "images/crafting_menu_icons.xml",
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

local function originAtlasContains(atlas, tex)
    -- 未识别的模组路径不能作为原版路径直接送入底层控件。
    if not atlas:match("^images/") or atlas:find("..", 1, true) then
        return nil
    end
    -- softresolvefilepath 会优先返回缓存路径；当其他 HUD 覆盖了同名
    -- atlas 时，即使传入空 search_first_path 也可能仍解析到模组资源。
    -- 直接遍历资源搜索路径并跳过 mods，确保结果来自游戏原始资源。
    for i = #GLOBAL.package.assetpath, 1, -1 do
        local pathdata = GLOBAL.package.assetpath[i]
        local path = pathdata.path or ""
        if not path:find("[/\\]mods[/\\]") then
            local resolved = (path..atlas):gsub("\\", "/")
            if GLOBAL.kleifileexists(resolved, pathdata.manifest, atlas)
                and GLOBAL.TheSim:AtlasContains(resolved, tex) then
                return resolved
            end
        end
    end
    return nil
end

local function getOriginTextureAtlas(atlas, tex)
    local preferred = getOriginAtlasPath(atlas) or getUnprefixedAtlasPath(atlas)
    local resolved = originAtlasContains(preferred, tex)
    if resolved then
        return resolved
    end

    -- 模组贴图的目录或文件名可能与原版不同，按 tex 名再查找原版 HUD atlas。
    for _, candidate in ipairs(originAtlases) do
        if candidate ~= preferred then
            resolved = originAtlasContains(candidate, tex)
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
        local origin = getOriginTextureAtlas(atlas, tex)
        return origin or atlas, origin ~= nil
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

    -- 单贴图 HUD 切到合并图集 HUD（如 Celestial）时，同名文件不存在，
    -- 必须先尝试目标 HUD 的合并 atlas，不能直接回退到原版。
    local origin = getOriginAtlasPath(atlas) or getUnprefixedAtlasPath(atlas)
    if origin ~= getUnprefixedAtlasPath(atlas) then
        local resolved = atlasContains("../mods/"..replacement.."/"..origin, tex)
        if resolved then
            return resolved
        end
    end

    -- 原 HUD 的 PostConstruct 不再运行，由统一入口接管第三方界面贴图。
    local special
    if tex == "status_bgs.tex" then
        special = {
            "images/combinedstatus/status_bgs2.xml",
            "images/status_bgs2.xml",
            "images/status_bgs.xml",
        }
    elseif tex == "sisturn_slot_petals.tex" then
        -- Redux 的文件名为单数，但 atlas 内元素使用原版的复数名称。
        special = { "images/hud/sisturn_slot_petal.xml" }
    elseif (tex == "tools_back.tex" or tex == "tools_back_ship.tex"
        or tex == "equip_back.tex" or tex == "equip_back_long.tex")
        and atlas:find("basic_back", 1, true) then
        special = { "images/fastequipment/basic_back2.xml" }
    end
    if special then
        for _, path in ipairs(special) do
            local resolved = atlasContains("../mods/"..replacement.."/"..path, tex)
            if resolved then
                return resolved
            end
        end
    end

    -- 从合并 atlas 切回单贴图 HUD；也兼容单贴图文件名不同的情况。
    local folder = origin:match("^images/([%w_]+)%.xml$")
    local name = tex:match("^([%w_%-]+)%.tex$")
    if folder and name then
        local resolved = atlasContains("../mods/"..replacement.."/images/"..folder.."/"..name..".xml", tex)
        if resolved then
            return resolved
        end
    end
    local origin = getOriginTextureAtlas(atlas, tex)
    return origin or atlas, origin ~= nil
end

local Image = require("widgets/image")
local _SetTexture = Image.SetTexture
Image.SetTexture = function(self, atlas, tex, ...)
    if type(atlas) ~= "string" or type(tex) ~= "string" then
        return _SetTexture(self, atlas, tex, ...)
    end
    if atlas:find("modicon.xml") then
        return _SetTexture(self, atlas, tex, ...)
    end
    -- 保存调用者请求的资源；切换时不能把上一个主题的路径当作源资源。
    self._dhud_source_atlas = atlas
    self._dhud_source_texture = tex
    local newatlas, isOrigin = ProcessAtlasPath(atlas, tex, CURRENT_HUD_MOD)
    if isOrigin then
        -- 原版 Image:SetTexture 会再次 resolvefilepath，重新命中 HUD 的
        -- 同名路径缓存。atlas 已经过原版路径和贴图校验，直接使用它。
        self.atlas = newatlas
        self.texture = tex
        self.inst.ImageWidget:SetTexture(newatlas, tex, ...)
        self.inst.UITransform:UpdateTransform()
        return
    end
    return _SetTexture(self, newatlas, tex, ...)
end

local function reloadAllTexture(widget)
    if widget == nil then
        return
    end
    
    if widget.atlas and widget.texture then
        if widget.SetTexture then
            widget:SetTexture(widget._dhud_source_atlas or widget.atlas,
                widget._dhud_source_texture or widget.texture)
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
    return ORIGIN_BUILD_OVERRIDE[originbuildname] or originbuildname
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

-- 原主题的头像 tint 原先在 PostConstruct 中永久生效，现在随主题切换恢复。
local function updateStatusTint(status)
    local themed = BUILD_OVERRIDE[CURRENT_HUD_MOD] ~= nil
        and CURRENT_HUD_MOD ~= "workshop-2284894693"
        and CURRENT_HUD_MOD ~= "workshop-2329943377"
        and CURRENT_HUD_MOD ~= "workshop-2238885511"
    for _, child in pairs(status:GetChildren()) do
        local frame = child.headframe
        if frame and frame.tint then
            if not frame._dhud_original_tint then
                frame._dhud_original_tint = { GLOBAL.unpack(frame.tint) }
            end
            if (CURRENT_HUD_MOD == "workshop-2571443104"
                or CURRENT_HUD_MOD == "workshop-2329943377")
                and (child == status.tempbadge or child == status.worldtempbadge) then
                frame:SetTint(1, 1, 1, 1)
            elseif themed then
                frame:SetTint(0.75, 0.75, 0.75, 1)
            else
                frame:SetTint(GLOBAL.unpack(frame._dhud_original_tint))
            end
        end
    end
end

AddClassPostConstruct("widgets/statusdisplays", function(self)
    self.inst:DoTaskInTime(0, function()
        updateStatusTint(self)
    end)
end)

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
        updateStatusTint(controls.status)
        
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
