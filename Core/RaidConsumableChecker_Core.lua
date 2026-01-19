-- ============================================================================
-- RaidConsumableChecker_Core.lua
-- Core addon logic: initialization, events, and main control
-- ============================================================================

RaidConsumableChecker = {}
RaidConsumableChecker.itemFrames = {}
RaidConsumableChecker.buffScanTimer = 0
RaidConsumableChecker.pendingBuffUpdate = false
RaidConsumableChecker.buffUpdateTimer = 0

-- ============================================================================
-- HELPERS
-- ============================================================================

-- Convert hex color to RGBA
function RaidConsumableChecker:HexToRGBA(hex)
    if not hex or type(hex) ~= "string" or string.len(hex) ~= 8 then
        return 1, 1, 1, 1
    end
    
    local a = tonumber(string.sub(hex, 1, 2), 16) / 255
    local r = tonumber(string.sub(hex, 3, 4), 16) / 255
    local g = tonumber(string.sub(hex, 5, 6), 16) / 255
    local b = tonumber(string.sub(hex, 7, 8), 16) / 255
    return r, g, b, a
end

-- Print to chat with [RCC] prefix and type-based coloring
function RaidConsumableChecker:Print(msg, msgType)
    local prefix = "|c" .. RCC_Constants.TEXT_COLOR_ADDON_NAME .. "[RCC]|r "
    local color = RCC_Constants.TEXT_COLOR_NORMAL
    
    if msgType == "success" then
        color = RCC_Constants.TEXT_COLOR_SUFFICIENT
    elseif msgType == "warning" then
        color = RCC_Constants.TEXT_COLOR_GOLD
    elseif msgType == "error" then
        color = RCC_Constants.TEXT_COLOR_INSUFFICIENT
    end
    
    local highlightColor = RCC_Constants.TEXT_COLOR_HIGHLIGHT
    local coloredMsg = string.gsub(msg, "'(.-)'", "'|c" .. highlightColor .. "%1|r|c" .. color .. "'")
    
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. "|c" .. color .. coloredMsg .. "|r")
end

-- Get full path for icon
function RaidConsumableChecker:GetFullIconPath(iconPath)
    if not iconPath or iconPath == "" then
        return RCC_Constants.TEXTURE_DEFAULT_ICON
    end
    
    local lowPath = string.lower(iconPath)
    if string.find(lowPath, "interface\\") or string.find(lowPath, "interface/") then
        return iconPath
    end
    
    return RCC_Constants.TEXTURE_ICON_BASE_PATH .. iconPath
end

-- Normalize icon path/name to pattern: UPPER_Title_Title
function RaidConsumableChecker:NormalizeIconPath(path)
    if not path or path == "" then return "" end
    
    path = string.gsub(path, "%s+", "")
    
    local result = ""
    local partIndex = 1
    
    for part in string.gfind(path, "([^%_]+)") do
        if partIndex == 1 then
            result = string.upper(part)
        else
            local first = string.sub(part, 1, 1)
            local rest = string.sub(part, 2)
            result = result .. "_" .. string.upper(first) .. string.lower(rest)
        end
        partIndex = partIndex + 1
    end
    
    return result
end

-- Deep Copy a table
function RaidConsumableChecker:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize addon settings and data migration
function RaidConsumableChecker:Initialize()
    if not RaidConsumableCheckerDB then
        RaidConsumableCheckerDB = {}
    end
    if not RaidConsumableCheckerDB.position then
        RaidConsumableCheckerDB.position = self:DeepCopy(RCC_Constants.DEFAULT_POSITION)
    end

    local initMsg = nil
    -- DATA MIGRATION / INITIALIZATION
    if not RaidConsumableCheckerDB.ConsumableData then
        local prefix = "|c" .. RCC_Constants.TEXT_COLOR_ADDON_NAME .. "Raid Consumable Checker|r: "
        local color = "|c" .. RCC_Constants.TEXT_COLOR_SUFFICIENT
        
        -- Scenario A: User has an old RaidConsumableChecker_Data.lua (Legacy Migration)
        if RCC_ConsumableData and (RCC_ConsumableData.Items or RCC_ConsumableData.Categories) then
            RaidConsumableCheckerDB.ConsumableData = {
                Items = self:DeepCopy(RCC_ConsumableData.Items or {}),
                Categories = self:DeepCopy(RCC_ConsumableData.Categories or {})
            }
            initMsg = prefix .. color .. "Data migrated from legacy configuration file.|r"
        -- Scenario B: Fresh install or no legacy data found (Seed from Constants)
        else
            RaidConsumableCheckerDB.ConsumableData = {
                Items = self:DeepCopy(RCC_Constants.DEFAULT_ITEMS or {}),
                Categories = self:DeepCopy(RCC_Constants.DEFAULT_CATEGORIES)
            }
            initMsg = prefix .. color .. "Initialized with default 2.0.0 settings.|r"
        end
    end
    
    self:RegisterSlashCommands()

    if RaidConsumableCheckerDB.ConsumableData then
        local data = RaidConsumableCheckerDB.ConsumableData
        
        -- 1. Data Integrity: Ensure all items have a category & normalize icon paths
        local needsOtherCategory = false
        if data.Items then
            for _, item in ipairs(data.Items) do
                if item.iconPath then
                    local lowerPath = string.lower(item.iconPath)
                    if string.sub(lowerPath, 1, 16) == "interface\\icons\\" then
                        item.iconPath = string.sub(item.iconPath, 17)
                    elseif string.sub(lowerPath, 1, 16) == "interface/icons/" then
                        item.iconPath = string.sub(item.iconPath, 17)
                    end
                    item.iconPath = self:NormalizeIconPath(item.iconPath)
                end

                if not item.category or item.category == "" then
                    item.category = "other"
                    needsOtherCategory = true
                end
            end
        end

        -- 2. Ensure "other" category exists if it's being used
        if needsOtherCategory and data.Categories then
            local otherExists = false
            for _, cat in ipairs(data.Categories) do
                if cat.id == "other" then otherExists = true break end
            end
            
            if not otherExists then
                table.insert(data.Categories, {
                    id = "other", 
                    name = "Other",
                    dashes = 20
                })
            end
        end

        -- 3. Transition from 'order' field to table position
        if data.Categories and table.getn(data.Categories) > 0 then
            local hasOrder = false
            for _, cat in ipairs(data.Categories) do
                if cat.order then hasOrder = true break end
            end
            if hasOrder then
                table.sort(data.Categories, function(a, b)
                    local orderA = tonumber(a.order) or 99
                    local orderB = tonumber(b.order) or 99
                    return orderA < orderB
                end)
                for _, cat in ipairs(data.Categories) do cat.order = nil end
            end
        end

        -- 4. Set entryType for existing items (Migration)
        if data.Items then
            for _, item in ipairs(data.Items) do
                if not item.entryType then
                    local hasName = (item.itemName and item.itemName ~= "")
                    local hasReq = (item.requiredCount and tonumber(item.requiredCount) > 0)
                    local hasBuffs = false
                    if type(item.buffName) == "table" then
                        hasBuffs = (table.getn(item.buffName) > 0)
                    else
                        hasBuffs = (item.buffName and item.buffName ~= "")
                    end
                    
                    if not hasName and not hasReq and hasBuffs then
                        item.entryType = "buff"
                    else
                        item.entryType = "consumable"
                    end
                end
            end
        end
    end
    
    self:CalculateWindowDimensions()
    self:CreateMainFrame()
    self.mainFrame:Hide()
    
    -- Loaded message
    local addonNameColor = "|c" .. RCC_Constants.TEXT_COLOR_ADDON_NAME
    local goldColor = "|c" .. RCC_Constants.TEXT_COLOR_GOLD
    local whiteColor = "|cffffffff"
    
    local message = addonNameColor .. "Raid Consumable Checker" .. whiteColor .. ": " ..
                   goldColor .. "v" .. RCC_Constants.ADDON_VERSION .. whiteColor ..
                   " loaded. Type " .. goldColor .. RCC_Constants.SLASH_COMMANDS.PRIMARY .. whiteColor ..
                   " or " .. goldColor .. RCC_Constants.SLASH_COMMANDS.SECONDARY .. whiteColor .. " to open."
    
    DEFAULT_CHAT_FRAME:AddMessage(message)
    
    if initMsg then
        DEFAULT_CHAT_FRAME:AddMessage(initMsg)
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Main event dispatcher
function RaidConsumableChecker:OnEvent(event)
    if event == "BAG_UPDATE" then
        if self.mainFrame:IsVisible() then
            self:UpdateConsumables()
        end
    end
end

-- Per-frame update logic for timers
function RaidConsumableChecker:OnUpdate(elapsed)
    if not self.mainFrame:IsVisible() then
        return
    end
    
    self.buffScanTimer = self.buffScanTimer + elapsed
    if self.buffScanTimer >= RCC_Constants.BUFF_SCAN_INTERVAL then
        self.buffScanTimer = 0
        self:UpdateBuffs()
    end
    
    if self.pendingBuffUpdate then
        self.buffUpdateTimer = self.buffUpdateTimer + elapsed
        if self.buffUpdateTimer >= RCC_Constants.BUFF_UPDATE_DELAY_AFTER_USE then
            self.pendingBuffUpdate = false
            self.buffUpdateTimer = 0
            self:UpdateBuffs()
        end
    end
end

-- Frame show handler
function RaidConsumableChecker:OnShow()
    self:UpdateConsumables()
    self:UpdateBuffs()
    self.buffScanTimer = 0
end

-- Frame hide handler
function RaidConsumableChecker:OnHide()
    self.buffScanTimer = 0
    self.pendingBuffUpdate = false
    self.buffUpdateTimer = 0
    
    if self.configFrame and self.configFrame:IsVisible() then
        self.configFrame:Hide()
    end
end

-- ============================================================================
-- WINDOW CONTROL
-- ============================================================================

-- Toggle the visibility of the main addon window
function RaidConsumableChecker:ToggleWindow()
    if self.mainFrame:IsVisible() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
    end
end

-- Save current main window position to database
function RaidConsumableChecker:SavePosition()
    local point, _, relativePoint, x, y = self.mainFrame:GetPoint()
    RaidConsumableCheckerDB.position = {
        point = point,
        x = x,
        y = y
    }
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

-- Register chat slash commands
function RaidConsumableChecker:RegisterSlashCommands()
    SLASH_RAIDCONSUMABLECHECKER1 = RCC_Constants.SLASH_COMMANDS.PRIMARY
    SLASH_RAIDCONSUMABLECHECKER2 = RCC_Constants.SLASH_COMMANDS.SECONDARY
    SLASH_RAIDCONSUMABLECHECKER3 = RCC_Constants.SLASH_COMMANDS.TERTIARY
    
    SlashCmdList["RAIDCONSUMABLECHECKER"] = function(msg)
        RaidConsumableChecker:ToggleWindow()
    end
end

-- ============================================================================
-- BOOTSTRAP
-- ============================================================================

-- Initialize addon on load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == RCC_Constants.ADDON_NAME then
        RaidConsumableChecker:Initialize()
    end
end)