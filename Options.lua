local _, ns = ...

-- Class list for the dropdown (English tokens → localised names)
local colorList = {
    DEATHKNIGHT = "Death Knight",
    DEMONHUNTER = "Demon Hunter",
    DRUID       = "Druid",
    EVOKER      = "Evoker",
    HUNTER      = "Hunter",
    MAGE        = "Mage",
    MONK        = "Monk",
    PALADIN     = "Paladin",
    PRIEST      = "Priest",
    ROGUE       = "Rogue",
    SHAMAN      = "Shaman",
    WARLOCK     = "Warlock",
    WARRIOR     = "Warrior"
}

-- Small helper so we never lose the reference
local function Refresh() ns.Refresh() end

local options = {
    name = "Cursor Ring",
    type = "group",
    childGroups = "tab",
    args = {
        appearance = {
            name = "Appearance",
            type = "group",
            order = 1,
            args = {
                -- 1. Hide while right-clicking
                hideOnRightClick = {
                    name = "Hide on right-click",
                    type = "toggle",
                    order = 1,
                    get = function() return CursorRingDB.hideOnRightClick end,
                    set = function(_, v)
                        CursorRingDB.hideOnRightClick = v
                        Refresh()
                    end,
                },

                -- 2. Show / Hide
                visible = {
                    name = "Show / Hide",
                    type = "toggle",
                    order = 2,
                    get = function() return CursorRingDB.visible end,
                    set = function(_, v) CursorRingDB.visible = v; Refresh() end
                },

                -- 3. Texture
                textureSelect = {
                    name = "Texture",
                    type = "select",
                    order = 3,
                    values = { Default = "Default", Thin = "Thin", Thick = "Thick", Solid = "Solid" },
                    get = function() return CursorRingDB.textureKey end,
                    set = function(_, v) CursorRingDB.textureKey = v; Refresh() end
                },

                -- 4. Ring radius
                ringRadius = {
                    name = "Ring radius",
                    type = "range",
                    order = 4,
                    min = 10, max = 100, step = 1,
                    get = function() return CursorRingDB.ringRadius end,
                    set = function(_, v) CursorRingDB.ringRadius = v; Refresh() end
                },

                -- 5. Use class color
                useClassColor = {
                    name = "Use class color",
                    type = "toggle",
                    order = 5,
                    get = function() return CursorRingDB.useClassColor end,
                    set = function(_, v)
                        CursorRingDB.useClassColor = v
                        CursorRingDB.useHighVis = false
                        if v then CursorRingDB.colorMode = "class" end
                        Refresh()
                    end
                },

                -- 6. High-vis color
                useHighVis = {
                    name = "High-visibility color",
                    type = "toggle",
                    order = 6,
                    get = function() return CursorRingDB.useHighVis end,
                    set = function(_, v)
                        CursorRingDB.useHighVis = v
                        CursorRingDB.useClassColor = false
                        if v then CursorRingDB.colorMode = "highvis" end
                        Refresh()
                    end
                },

                -- 7. Class-color preset dropdown
                classColorSelect = {
                    name = "Class color preset",
                    type = "select",
                    order = 7,
                    --  Build the list on the fly so Ace3 sees plain strings
                    values = {
                        deathknight = "Death Knight",
                        demonhunter = "Demon Hunter",
                        druid       = "Druid",
                        evoker      = "Evoker",
                        hunter      = "Hunter",
                        mage        = "Mage",
                        monk        = "Monk",
                        paladin     = "Paladin",
                        priest      = "Priest",
                        rogue       = "Rogue",
                        shaman      = "Shaman",
                        warlock     = "Warlock",
                        warrior     = "Warrior"
                    },
                    get = function()
                        return (CursorRingDB.useClassColor or CursorRingDB.useHighVis)
                               and nil
                               or CursorRingDB.colorMode
                    end,
                    set = function(_, v)
                        CursorRingDB.useClassColor = false
                        CursorRingDB.useHighVis    = false
                        CursorRingDB.colorMode     = strlower(v)
                        Refresh()
                    end,
                    disabled = function() return CursorRingDB.useClassColor or CursorRingDB.useHighVis end
                },

                -- 8. Custom color picker
                customColor = {
                    name = "Custom color",
                    type = "color",
                    hasAlpha = false,
                    order = 8,
                    get = function()
                        return CursorRingDB.customColor.r,
                               CursorRingDB.customColor.g,
                               CursorRingDB.customColor.b
                    end,
                    set = function(_, r, g, b)
                        CursorRingDB.useClassColor = false
                        CursorRingDB.useHighVis    = false
                        CursorRingDB.colorMode     = "custom"
                        CursorRingDB.customColor   = { r = r, g = g, b = b }
                        Refresh()
                    end,
                    disabled = function() return CursorRingDB.useClassColor or CursorRingDB.useHighVis end
                },

                -- 9. In-combat alpha
                inCombatAlpha = {
                    name = "In-combat alpha",
                    type = "range",
                    order = 9,
                    min = 0, max = 1, step = 0.05,
                    get = function() return CursorRingDB.inCombatAlpha end,
                    set = function(_, v) CursorRingDB.inCombatAlpha = v; Refresh() end
                },

                -- 10. Out-of-combat alpha
                outCombatAlpha = {
                    name = "Out-of-combat alpha",
                    type = "range",
                    order = 10,
                    min = 0, max = 1, step = 0.05,
                    get = function() return CursorRingDB.outCombatAlpha end,
                    set = function(_, v) CursorRingDB.outCombatAlpha = v; Refresh() end
                },

                -- 11. Reset button
                reset = {
                    name = "Reset to defaults",
                    type = "execute",
                    order = 11,
                    func = function()
                        CursorRingDB = CopyTable(ns.defaults)
                        Refresh()
                    end
                },

                -- 12. Slash help
                slashHelp = {
                    name = "Slash Commands",
                    type = "group",
                    order = 12,
                    inline = true,
                    args = {
                        text = {
                            type = "description",
                            fontSize = "medium",
                            width = "full",
                            name = [=[
|cff00ff00/cr show|r – show the ring
|cff00ff00/cr hide|r – hide the ring
|cff00ff00/cr toggle|r – toggle the ring
|cff00ff00/cr reset|r – reset to defaults

|cff00ff00/cr color <name>|r – choose color
  Valid names:
  |cffC41F3Bdeathknight|r |cffA330C9demonhunter|r |cffFF7D0Adruid|r |cff33937Fevoker|r |cffABD473hunter|r |cff69CCF0mage|r |cff00FF96monk|r |cffF58CBApaladin|r |cffFFFFFFpriest|r |cffFFF569rogue|r |cff0070DEshaman|r |cff9482C9warlock|r |cffC79C6Ewarrior|r
  Aliases:
  |cffC41F3Bred|r |cffA330C9magenta|r |cffFF7D0Aorange|r |cff33937Fdarkgreen|r |cffABD473green|r |cff00FF96lightgreen|r |cff0070DEblue|r |cff69CCF0lightblue|r |cffF58CBApink|r |cffFFFFFFwhite|r |cffFFF569yellow|r |cff9482C9purple|r |cffC79C6Etan|r
  Special: |cff888888default|r |cff00ff00highvis|r |cffffffffcustom|r

|cff00ff00/cr alpha in|out <0-1>|r – set alpha
|cff00ff00/cr texture <name>|r – Default | Thin | Thick | Solid
|cff00ff00/cr size 10-100|r – radius in pixels
|cff00ff00/cr right-click enable | disable | toggle|r – hide ring while right-clicking
]=]
                        }
                    }
                }
            }
        }
    }
}

-- Loader
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    CursorRingDB = CursorRingDB or CopyTable(ns.defaults)
    local AceConfig    = LibStub("AceConfig-3.0")
    local AceConfigDlg = LibStub("AceConfigDialog-3.0")
    AceConfig:RegisterOptionsTable("Cursor Ring", options)
    AceConfigDlg:AddToBlizOptions("Cursor Ring", "Cursor Ring")
end)