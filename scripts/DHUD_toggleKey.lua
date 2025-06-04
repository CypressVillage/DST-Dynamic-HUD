local function OnKeyPressed()
    if GLOBAL.ThePlayer == nil or not GLOBAL.ThePlayer.HUD then
        return
    end
    local current_index = 1
    for i, mod_id in ipairs(ENABLED_HUD_MODS) do
        if mod_id == CURRENT_HUD_MOD then
            current_index = i
            break
        end
    end
    current_index = current_index % #ENABLED_HUD_MODS + 1
    applyHUD(ENABLED_HUD_MODS[current_index])
end

local handler = nil -- 按键事件处理器

function KeyBind(_, key)
  if handler then handler:Remove() end -- 禁用旧绑定
  handler = key and GLOBAL.TheInput:AddKeyDownHandler(key, OnKeyPressed) or nil -- 新建绑定或无绑定
end