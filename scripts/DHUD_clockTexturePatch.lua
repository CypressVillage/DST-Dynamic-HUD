-- Klei 更新后，部分旧 HUD 的时钟贴图显示尺寸偏小。
-- 对未适配的 HUD 将地表时钟的 rim / hand 图片从原版 0.5 缩放设为 1。
local excludedHUDs = {
    ["origin"] = true, -- 原版
    ["workshop-2226345952"] = true, -- Nautical HUD
    ["workshop-1992293314"] = true, -- Nightmare / Shadow HUD
    ["workshop-2954087809"] = true, -- Soul Infused HUD
    ["workshop-1824509831"] = true, -- The Battle Arena / Forge HUD
    ["workshop-1583765151"] = true, -- Victorian / Gorge HUD
    ["workshop-2250176974"] = true, -- Roseate HUD
    ["workshop-3649427234"] = true, -- Minecraft HUD
}

local handExcludedHUDs = {
    ["workshop-3173870597"] = true, -- Redux HUD：只放大时钟边框
}

local function applyClockTextureScale(clock)
    if not clock then
        return
    end
    local rimScale = excludedHUDs[CURRENT_HUD_MOD] and 0.5 or 1
    local handScale = (excludedHUDs[CURRENT_HUD_MOD]
        or handExcludedHUDs[CURRENT_HUD_MOD]) and 0.5 or 1
    -- Cave clock uses animated rim and a scaled hand container; this patch only
    -- targets the two static Image widgets used by the surface clock.
    if clock._rim and clock._rim.SetTexture then
        clock._rim:SetScale(rimScale, rimScale, rimScale)
    end
    if clock._hands and clock._hands.SetTexture then
        clock._hands:SetScale(handScale, handScale, handScale)
    end
end

HUD_CLOCK_TEXTURE_PATCH = {
    Apply = applyClockTextureScale,
}

AddClassPostConstruct("widgets/uiclock", function(self)
    -- PostConstruct runs after the constructor's original 0.5 image scales.
    applyClockTextureScale(self)
end)
