name = "[DST] Dynamic HUD"
author = "三九四九冰上走"
version = "0.1.3"
description = [[
本模组允许你根据当前环境动态切换不同的HUD。

注意事项：
- 必须同时启用对应的HUD模组，切换HUD功能才会生效

HUD兼容列表：
- Celestial HUD [Fixed]（workshop-3285344272）
- Merrymaker HUD（workshop-3381333362）
- Nautical HUD（workshop-2226345952）
- Nightmare HUD（workshop-1992293314）
- Redux HUD（workshop-3173870597）
- Roseate HUD（workshop-2250176974）
- Soul Infused HUD（workshop-2954087809）
- The Battle Arena HUD（workshop-1824509831）
- Victorian HUD（workshop-1583765151）

]]

forumthread = ""

api_version = 10
priority = 100

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "HUD" }

local emptyline = {name = "Title", label = "", options = {{description = "", data = ""}}, default = ""}
local function title(text)
    return {name = "Title", label = text, options = {{description = "", data = ""}}, default = ""}
end
local priority_table = {
    {description = "0（不启用）", data = 0},
    {description = "1", data = 1},
    {description = "2", data = 2},
    {description = "3", data = 3},
    {description = "4", data = 4},
    {description = "5", data = 5},
    {description = "6", data = 6},
    {description = "7", data = 7},
    {description = "8", data = 8},
    {description = "9", data = 9},
}
local hud_table = {
    {description = "Celestial HUD", data = "workshop-3285344272"},
    {description = "Merrymaker HUD", data = "workshop-3381333362"},
    {description = "Nautical HUD", data = "workshop-2226345952"},
    {description = "Nightmare HUD", data = "workshop-1992293314"},
    {description = "Redux HUD", data = "workshop-3173870597"},
    {description = "Roseate HUD", data = "workshop-2250176974"},
    {description = "Soul Infused HUD", data = "workshop-2954087809"},
    {description = "The Battle Arena HUD", data = "workshop-1824509831"},
    {description = "Victorian HUD", data = "workshop-1583765151"},
}
local keyboard = { -- from STRINGS.UI.CONTROLSSCREEN.INPUTS[1] of strings.lua, need to match constants.lua too.
  { 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'Print', 'ScrolLock', 'Pause' },
  { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' },
  { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M' },
  { 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' },
  { 'Escape', 'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LSuper', 'LAlt' },
  { 'Space', 'RAlt', 'RSuper', 'RCtrl', 'RShift', 'Enter', 'Backspace' },
  { 'BackQuote', 'Minus', 'Equals', 'LeftBracket', 'RightBracket' },
  { 'Backslash', 'Semicolon', 'Quote', 'Period', 'Slash' }, -- punctuation
  { 'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown' }, -- navigation
}
local numpad = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Period', 'Divide', 'Multiply', 'Minus', 'Plus' }
local key_disabled = { description = 'Disabled', data = 'KEY_DISABLED' }
keys = { key_disabled }
for i = 1, #keyboard do
  for j = 1, #keyboard[i] do
    local key = keyboard[i][j]
    keys[#keys + 1] = { description = key, data = 'KEY_' .. key:upper() }
  end
  keys[#keys + 1] = key_disabled
end
for i = 1, #numpad do
  local key = numpad[i]
  keys[#keys + 1] = { description = 'Numpad ' .. key, data = 'KEY_KP_' .. key:upper() }
end

configuration_options = {
    title("【功能设置】"),
    {
        name = "ENABLE_FLUENT_ANIM",
        label = "HUD切换时过渡动画",
        hover = "启用后，HUD切换时会有过渡动画",
        options = {
            {description = "启用", data = true},
            {description = "禁用", data = false},
        },
        default = true,
    },
    {
        name = "KEY_BIND",
        label = "HUD切换热键",
        hover = "设置HUD切换的热键",
        options = keys,
        default = "H", -- Default to H
    },
    emptyline,
    title("【HUD偏好设置】"),
    title("不同地形HUD"),
    {
        name = "HUD_ON_DEFAULT_AREA",
        label = "默认",
        hover = "角色进入默认区域时使用的HUD",
        options = hud_table,
        default = "workshop-2250176974", -- Roseate HUD
    },
    {
        name = "HUD_ON_BOAT",
        label = "船上",
        hover = "角色进入船上区域时使用的HUD",
        options = hud_table,
        default = "workshop-2226345952", -- Nautical HUD
    },
    {
        name = "HUD_ON_CAVE",
        label = "洞穴",
        hover = "角色进入洞穴区域时使用的HUD",
        options = hud_table,
        default = "workshop-1583765151", -- Victorian HUD
    },
    {
        name = "HUD_ON_LUNACY_AREA",
        label = "启蒙区域",
        hover = "角色进入启蒙区域时使用的HUD",
        options = hud_table,
        default = "workshop-3285344272", -- Celestial HUD
    },
    emptyline,
    title("【HUD优先级设置】"),
    title("不同地形优先级"),
    {
        name = "P_ON_DEFAULT_AREA",
        label = "默认区域",
        hover = "角色进入默认区域的优先级",
        options = priority_table,
        default = 1,
    },
    {
        name = "P_ON_BOAT",
        label = "船上",
        hover = "角色进入船上区域的优先级",
        options = priority_table,
        default = 6,
    },
    {
        name = "P_ON_CAVE",
        label = "洞穴",
        hover = "角色进入洞穴区域的优先级",
        options = priority_table,
        default = 6,
    },
    {
        name = "P_ON_LUNACY_AREA",
        label = "启蒙区域",
        hover = "角色进入启蒙区域的优先级",
        options = priority_table,
        default = 6,
    }
    -- emptyline,
    -- title("特定时间优先级"),
    -- {
    --     name = "P_DAY",
    --     label = "白天",
    --     hover = "白天的优先级",
    --     options = priority_table,
    --     default = 5,
    -- },
    -- {
    --     name = "P_NIGHT",
    --     label = "夜晚",
    --     hover = "夜晚的优先级",
    --     options = priority_table,
    --     default = 4,
    -- },
    -- {
    --     name = "P_DUSK",
    --     label = "黄昏",
    --     hover = "黄昏的优先级",
    --     options = priority_table,
    --     default = 3,
    -- },
    -- {
    --     name = "P_DAWN",
    --     label = "黎明",
    --     hover = "黎明的优先级",
    --     options = priority_table,
    --     default = 2,
    -- },
}