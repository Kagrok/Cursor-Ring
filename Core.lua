local _, ns = ...
local UIParent, CreateFrame = UIParent, CreateFrame
local GetCursorPosition, UnitClass = GetCursorPosition, UnitClass
local CopyTable, strlower = CopyTable, strlower
local InCombatLockdown = InCombatLockdown
local C_ClassColor = C_ClassColor
local lastInCombat = nil

-- Textures
ns.textures = {
    Default = "Interface\\AddOns\\CursorRing\\media\\Default.png",
    Thin    = "Interface\\AddOns\\CursorRing\\media\\Thin.png",
    Thick   = "Interface\\AddOns\\CursorRing\\media\\Thick.png",
    Solid   = "Interface\\AddOns\\CursorRing\\media\\Solid.png"
}

-- Default config
ns.defaults = {
    ringRadius      = 28,
    textureKey      = "Default",
    inCombatAlpha   = 0.70,
    outCombatAlpha  = 0.30,
    useClassColor   = true,
    useHighVis      = false,
    colorMode       = "class",
    customColor     = { r = 1, g = 1, b = 1 },
    visible         = true,
    hideOnRightClick = True
}

-- Ring frame
local ring = CreateFrame("Frame", nil, UIParent)
ring:SetFrameStrata("TOOLTIP")
ring:SetSize(64, 64)
ring:SetPoint("CENTER", 0, 0)
ring:Hide()
local tex = ring:CreateTexture(nil, "OVERLAY")
tex:SetAllPoints()

-- Handle right-click hide/show
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if button == "RightButton" and CursorRingDB.hideOnRightClick then
        tex:Hide()
    end
end)

WorldFrame:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" and CursorRingDB.hideOnRightClick then
        tex:Show()
    end
end)

-- Alias table for slash command only
ns.colorAlias = {
    red         = "deathknight",
    magenta     = "demonhunter",
    orange      = "druid",
    darkgreen   = "evoker",
    green       = "hunter",
    lightgreen  = "monk",
    blue        = "shaman",
    lightblue   = "mage",
    pink        = "paladin",
    white       = "priest",
    yellow      = "rogue",
    purple      = "warlock",
    tan         = "warrior"
}

-- Helper: returns r,g,b
local function GetColor()
    local db = CursorRingDB
    if db.useHighVis then
        return 0, 1, 0
    end
    if db.useClassColor then
        local _, classFile = UnitClass("player")
        local color = C_ClassColor.GetClassColor(classFile)
        return color.r, color.g, color.b
    end
    if db.colorMode == "custom" then
        return db.customColor.r, db.customColor.g, db.customColor.b
    end
    local classFile = ns.colorAlias[db.colorMode] or db.colorMode
    local color = C_ClassColor.GetClassColor(strupper(classFile))
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

-- Appearance update
local function UpdateAppearance()
    local db      = CursorRingDB
    local texture = ns.textures[db.textureKey] or ns.textures.Default
    local radius  = db.ringRadius
    local alpha   = InCombatLockdown() and db.inCombatAlpha or db.outCombatAlpha
    tex:SetTexture(texture)
    tex:SetVertexColor(GetColor())
    tex:SetAlpha(alpha)
    tex:SetTexture(nil)          -- clear
    tex:SetTexture(texture)
    ring:SetSize(radius * 2, radius * 2)
end

ns.UpdateAppearance = UpdateAppearance

-- Event setup
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_DISABLED")   -- entered combat
f:RegisterEvent("PLAYER_REGEN_ENABLED")    -- left combat
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        CursorRingDB = CursorRingDB or CopyTable(ns.defaults)
        ring:SetShown(CursorRingDB.visible)
        UpdateAppearance()

        ring:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local scale = ring:GetEffectiveScale()
            ring:ClearAllPoints()
            ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

            -- only repaint when combat state flips
            local nowInCombat = InCombatLockdown()
            if nowInCombat ~= lastInCombat then
                lastInCombat = nowInCombat
                UpdateAppearance()
            end
        end)

        C_Timer.After(3, function()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r Type |cff00ff00/cr|r or open |cff00ff00Esc -> Options -> AddOns -> CursorRing|r to customize.")
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        UpdateAppearance()

    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateAppearance()
    end
end)

-- Public refresh
function ns.Refresh()
    ring:SetShown(CursorRingDB.visible)
    UpdateAppearance()
end

-- Slash command (unchanged)
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00CursorRing:|r "..msg) end
SLASH_CURSORRING1 = "/cr"
SlashCmdList["CURSORRING"] = function(msg)
    local cmd, arg1, arg2 = strsplit(" ", strlower(msg), 3)
    local db = CursorRingDB

    if cmd == "show"   then db.visible = true  ns.Refresh() Print("Ring shown")
    elseif cmd == "hide"   then db.visible = false ns.Refresh() Print("Ring hidden")
    elseif cmd == "toggle" then db.visible = not db.visible ns.Refresh() Print(db.visible and "Ring shown" or "Ring hidden")
    elseif cmd == "reset"  then CursorRingDB = CopyTable(ns.defaults); ns.Refresh() Print("Reset to defaults")

    elseif cmd == "color" and arg1 then
        arg1 = strlower(arg1)
        -- Easter egg for guild
        if arg1 == "rouge" then
            CursorRingDB.useClassColor = false
            CursorRingDB.useHighVis    = false
            CursorRingDB.colorMode     = "custom"
            CursorRingDB.customColor   = { r = 1, g = 0, b = 0 }
            ns.Refresh()
            Print("|cffFF0000It's spelled |cffffd100R-O-G-U-E|r|cffFF0000, not rouge!|r")
            return
        end
        local classFile = ns.colorAlias[arg1] or arg1
        local color = C_ClassColor.GetClassColor(strupper(classFile))
        if color or arg1 == "default" or arg1 == "highvis" then
            db.useClassColor = (arg1 == "default")
            db.useHighVis    = (arg1 == "highvis")
            if arg1 ~= "default" and arg1 ~= "highvis" then
                db.colorMode = classFile
            end
            ns.Refresh()
            Print("Color set to "..arg1)
        elseif arg1 == "custom" then
            db.useClassColor = false
            db.useHighVis    = false
            db.colorMode     = "custom"
            ns.Refresh()
            Print("Color set to custom")
        else
            Print("Unknown color: "..arg1)
        end

    elseif cmd == "alpha" and arg1 and arg2 then
        local val = tonumber(arg2)
        if not val or val < 0 or val > 1 then Print("Alpha must be 0–1") return end
        if arg1 == "in" then db.inCombatAlpha = val elseif arg1 == "out" then db.outCombatAlpha = val else Print("Usage: /cr alpha in|out 0-1") return end
        ns.Refresh()
        Print("Alpha "..arg1.." = "..val)

    elseif cmd == "texture" and arg1 then
        local key = strupper(strsub(arg1,1,1)) .. strlower(strsub(arg1,2))  -- force Title-case
        if ns.textures[key] then
            db.textureKey = key
            ns.Refresh()
            Print("Texture set to "..key)
        else
            Print("Unknown texture: "..arg1)
        end

    elseif cmd == "size" and arg1 then
        local val = tonumber(arg1)
        if not val or val < 10 or val > 100 then Print("Size must be 10-100") return end
        db.ringRadius = val ns.Refresh() Print("Size = "..val)

    elseif cmd == "right-click" or cmd == "rightclick" then
        if not arg1 or arg1 == "toggle" then
            CursorRingDB.hideOnRightClick = not CursorRingDB.hideOnRightClick
        elseif arg1 == "enable" then
            CursorRingDB.hideOnRightClick = true
        elseif arg1 == "disable" then
            CursorRingDB.hideOnRightClick = false
        else
            Print("Usage: /cr right-click enable | disable | toggle")
            return
        end
        ns.Refresh()
        Print("Hide on right-click: "..(CursorRingDB.hideOnRightClick and "|cff00ff00ON|r" or "|cffff0000OFF|r"))

    else
        Print("|cffffff00CursorRing slash commands:|r")
        Print("|cff00ff00/cr show|r |cffaaaaaa– show the ring|r")
        Print("|cff00ff00/cr hide|r |cffaaaaaa– hide the ring|r")
        Print("|cff00ff00/cr toggle|r |cffaaaaaa– toggle visibility|r")
        Print("|cff00ff00/cr reset|r |cffaaaaaa– restore defaults|r")
        Print("|cff00ff00/cr color <name> | default | highvis | <alias> |r")
        Print("  Valid names:")
        Print("  |cffC41F3Bdeathknight|r |cffA330C9demonhunter|r |cffFF7D0Adruid|r |cff33937Fevoker|r |cffABD473hunter|r |cff69CCF0mage|r |cff00FF96monk|r |cffF58CBApaladin|r |cffFFFFFFpriest|r |cffFFF569rogue|r |cff0070DEshaman|r |cff9482C9warlock|r |cffC79C6Ewarrior|r")
        Print("  Aliases:")
        Print("  |cffC41F3Bred|r |cffA330C9magenta|r |cffFF7D0Aorange|r |cff33937Fdarkgreen|r |cffABD473green|r |cff00FF96lightgreen|r |cff0070DEblue|r |cff69CCF0lightblue|r |cffF58CBApink|r |cffFFFFFFwhite|r |cffFFF569yellow|r |cff9482C9purple|r |cffC79C6Etan|r")
        Print("")
        Print("|cff00ff00/cr alpha in|out 0-0.99|r |cffaaaaaa– e.g. /cr alpha in 0.8|r")
        Print("|cff00ff00/cr texture <name>|r |cffaaaaaa– default | thin | thick | solid|r")
        Print("|cff00ff00/cr size 10-100|r |cffaaaaaa– radius in pixels|r")
        Print("|cff00ff00/cr right-click enable | disable | toggle|r – hide ring while right-clicking")
    end
end
