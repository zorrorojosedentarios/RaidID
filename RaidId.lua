-- RaidID Tracker para WotLK 3.3.5a
-- Desarrollado por Zorrorojo (hermandad Sedentarios)

RaidIDTracker = CreateFrame("Frame", "RaidIDTrackerFrame", UIParent)
RaidIDTracker:RegisterEvent("PLAYER_LOGIN")
RaidIDTracker:RegisterEvent("UPDATE_INSTANCE_INFO")
RaidIDTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
RaidIDTracker:RegisterEvent("BOSS_KILL")

local function GetClassColor(className)
    local color = RAID_CLASS_COLORS[className]
    if color then
        return string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    end
    return "ffffff"
end

local function FormatTime(seconds)
    if not seconds or seconds <= 0 then return "|cff00ff00Libre|r" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

local function CleanupExpiredIDs()
    if not RaidIDLibDB then return end
    local currentTime = time()
    for charKey, data in pairs(RaidIDLibDB) do
        if data.lockouts then
            for i = #data.lockouts, 1, -1 do
                if data.lockouts[i].expiry < currentTime then
                    table.remove(data.lockouts, i)
                end
            end
        end
    end
end

local function UpdateRaidInfo()
    if not RaidIDLibDB then RaidIDLibDB = {} end
    
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    local playerClass = select(2, UnitClass("player"))
    local charKey = playerName .. " - " .. playerRealm
    
    RaidIDLibDB[charKey] = RaidIDLibDB[charKey] or {}
    RaidIDLibDB[charKey].class = playerClass
    RaidIDLibDB[charKey].lastUpdate = time()
    RaidIDLibDB[charKey].lockouts = {}
    
    local numInstances = GetNumSavedInstances()
    for i = 1, numInstances do
        local name, id, reset, difficulty, locked, extended, instanceID, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
        
        -- Solo guardamos BANDAS activas
        if (locked or extended) and isRaid then
            local expiry = time() + reset
            
            -- Detectar Heroico vs Normal con mayor precisión
            local diffTag = "|cff00ff00[N]|r"
            local dName = (difficultyName or ""):lower()
            if dName:find("heroic") or dName:find("heroico") or difficulty == 3 or difficulty == 4 then
                diffTag = "|cffff0000[H]|r"
            end

            table.insert(RaidIDLibDB[charKey].lockouts, {
                name = name,
                id = id,
                diffTag = diffTag,
                maxPlayers = maxPlayers or (difficulty % 2 == 0 and 25 or 10),
                expiry = expiry
            })
        end
    end
    
    CleanupExpiredIDs()
    
    if RaidIDMainFrame and RaidIDMainFrame:IsShown() then
        RefreshUI()
    end
end

RaidIDTracker:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not RaidIDLibDB then RaidIDLibDB = {} end
        RequestRaidInfo() -- Forzar al juego a cargar las IDs
        UpdateRaidInfo()
    elseif event == "UPDATE_INSTANCE_INFO" or event == "BOSS_KILL" then
        UpdateRaidInfo()
    elseif event == "PLAYER_ENTERING_WORLD" then
        RequestRaidInfo()
    end
end)

-- UI Logic
local MainFrame = CreateFrame("Frame", "RaidIDMainFrame", UIParent)
MainFrame:SetSize(450, 500)
MainFrame:SetPoint("CENTER")
MainFrame:SetClampedToScreen(true)
MainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()

local HeaderTexture = MainFrame:CreateTexture(nil, "ARTWORK")
HeaderTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
HeaderTexture:SetWidth(300)
HeaderTexture:SetHeight(64)
HeaderTexture:SetPoint("TOP", 0, 12)

local Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("TOP", HeaderTexture, 0, -14)
Title:SetText("|cffffff00RaidID|r |cff00ff00Rastreador|r")

local CloseBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", -5, -5)

-- Botón de refrescar manual
local RefreshBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
RefreshBtn:SetSize(100, 22)
RefreshBtn:SetPoint("BOTTOM", 0, 15)
RefreshBtn:SetText("Actualizar")
RefreshBtn:SetScript("OnClick", function()
    RequestRaidInfo()
    UpdateRaidInfo()
    print("|cff00ff00RaidID|r: IDs actualizadas.")
end)

local ScrollFrame = CreateFrame("ScrollFrame", "RaidIDScrollFrame", MainFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 15, -45)
ScrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)

local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(380, 1)
ScrollFrame:SetScrollChild(Content)

function RefreshUI()
    local children = {Content:GetChildren()}
    for _, child in ipairs(children) do child:Hide(); child:SetParent(nil); end
    
    local yOffset = -5
    local currentTime = time()
    local myKey = UnitName("player") .. " - " .. GetRealmName()
    
    local keys = {}
    if RaidIDLibDB then
        for k in pairs(RaidIDLibDB) do table.insert(keys, k) end
        -- Ordenar: Yo siempre primero, luego alfabético
        table.sort(keys, function(a, b) 
            if a == myKey then return true end
            if b == myKey then return false end
            return a < b 
        end)
    end
    
    for _, charKey in ipairs(keys) do
        local data = RaidIDLibDB[charKey]
        if data then
            local classColor = GetClassColor(data.class or "PLAYER")
            
            local Row = CreateFrame("Frame", nil, Content)
            Row:SetPoint("TOPLEFT", 0, yOffset)
            Row:SetPoint("RIGHT", 0, 0)
            Row:SetHeight(20)
            
            local bg = Row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.2, 0.2, 0.2, 0.3)
            
            local CharHeader = Row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            CharHeader:SetPoint("LEFT", 5, 0)
            CharHeader:SetText(string.format("|cff%s%s|r", classColor, charKey))
            
            yOffset = yOffset - 22
            
            local hasLockouts = false
            if data.lockouts and #data.lockouts > 0 then
                table.sort(data.lockouts, function(a, b) return (a.name or "") < (b.name or "") end)
                for _, lockout in ipairs(data.lockouts) do
                    local timeLeft = (lockout.expiry or 0) - currentTime
                    if timeLeft > 0 then
                        hasLockouts = true
                        local LockoutRow = CreateFrame("Frame", nil, Content)
                        LockoutRow:SetPoint("TOPLEFT", 0, yOffset)
                        LockoutRow:SetPoint("RIGHT", 0, 0)
                        LockoutRow:SetHeight(16)
                        
                        local LockoutText = LockoutRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        LockoutText:SetPoint("LEFT", 25, 0)
                        local tag = lockout.diffTag or "|cff00ff00[N]|r"
                        LockoutText:SetText(string.format("%s (%s) %s |cff00ffffID: %s|r", lockout.name or "???", lockout.maxPlayers or "?", tag, tostring(lockout.id or "---")))
                        
                        local TimeText = LockoutRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        TimeText:SetPoint("RIGHT", -5, 0)
                        TimeText:SetText(string.format("|cffff6600%s|r", FormatTime(timeLeft)))
                        
                        yOffset = yOffset - 18
                    end
                end
            end
            
            if not hasLockouts then
                local NoLockoutRow = CreateFrame("Frame", nil, Content)
                NoLockoutRow:SetPoint("TOPLEFT", 0, yOffset)
                NoLockoutRow:SetPoint("RIGHT", 0, 0)
                NoLockoutRow:SetHeight(16)
                local NoLockoutText = NoLockoutRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                NoLockoutText:SetPoint("LEFT", 25, 0)
                NoLockoutText:SetText("|cff888888- Sin IDs (Libre) -|r")
                yOffset = yOffset - 18
            end
            yOffset = yOffset - 12
        end
    end
    Content:SetHeight(math.abs(yOffset) + 20)
end

MainFrame:SetScript("OnShow", function()
    RequestRaidInfo()
    UpdateRaidInfo()
    RefreshUI()
end)

SLASH_RAIDID1 = "/raidid"
SlashCmdList["RAIDID"] = function(msg)
    local command = msg:lower()
    if command == "reset" then
        RaidIDLibDB = {}
        print("|cff00ff00RaidID|r: Todos los datos reiniciados.")
        UpdateRaidInfo()
        RefreshUI()
    elseif command == "ver" then
        local version = GetAddOnMetadata("RaidId", "Version") or "1.0"
        print("|cff00ff00RaidID|r Tracker - Versión: |cffffff00" .. version .. "|r")
    else
        if MainFrame:IsShown() then MainFrame:Hide() else MainFrame:Show() end
    end
end

SLASH_RAIDIDVER1 = "/ver"
SlashCmdList["RAIDIDVER"] = function()
    local version = GetAddOnMetadata("RaidId", "Version") or "1.0"
    print("|cff00ff00RaidID|r Tracker - Versión: |cffffff00" .. version .. "|r")
end

-- Minimap Button
local minimapBtn = CreateFrame("Button", "RaidIDMinimapButton", Minimap)
minimapBtn:SetSize(32, 32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Addons\\RaidId\\raidid.tga")
icon:SetSize(21, 21)
icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)

local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)

minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if RaidIDMainFrame:IsShown() then RaidIDMainFrame:Hide() else RaidIDMainFrame:Show() end
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("RaidID Tracker")
    GameTooltip:AddLine("Click Izquierdo para abrir/cerrar", 1, 1, 1)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

minimapBtn:SetPoint("CENTER", Minimap, "CENTER", -78, -38)

