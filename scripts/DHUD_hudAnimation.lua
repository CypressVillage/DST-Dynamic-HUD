-- HUD 控件的位置与主题切换时的移出 / 移回动画。
local HUDAnimation = {}

local animatedRoots = {
    { name = "topright_root", x = 300, y = 0 },
    { name = "containerroot_side", x = 300, y = 0 },
    { name = "bottomright_root", x = 300, y = 0 },
    { name = "bottom_root", x = 0, y = -200 },
    { name = "left_root", x = -800, y = 0 },
}

function HUDAnimation.StorePositions(controls)
    local originalPositions = {}
    for _, root in ipairs(animatedRoots) do
        local widget = controls[root.name]
        if widget then
            originalPositions[root.name] = widget:GetPosition()
        end
    end
    controls._dhud_original_positions = originalPositions
end

local function moveRoots(controls, hiding, onComplete)
    local positions = controls._dhud_original_positions
    local moves = {}
    for _, root in ipairs(animatedRoots) do
        local widget = controls[root.name]
        local position = positions and positions[root.name]
        if widget and position then
            moves[#moves + 1] = {
                widget = widget,
                target = hiding and GLOBAL.Vector3(
                    position.x + root.x, position.y + root.y, position.z) or position,
            }
        end
    end

    local remaining = #moves
    if remaining == 0 then
        onComplete()
        return
    end
    for _, move in ipairs(moves) do
        local widget = move.widget
        widget:CancelMoveTo()
        widget:MoveTo(widget:GetPosition(), move.target, hiding and 0.3 or 0.5, function()
            remaining = remaining - 1
            if remaining == 0 then
                onComplete()
            end
        end)
    end
end

function HUDAnimation.Hide(controls, onComplete)
    moveRoots(controls, true, onComplete)
end

function HUDAnimation.Show(controls, onComplete)
    moveRoots(controls, false, onComplete)
end

HUD_ANIMATION = HUDAnimation
