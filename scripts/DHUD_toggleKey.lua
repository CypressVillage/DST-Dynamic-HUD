local function OnKeyPressed(key)
    if not GetModConfigData("ENABLE_TOGGLE_KEY") then
        return
    end
    if key == 104 then
        -- 循环切换HUD
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
end

local function OnRawKey(key, down)
  	if (key and not down) then
      	OnKeyPressed(key)
  	end
end

local function ControlsPostConstruct(inst)
	inst.handler = GLOBAL.TheInput:AddKeyHandler(function(key, down) OnRawKey(key, down) end )
end
AddClassPostConstruct("widgets/controls", ControlsPostConstruct)