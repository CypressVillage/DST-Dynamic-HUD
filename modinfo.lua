name = "[DST] Dynamic HUD"
author = "CypressVillage"
version = "0.1.0"
description = "A mod that allows you to toggle different HUD by area, season, time or special events.\n\n"

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
    {description = "Merrymaker HUD", data = "workshop-3381333362"},
    {description = "Nautical HUD", data = "workshop-2226345952"},
    {description = "Nightmare HUD", data = "workshop-1992293314"},
    {description = "Redux HUD", data = "workshop-3173870597"},
    {description = "Roseate HUD", data = "workshop-2250176974"},
    {description = "Soul Infused HUD", data = "workshop-2954087809"},
    {description = "The Battle Arena HUD", data = "workshop-1824509831"},
    {description = "Victorian HUD", data = "workshop-1583765151"},
}

configuration_options = {
    title("【HUD偏好设置】"),
    title("不同地形HUD设置"),
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
    -- {
    --     name = "HUD_ON_CAVE",
    --     label = "洞穴HUD",
    --     hover = "角色进入洞穴区域时使用的HUD",
    --     options = hud_table,
    --     default = "workshop-1583765151", -- Victorian HUD
    -- },
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
    -- {
    --     name = "P_ON_CAVE",
    --     label = "洞穴",
    --     hover = "角色进入洞穴区域的优先级",
    --     options = priority_table,
    --     default = 0,
    -- },
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