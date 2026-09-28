-- HUD Apply：更新当前主题，并刷新已经创建的 HUD 控件。

-- 图片 texture
local function refreshTextureTree(widget)
    if widget == nil then
        return
    end

    if widget.atlas and widget.texture and widget.SetTexture then
        widget:SetTexture(widget._dhud_source_atlas or widget.atlas,
            widget._dhud_source_texture or widget.texture)
    end

    if widget.children then
        for _, child in pairs(widget.children) do
            refreshTextureTree(child)
        end
    end
end

local function refreshTextures(controls)
    -- 全量遍历 HUD 会卡顿，只刷新切换时需要更新的子树。
    refreshTextureTree(controls.craftingmenu)       -- 左侧制作栏
    refreshTextureTree(controls.inv)                -- 下方物品栏
    refreshTextureTree(controls.mapcontrols)        -- 右下地图
    refreshTextureTree(controls.containerroot_side) -- 右侧背包
    refreshTextureTree(controls.topright_root)      -- 右上角
end

-- 动画 build
local function refreshBuild(widget)
    if widget and widget.GetAnimState then
        local animState = widget:GetAnimState()
        local buildname = animState:GetBuild()
        if buildname then
            local newbuild = HUD_ASSET_RESOLVER.ResolveBuildName(buildname)
            if newbuild ~= buildname then
                animState:SetBuild(newbuild)
            end
        end
    end
end

local function refreshBuildTree(widget)
    if widget == nil then
        return
    end
    refreshBuild(widget)
    if widget.children then
        for _, child in pairs(widget.children) do
            refreshBuildTree(child)
        end
    end
end

local function refreshStatusBuilds(status)
    -- 普通子控件先递归刷新；显式引用用于覆盖不在 children 树中的控件。
    refreshBuildTree(status)
    refreshBuild(status.stomach.backing) -- 饱食度边框
    refreshBuild(status.stomach.circleframe)
    refreshBuild(status.heart.backing) -- 血量边框
    refreshBuild(status.heart.circleframe2)
    refreshBuild(status.brain.backing) -- 理智边框
    status.brain.circleframe2:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle")
    refreshBuild(status.boatmeter.backing) -- 船只耐久边框
    status.boatmeter.anim:GetAnimState():OverrideSymbol("frame_circle", "status_meter", "frame_circle")
    refreshBuild(status.moisturemeter.backing) -- 潮湿度边框
    refreshBuild(status.moisturemeter.circleframe)

    local optionalBadges = {
        { status.mightybadge, true },       -- 大力士健身值
        { status.pethealthbadge, true },    -- 阿比
        { status.werebadge, false },        -- 伍迪
        { status.inspirationbadge, true }, -- 女武神激励值
    }
    for _, entry in ipairs(optionalBadges) do
        local badge, hasCircle = entry[1], entry[2]
        if badge then
            refreshBuild(badge.backing)
            if hasCircle then
                refreshBuild(badge.circleframe)
            end
        end
    end
end

local function refreshClockBuilds(controls)
    local clock = controls.clock
    refreshBuild(clock._rim)
    refreshBuild(clock._anim)
    refreshBuild(clock._moonanim)
    -- 切换 bank 后重新播放当前时段的循环装饰，不能只换 build。
    if clock._anim and clock._phase then
        clock._anim:GetAnimState():PlayAnimation("idle_"..clock._phase, true)
    end
    if controls.seasonclock then
        refreshBuild(controls.seasonclock._rim)
        refreshBuild(controls.seasonclock._anim)
    end
end

local function refreshContainerBuilds(containers)
    for _, container in pairs(containers) do
        refreshBuild(container.bganim)
    end
end

local function refreshBuilds(controls)
    refreshStatusBuilds(controls.status)
    refreshClockBuilds(controls)
    refreshContainerBuilds(controls.containers)
end

-- 头像 tint 是主题外观属性，不属于 texture 或 build 替换。
local function refreshStatusTint(status)
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
        refreshStatusTint(self)
    end)
end)

local function refreshHUD(controls)
    refreshTextures(controls)
    refreshBuilds(controls)
    refreshStatusTint(controls.status)
end

CURRENT_HUD_MOD = GetModConfigData("HUD_ON_DEFAULT_AREA")
if not HUD_ENABLED[CURRENT_HUD_MOD] then
    CURRENT_HUD_MOD = "origin"
end

function applyHUD(mod_id)
    if not HUD_ENABLED[mod_id] then
        print("[HUD]: HUD mod not enabled: ", mod_id)
        return
    end
    if CURRENT_HUD_MOD == mod_id then
        return
    end
    local controls = GLOBAL.ThePlayer.HUD.controls

    HUD_ANIMATION.StorePositions(controls)
    if GetModConfigData("ENABLE_FLUENT_ANIM") then
        HUD_ANIMATION.Hide(controls)
    end

    GLOBAL.ThePlayer:DoTaskInTime(0.3, function()
        CURRENT_HUD_MOD = mod_id
        refreshHUD(controls)
    end)

    if GetModConfigData("ENABLE_FLUENT_ANIM") then
        GLOBAL.ThePlayer:DoTaskInTime(0.5, function()
            HUD_ANIMATION.Show(controls)
        end)
    end
end
