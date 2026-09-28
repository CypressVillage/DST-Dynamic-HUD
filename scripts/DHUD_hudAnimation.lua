-- HUD 控件的位置与主题切换时的移出 / 移回动画。
local HUDAnimation = {}

local animatedRoots = {
    { name = "topright_root", x = 300, y = 0 },
    { name = "containerroot_side", x = 300, y = 0 },
    { name = "bottomright_root", x = 300, y = 0 },
    { name = "bottom_root", x = 0, y = -200 },
    { name = "left_root", x = -800, y = 0 },
}

local originalPositions

function HUDAnimation.StorePositions(controls)
    if originalPositions then
        return
    end

    originalPositions = {}
    for _, root in ipairs(animatedRoots) do
        originalPositions[root.name] = controls[root.name]:GetPosition()
    end
end

function HUDAnimation.Hide(controls)
    for _, root in ipairs(animatedRoots) do
        local position = originalPositions[root.name]
        controls[root.name]:MoveTo(position,
            GLOBAL.Vector3(root.x, root.y, position.z), 0.3)
    end
end

function HUDAnimation.Show(controls)
    for _, root in ipairs(animatedRoots) do
        local widget = controls[root.name]
        widget:MoveTo(widget:GetPosition(), originalPositions[root.name], 0.5)
    end
end

HUD_ANIMATION = HUDAnimation
