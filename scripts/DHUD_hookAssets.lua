-- 资源路径解析
-- 原版 HUD 将分类贴图合并在同一个 atlas 中。
local originalHUDAtlases = {
    "images/avatars.xml",
    "images/crafting_menu.xml",
    "images/crafting_menu_icons.xml",
    "images/frontend.xml",
    "images/hud.xml",
    "images/hud2.xml",
    "images/ui.xml",
}

local function findOriginalAtlasPath(atlas)
    for _, path in ipairs(originalHUDAtlases) do
        if atlas:find(path:sub(1, -5).."/", 1, true) then
            return path
        end
    end
end

local function stripWorkshopPrefix(atlas)
    return atlas:gsub("^%.%./mods/workshop%-%d+/", "", 1)
end

local function findAtlasContainingTexture(atlas, tex)
    local resolved = GLOBAL.softresolvefilepath(atlas, false, "")
    if resolved and GLOBAL.TheSim:AtlasContains(resolved, tex) then
        return resolved
    end
    return nil
end

local function findOriginalAtlasContainingTexture(atlas, tex)
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

local function findOriginalTextureAtlas(atlas, tex)
    local preferred = findOriginalAtlasPath(atlas) or stripWorkshopPrefix(atlas)
    local resolved = findOriginalAtlasContainingTexture(preferred, tex)
    if resolved then
        return resolved
    end

    -- 模组贴图的目录或文件名可能与原版不同，按 tex 名再查找原版 HUD atlas。
    for _, candidate in ipairs(originalHUDAtlases) do
        if candidate ~= preferred then
            resolved = findOriginalAtlasContainingTexture(candidate, tex)
            if resolved then
                return resolved
            end
        end
    end
    return nil
end

local function findMatchingTextureAtlas(atlas, tex, modId)
    if atlas:find("mods/workshop") then
        -- 来自另一 HUD 的路径：尝试同名文件在目标 HUD 中的版本。
        return findAtlasContainingTexture(atlas:gsub("workshop%-%d+", modId, 1), tex)
    elseif not atlas:find("workshop%-") and not atlas:find("%.%.%/") then
        return findAtlasContainingTexture("../mods/"..modId.."/"..atlas, tex)
    end
end

local function getSpecialTextureAtlasPaths(atlas, tex)
    if tex == "status_bgs.tex" then
        return {
            "images/combinedstatus/status_bgs2.xml",
            "images/status_bgs2.xml",
            "images/status_bgs.xml",
        }
    elseif tex == "sisturn_slot_petals.tex" then
        -- Redux 的文件名为单数，但 atlas 内元素使用原版的复数名称。
        return { "images/hud/sisturn_slot_petal.xml" }
    elseif (tex == "tools_back.tex" or tex == "tools_back_ship.tex"
        or tex == "equip_back.tex" or tex == "equip_back_long.tex")
        and atlas:find("basic_back", 1, true) then
        return { "images/fastequipment/basic_back2.xml" }
    end
end

local function findTextureAtlasInHUD(atlas, tex, modId)
    local resolved = findMatchingTextureAtlas(atlas, tex, modId)
    if resolved then
        return resolved
    end
    -- 单贴图 HUD 切到合并图集 HUD（如 Celestial）时，同名文件不存在，
    -- 必须先尝试目标 HUD 的合并 atlas，不能直接回退到原版。
    local originalAtlas = findOriginalAtlasPath(atlas) or stripWorkshopPrefix(atlas)
    if originalAtlas ~= stripWorkshopPrefix(atlas) then
        resolved = findAtlasContainingTexture("../mods/"..modId.."/"..originalAtlas, tex)
        if resolved then
            return resolved
        end
    end

    -- 原 HUD 的 PostConstruct 不再运行，由统一入口接管第三方界面贴图。
    local special = getSpecialTextureAtlasPaths(atlas, tex)
    if special then
        for _, path in ipairs(special) do
            resolved = findAtlasContainingTexture("../mods/"..modId.."/"..path, tex)
            if resolved then
                return resolved
            end
        end
    end

    -- 从合并 atlas 切回单贴图 HUD；也兼容单贴图文件名不同的情况。
    local folder = originalAtlas:match("^images/([%w_]+)%.xml$")
    local name = tex:match("^([%w_%-]+)%.tex$")
    if folder and name then
        resolved = findAtlasContainingTexture("../mods/"..modId.."/images/"..folder.."/"..name..".xml", tex)
        if resolved then
            return resolved
        end
    end
end

local function resolveTextureAtlasForHUD(atlas, tex, modId)
    if modId == nil or modId == "" then
        return atlas
    end
    if modId ~= "origin" then
        local resolved = findTextureAtlasInHUD(atlas, tex, modId)
        if resolved then
            return resolved
        end
    end
    local originalAtlas = findOriginalTextureAtlas(atlas, tex)
    return originalAtlas or atlas, originalAtlas ~= nil
end

-- 根据逻辑 build 名解析当前主题实际使用的 build 名。
local function getLogicalBuildName(buildname)
    if buildname:find("^dhud_origin_") then
        return buildname:gsub("^dhud_origin_", "", 1)
    elseif buildname:find("^workshop%-%d+_") then
        return buildname:gsub("workshop%-%d+_", "", 1)
    end
    return buildname
end

local function resolveCurrentHUDBuildName(buildname)
    if type(buildname) ~= "string" then
        return buildname
    end
    local baseName = getLogicalBuildName(buildname)
    local themedBuilds = BUILD_OVERRIDE[CURRENT_HUD_MOD]
    if CURRENT_HUD_MOD ~= "origin" and themedBuilds and themedBuilds[baseName] then
        return themedBuilds[baseName]
    end
    return ORIGIN_BUILD_OVERRIDE[baseName] or baseName
end

-- HUD Apply 刷新已有动画控件时复用相同的 build 映射逻辑。
HUD_ASSET_RESOLVER = {
    ResolveBuildName = resolveCurrentHUDBuildName,
}

-- Hooks：将解析器接入游戏的贴图与动画资源设置接口。
local Image = require("widgets/image")
local originalSetTexture = Image.SetTexture
Image.SetTexture = function(self, atlas, tex, ...)
    if type(atlas) ~= "string" or type(tex) ~= "string"
        or atlas:find("modicon.xml") then
        return originalSetTexture(self, atlas, tex, ...)
    end

    -- 保存最初请求的路径，主题切换时始终从它重新解析。
    self._dhud_source_atlas = atlas
    self._dhud_source_texture = tex
    local resolvedAtlas, isOriginalAtlas = resolveTextureAtlasForHUD(
        atlas, tex, CURRENT_HUD_MOD)
    if isOriginalAtlas then
        -- 绕过 Image:SetTexture 的二次 resolve，避免缓存命中 HUD 同名资源。
        self.atlas = resolvedAtlas
        self.texture = tex
        self.inst.ImageWidget:SetTexture(resolvedAtlas, tex, ...)
        self.inst.UITransform:UpdateTransform()
        return
    end
    return originalSetTexture(self, resolvedAtlas, tex, ...)
end

-- Bank 决定动画变换，必须与原版 build 配套，不能沿用 HUD 的同名 bank。
local logicalBanks = GLOBAL.setmetatable({}, { __mode = "k" })
local actualBanks = GLOBAL.setmetatable({}, { __mode = "k" })
local originalSetBank = GLOBAL.AnimState.SetBank
local originalSetBuild = GLOBAL.AnimState.SetBuild
local originalOverrideSymbol = GLOBAL.AnimState.OverrideSymbol

local function resolveBankForBuild(bank, build)
    local mapping = ORIGIN_BANK_OVERRIDE[build]
    return mapping and mapping[bank] or bank
end

GLOBAL.AnimState.SetBank = function(self, bank, ...)
    logicalBanks[self] = bank
    local resolvedBank = resolveBankForBuild(bank, self:GetBuild())
    actualBanks[self] = resolvedBank
    return originalSetBank(self, resolvedBank, ...)
end

GLOBAL.AnimState.SetBuild = function(self, buildname, ...)
    if buildname then
        local resolvedBuild = resolveCurrentHUDBuildName(buildname)
        if logicalBanks[self] then
            local resolvedBank = resolveBankForBuild(logicalBanks[self], resolvedBuild)
            if actualBanks[self] ~= resolvedBank then
                originalSetBank(self, resolvedBank)
                actualBanks[self] = resolvedBank
            end
        end
        return originalSetBuild(self, resolvedBuild, ...)
    end
    return originalSetBuild(self, buildname, ...)
end

GLOBAL.AnimState.OverrideSymbol = function(self, symbol, buildname, ...)
    if buildname then
        local resolvedBuild = resolveCurrentHUDBuildName(buildname)
        if resolvedBuild ~= buildname then
            return originalOverrideSymbol(self, symbol, resolvedBuild, ...)
        end
    end
    return originalOverrideSymbol(self, symbol, buildname, ...)
end
