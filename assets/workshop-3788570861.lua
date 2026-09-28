local assets = {
    Asset("ANIM", "anim/3788570861/workshop-3788570861_status_meter.zip"),
    Asset("IMAGE", "../mods/workshop-3788570861/images/modicon.tex"),
    Asset("ATLAS", "../mods/workshop-3788570861/images/modicon.xml"),
    Asset("IMAGE", "../mods/workshop-3788570861/images/picnic_hud.tex"),
    Asset("ATLAS", "../mods/workshop-3788570861/images/picnic_hud.xml"),
}

for i, v in ipairs(assets) do
    table.insert(Assets, v)
end
