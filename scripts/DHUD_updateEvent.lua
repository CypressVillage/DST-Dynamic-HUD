
HUD_EVENTS_PRIORITY = {
    AREA_CHANGE = {
        ON_DEFAULT_AREA = GetModConfigData("P_ON_DEFAULT_AREA"),
        ON_BOAT = GetModConfigData("P_ON_BOAT"),
        ON_CAVE = GetModConfigData("P_ON_CAVE"),
        ON_LUNACY_AREA = GetModConfigData("P_ON_LUNACY_AREA"),
    },
    -- TIME_CHANGE = {
    --     DAY = 5,
    --     NIGHT = 4,
    --     DUSK = 3,
    -- },
    -- EVENT_NIGHTMIRE = 1,
}

EVENT_PRIORITY = {}
for event_type, _ in pairs(HUD_EVENTS_PRIORITY) do
    if type(HUD_EVENTS_PRIORITY[event_type]) == "table" then
        for sub_event_type, priority in pairs(HUD_EVENTS_PRIORITY[event_type]) do
            EVENT_PRIORITY[sub_event_type] = 0
        end
    else
        EVENT_PRIORITY[event_type] = 0
    end
end

HUD_ = {
    ON_DEFAULT_AREA = GetModConfigData("HUD_ON_DEFAULT_AREA"),
    ON_BOAT = GetModConfigData("HUD_ON_BOAT"),
    ON_CAVE = GetModConfigData("HUD_ON_CAVE"),
    ON_LUNACY_AREA = GetModConfigData("HUD_ON_LUNACY_AREA"),
}

local function OnHUDEvent()
    -- find max priority
    local event
    local max_priority = 0
    for event_type, priority in pairs(EVENT_PRIORITY) do
        if priority > max_priority then
            max_priority = priority
            event = event_type
        end
    end
    -- apply HUD based on event
    if event then
        local mod_id = HUD_[event]
        if mod_id then
            applyHUD(mod_id)
        else
            print("[HUD]: No HUD mod found for event: " .. event)
        end
    else
        print("[HUD]: No active HUD events found.")
    end
end

local function updateEventPriority(event_type, event)
    if event_type == "AREA_CHANGE" then
        for area_event, priority in pairs(HUD_EVENTS_PRIORITY.AREA_CHANGE) do
            if area_event == event then
                EVENT_PRIORITY[area_event] = priority
            else
                EVENT_PRIORITY[area_event] = 0
            end
        end
    elseif event_type == "TIME_CHANGE" then
        for time_event, priority in pairs(HUD_EVENTS_PRIORITY.TIME_CHANGE) do
            if time_event == event then
                EVENT_PRIORITY[time_event] = priority
            else
                EVENT_PRIORITY[time_event] = 0
            end
        end
    else
        EVENT_PRIORITY[event] = HUD_EVENTS_PRIORITY[event] or 0
    end
end

local function updateHUDbyEvent(event_type, event)
    updateEventPriority(event_type, event)
    OnHUDEvent()
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("got_on_platform", function()
        updateHUDbyEvent("AREA_CHANGE", "ON_BOAT")
    end)
    inst:ListenForEvent("changearea", function(inst, area)
        if area == nil then
            return
        end
        if GLOBAL.TheWorld:HasTag("cave") then
            updateHUDbyEvent("AREA_CHANGE", "ON_CAVE")
        elseif area.tags and table.contains(area.tags, "lunacyarea") then
            updateHUDbyEvent("AREA_CHANGE", "ON_LUNACY_AREA")
        else
            updateHUDbyEvent("AREA_CHANGE", "ON_DEFAULT_AREA")
        end
        -- GLOBAL.ThePlayer.components.talker:Say("[HUD]: Area changed！")
        -- print("[HUD]: Area changed to ", area.id)
        -- print("type", area.type)
        -- print("center", area.center)
        -- print("poly", area.poly)
        -- print("tags", area.tags)
        -- if area.tags then
        --     for _, t in pairs(area.tags) do
        --         print("tag", t)
        --     end
        -- end
    end)
end)