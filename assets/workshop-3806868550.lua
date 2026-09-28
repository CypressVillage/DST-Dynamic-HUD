local assets = {
    Asset("ANIM", "anim/3806868550/workshop-3806868550_status_meter.zip"),
    Asset("IMAGE", "../mods/workshop-3806868550/images/modicon.tex"),
    Asset("ATLAS", "../mods/workshop-3806868550/images/modicon.xml"),
    Asset("IMAGE", "../mods/workshop-3806868550/images/picnic_hud.tex"),
    Asset("ATLAS", "../mods/workshop-3806868550/images/picnic_hud.xml"),
    Asset("IMAGE", "../mods/workshop-3806868550/images/picnic_map.tex"),
    Asset("ATLAS", "../mods/workshop-3806868550/images/picnic_map.xml"),
}

for i, v in ipairs(assets) do
    table.insert(Assets, v)
end
