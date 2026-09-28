-- Klei 更新后，部分旧 HUD 的时钟贴图显示尺寸偏小。
-- 仅对确认未适配新版时钟贴图尺寸的 HUD 放大，其他主题（含原版、奶茶猫）不动。
local needsClockFix = {
    ["workshop-3456159081"] = true, -- Archive HUD
    ["workshop-3381333362"] = true, -- Merrymaker HUD
    ["workshop-3548608555"] = true, -- Mystery HUD
    ["workshop-3173870597"] = true, -- Redux HUD
    ["workshop-2571443104"] = true, -- Celestial HUD
    ["workshop-2284894693"] = true, -- Pig Ruins HUD
    ["workshop-2329943377"] = true, -- The Lunar HUD
}

local function applyClockTextureScale(clock)
    if not clock then
        return
    end
    local rimScale = needsClockFix[CURRENT_HUD_MOD] and 1 or 0.5
    local handScale = (needsClockFix[CURRENT_HUD_MOD]
        and CURRENT_HUD_MOD ~= "workshop-3173870597") and 1 or 0.5
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
