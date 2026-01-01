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
-- HELPER: Convert hex color to RGBA
-- ============================================================================
function RaidConsumableChecker:HexToRGBA(hex)
    if not hex or type(hex) ~= "string" or string.len(hex) ~= 8 then
        -- Return white with full opacity as fallback
        return 1, 1, 1, 1
    end
    
    local r = tonumber(string.sub(hex, 1, 2), 16) / 255
    local g = tonumber(string.sub(hex, 3, 4), 16) / 255
    local b = tonumber(string.sub(hex, 5, 6), 16) / 255
    local a = tonumber(string.sub(hex, 7, 8), 16) / 255
    return r, g, b, a
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function RaidConsumableChecker:Initialize()
    -- Initialize saved variables
    if not RaidConsumableCheckerDB then
        RaidConsumableCheckerDB = {
            position = RCC_Constants.DEFAULT_POSITION
        }
    end
    
    -- Calculate window dimensions based on categories
    self:CalculateWindowDimensions()
    
    -- Create main frame
    self:CreateMainFrame()
    
    -- Hide frame initially
    self.mainFrame:Hide()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Print loaded message
    local addonNameColor = "|c" .. RCC_Constants.TEXT_COLOR_ADDON_NAME
    local goldColor = "|c" .. RCC_Constants.TEXT_COLOR_GOLD
    local whiteColor = "|cffffffff"
    
    local message = addonNameColor .. "Raid Consumable Checker" .. whiteColor .. ": " ..
                   goldColor .. "v" .. RCC_Constants.ADDON_VERSION .. whiteColor ..
                   " loaded. Type " .. goldColor .. RCC_Constants.SLASH_COMMANDS.PRIMARY .. whiteColor ..
                   " or " .. goldColor .. RCC_Constants.SLASH_COMMANDS.SECONDARY .. whiteColor .. " to open."
    
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================
function RaidConsumableChecker:OnEvent(event)
    if event == "BAG_UPDATE" then
        if self.mainFrame:IsVisible() then
            self:UpdateConsumables()
        end
    end
end

function RaidConsumableChecker:OnUpdate(elapsed)
    if not self.mainFrame:IsVisible() then
        return
    end
    
    -- Buff scan timer
    self.buffScanTimer = self.buffScanTimer + elapsed
    if self.buffScanTimer >= RCC_Constants.BUFF_SCAN_INTERVAL then
        self.buffScanTimer = 0
        self:UpdateBuffs()
    end
    
    -- Pending buff update after using consumable
    if self.pendingBuffUpdate then
        self.buffUpdateTimer = self.buffUpdateTimer + elapsed
        if self.buffUpdateTimer >= RCC_Constants.BUFF_UPDATE_DELAY_AFTER_USE then
            self.pendingBuffUpdate = false
            self.buffUpdateTimer = 0
            self:UpdateBuffs()
        end
    end
end

function RaidConsumableChecker:OnShow()
    -- Initial update when window opens
    self:UpdateConsumables()
    self:UpdateBuffs()
    self.buffScanTimer = 0
end

function RaidConsumableChecker:OnHide()
    -- Reset timers when window closes
    self.buffScanTimer = 0
    self.pendingBuffUpdate = false
    self.buffUpdateTimer = 0
end

-- ============================================================================
-- TOGGLE WINDOW
-- ============================================================================
function RaidConsumableChecker:ToggleWindow()
    if self.mainFrame:IsVisible() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
    end
end

-- ============================================================================
-- SAVE WINDOW POSITION
-- ============================================================================
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
function RaidConsumableChecker:RegisterSlashCommands()
    SLASH_RAIDCONSUMABLECHECKER1 = RCC_Constants.SLASH_COMMANDS.PRIMARY
    SLASH_RAIDCONSUMABLECHECKER2 = RCC_Constants.SLASH_COMMANDS.SECONDARY
    SLASH_RAIDCONSUMABLECHECKER3 = RCC_Constants.SLASH_COMMANDS.TERTIARY
    
    SlashCmdList["RAIDCONSUMABLECHECKER"] = function(msg)
        RaidConsumableChecker:ToggleWindow()
    end
end

-- ============================================================================
-- ADDON LOADED EVENT
-- ============================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == RCC_Constants.ADDON_NAME then
        RaidConsumableChecker:Initialize()
    end
end)