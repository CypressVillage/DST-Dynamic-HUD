GLOBAL.TUNING.HIDE_A_HUD = {}
GLOBAL.TUNING.HIDE_A_HUD.KEY = 104

local function reloadAllTexture(widget)
    if widget == nil then
        return
    end
    if widget.atlas and widget.texture then
        -- local atlas = GLOBAL.resolvefilepath(widget.atlas)
        -- local texture = GLOBAL.resolvefilepath(widget.texture)
        if widget.SetTexture then
            widget:SetTexture(widget.atlas, widget.texture)
            -- widget:SetTexture(GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ATLAS), "crafting_tab.tex")
        end
    end
    
    if widget.children then
        for k, v in pairs(widget.children) do
            reloadAllTexture(v)
        end
    end
end
Assets = {
    Asset("ATLAS","../mods/workshop-2226345952/images/crafting_menu/crafting_tab.xml"),
    Asset("IMAGE","../mods/workshop-2226345952/images/crafting_menu/crafting_tab.tex")
}

local function OnKeyPressed(key)
	if key == GLOBAL.TUNING.HIDE_A_HUD.KEY and not HIDE_HUD then
		-- GLOBAL.ThePlayer.HUD:Toggle(hud)
        -- GLOBAL.ThePlayer.HUD.controls:HideCraftingAndInventory()
        -- GLOBAL.ThePlayer.HUD.controls.status:Hide()
        -- GLOBAL.ThePlayer.HUD:ShowPlayerStatusScreen(true)
        if hud then
            GLOBAL.ThePlayer.HUD.controls.clock:Hide()
            GLOBAL.ThePlayer.HUD.controls.clock:Show()
            -- for k, v in pairs(envv) do
            --     print(k, v)
            -- end
            local envv = GLOBAL.ModManager:GetMod("workshop-2250176974")
            for k, v in GLOBAL.pairs(envv.Assets) do
                for i, j in GLOBAL.pairs(v) do
                    print(k, i, j)
                end
            end
            print(envv.modname)
            -- GLOBAL.ModManager:InitializeModMain("workshop-2250176974", envv, "modmain.lua")
            -- envv.GLOBAL.ModReloadFrontEndAssets(envv.Assets, envv.modname)
            GLOBAL.ThePlayer.HUD.controls.craftingmenu.craftingmenu.frame:AddChild(GLOBAL.Image(GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ATLAS), "crafting_tab.tex"))
            GLOBAL.ThePlayer.HUD.controls.craftingmenu.craftingmenu.frame:AddChild(GLOBAL.Image("../mods/workshop-2250176974/images/crafting_menu/crafting_tab.xml", "crafting_tab.tex"))
            -- reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.craftingmenu)
        else

            GLOBAL.ThePlayer.HUD.controls.clock:Hide()
            GLOBAL.ThePlayer.HUD.controls.clock:Show()
            -- local pt = GLOBAL.ThePlayer.HUD.controls.inv:GetPosition()
            -- print(pt.x, pt.y, pt.z)
            -- GLOBAL.ThePlayer.HUD.controls.inv:MoveTo(pt, GLOBAL.Vector3(0, 16, pt.z), .25)

            -- local CONVERTION_DATA = require("../../../../workshop/content/322330/2250176974/scripts/img_override_data")
            if GLOBAL.ModManager == nil then
                print("ModManager is nil")
                -- GLOBAL.ModManager = require("modmanager")
            else
                print("ModManager is not nil")
                local envv = GLOBAL.ModManager:GetMod("workshop-2226345952")
                -- GLOBAL.ModManager:InitializeModMain("workshop-2226345952", envv, "modmain.lua")

                -- print("ModManager envv:::::::::::::")
                -- for k, v in GLOBAL.pairs(envv) do
                --     print(k, v)
                -- end
                -- print("ModManager envv.GLOBAL:::::::::::::")
                for index_, asset_ in GLOBAL.pairs(envv.Assets) do
                    if asset_.file then
                        print(index_, asset_.file)
                        asset_.file = string.gsub(asset_.file, "workshop-2250176974", "workshop-2226345952")
                        print(index_, asset_.file)
                    end
                end
                print(envv.modname)


                -- GLOBAL.setfenv(1, envv)
                -- 2250176974
                -- envv.GLOBAL.ModReloadFrontEndAssets()
                -- envv.GLOBAL.ModReloadFrontEndAssets(envv.Assets, envv.modname)
                -- reloadAllTexture(GLOBAL.ThePlayer.HUD.controls.craftingmenu)
                -- GLOBAL.ThePlayer.HUD.controls.craftingmenu.craftingmenu.frame:AddChild(GLOBAL.Image(GLOBAL.resolvefilepath(GLOBAL.CRAFTING_ATLAS), "crafting_tab.tex"))
                GLOBAL.ThePlayer.HUD.controls.craftingmenu.craftingmenu.frame:AddChild(GLOBAL.Image("../mods/workshop-2226345952/images/crafting_menu/crafting_tab.xml", "crafting_tab.tex"))
            end
        end
		hud = not hud
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


