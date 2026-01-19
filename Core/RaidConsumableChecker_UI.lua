-- ============================================================================
-- RaidConsumableChecker_UI.lua
-- UI frame creation and layout management
-- ============================================================================

-- ============================================================================
-- DIMENSIONS & LAYOUT
-- ============================================================================

-- Calculate window dimensions based on current item configuration
function RaidConsumableChecker:CalculateWindowDimensions()
    local categorizedItems = self:GroupItemsByCategory()
    
    local maxItemsInCategory = 0
    for categoryId, items in pairs(categorizedItems) do
        if table.getn(items) > maxItemsInCategory then
            maxItemsInCategory = table.getn(items)
        end
    end
    
    local calculatedWidth = RCC_Constants.CONTENT_MARGIN_LEFT + 
                           RCC_Constants.CONTENT_MARGIN_RIGHT +
                           (maxItemsInCategory * (RCC_Constants.ICON_SIZE + RCC_Constants.ICON_SPACING_X)) + 
                           RCC_Constants.WINDOW_PADDING * 2
    
    if calculatedWidth < RCC_Constants.WINDOW_MIN_WIDTH then
        calculatedWidth = RCC_Constants.WINDOW_MIN_WIDTH
    end
    
    local numCategories = 0
    for _, _ in pairs(categorizedItems) do
        numCategories = numCategories + 1
    end
    
    local calculatedHeight = RCC_Constants.TITLE_HEIGHT + 40 + 
                            (numCategories * (RCC_Constants.CATEGORY_HEADER_HEIGHT + 
                                             RCC_Constants.ICON_SIZE + 30 + 
                                             RCC_Constants.CATEGORY_SPACING)) +
                            RCC_Constants.CONTENT_MARGIN_BOTTOM
    
    self.windowWidth = calculatedWidth
    self.windowHeight = calculatedHeight
end

-- Organize items into categories for display
function RaidConsumableChecker:GroupItemsByCategory()
    local categorizedItems = {}
    
    if not RaidConsumableCheckerDB.ConsumableData or not RaidConsumableCheckerDB.ConsumableData.Items then
        return categorizedItems
    end

    local items = RaidConsumableCheckerDB.ConsumableData.Items
    local itemCount = table.getn(items)
    local categories = RaidConsumableCheckerDB.ConsumableData.Categories
    
    for i = 1, itemCount do
        local itemData = items[i]
        local category = itemData.category or "other"
        
        local categoryExists = false
        for _, cat in ipairs(categories) do
            if cat.id == category then
                categoryExists = true
                break
            end
        end
        
        if not categoryExists then
            category = "other"
        end
        
        if not categorizedItems[category] then
            categorizedItems[category] = {}
        end
        
        table.insert(categorizedItems[category], itemData)
    end
    
    return categorizedItems
end

-- Retrieve category information by ID
function RaidConsumableChecker:GetCategoryInfo(categoryId)
    if not RaidConsumableCheckerDB.ConsumableData or not RaidConsumableCheckerDB.ConsumableData.Categories then
        return nil
    end

    for _, cat in ipairs(RaidConsumableCheckerDB.ConsumableData.Categories) do
        if cat.id == categoryId then
            return cat
        end
    end
    return nil
end

-- ============================================================================
-- MAIN FRAME CREATION
-- ============================================================================

-- Create the main addon window and its components
function RaidConsumableChecker:CreateMainFrame()
    local frame = CreateFrame("Frame", "RCCMainFrame", UIParent)
    frame:SetWidth(self.windowWidth or RCC_Constants.WINDOW_WIDTH)
    frame:SetHeight(self.windowHeight or RCC_Constants.WINDOW_HEIGHT)
    frame:SetPoint(
        RaidConsumableCheckerDB.position.point,
        RaidConsumableCheckerDB.position.x,
        RaidConsumableCheckerDB.position.y
    )
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    
    local bgR, bgG, bgB, bgA = self:HexToRGBA(RCC_Constants.BACKGROUND_COLOR)
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    self.titleBar = titleBar
    titleBar:SetWidth(self.windowWidth - 20 or RCC_Constants.WINDOW_WIDTH - 20)
    titleBar:SetHeight(RCC_Constants.TITLE_HEIGHT)
    titleBar:SetPoint("TOP", frame, "TOP", 0, -10)
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleBar)
    titleBg:SetTexture(RCC_Constants.TEXTURE_BORDER)
    
    local titleBgR, titleBgG, titleBgB, titleBgA = self:HexToRGBA(RCC_Constants.TITLE_BG_COLOR)
    titleBg:SetVertexColor(titleBgR, titleBgG, titleBgB, titleBgA)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetFont(RCC_Constants.FONT_TITLE, RCC_Constants.FONT_SIZE_TITLE, "OUTLINE")
    titleText:SetText(RCC_Constants.TEXT_WINDOW_TITLE)
    
    local titleTextR, titleTextG, titleTextB, titleTextA = self:HexToRGBA(RCC_Constants.TITLE_TEXT_COLOR)
    titleText:SetTextColor(titleTextR, titleTextG, titleTextB, titleTextA)
    
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        RaidConsumableChecker:SavePosition()
    end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Config button
    local configBtn = CreateFrame("Button", nil, titleBar, "UIPanelButtonTemplate")
    configBtn:SetWidth(60)
    configBtn:SetHeight(20)
    configBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
    configBtn:SetText("Config")
    configBtn:SetScript("OnClick", function()
        RaidConsumableChecker:ToggleConfig()
    end)
    
    -- Content area
    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", RCC_Constants.WINDOW_PADDING, -(RCC_Constants.TITLE_HEIGHT + 20))
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RCC_Constants.WINDOW_PADDING, RCC_Constants.WINDOW_PADDING)
    contentFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    self.mainFrame = frame
    self.contentFrame = contentFrame
    
    self:CreateConsumableFrames()
    
    frame:RegisterEvent("BAG_UPDATE")
    frame:SetScript("OnEvent", function()
        RaidConsumableChecker:OnEvent(event)
    end)
    
    frame:SetScript("OnUpdate", function()
        RaidConsumableChecker:OnUpdate(arg1)
    end)
    
    frame:SetScript("OnShow", function()
        RaidConsumableChecker:OnShow()
    end)
    frame:SetScript("OnHide", function()
        RaidConsumableChecker:OnHide()
    end)
end

-- ============================================================================
-- CONSUMABLE GRID CREATION
-- ============================================================================

-- Create all category headers and item frames dynamically
function RaidConsumableChecker:CreateConsumableFrames()
    self:ClearConsumableFrames()

    local categorizedItems = self:GroupItemsByCategory()
    local sortedCategories = {}
    local categories = RaidConsumableCheckerDB.ConsumableData.Categories
    
    for _, catInfo in ipairs(categories) do
        local items = categorizedItems[catInfo.id]
        if items and table.getn(items) > 0 then
            table.insert(sortedCategories, {id = catInfo.id, info = catInfo, items = items})
        end
    end
    
    local currentYOffset = 0
    
    for _, category in ipairs(sortedCategories) do
        currentYOffset = self:CreateCategoryHeader(category.info, currentYOffset)
        
        for i, itemData in ipairs(category.items) do
            local col = (i - 1)
            local xOffset = RCC_Constants.CONTENT_MARGIN_LEFT + (col * (RCC_Constants.ICON_SIZE + RCC_Constants.ICON_SPACING_X))
            local yOffset = currentYOffset
            
            self:CreateItemFrame(itemData, xOffset, yOffset)
        end
        
        currentYOffset = currentYOffset - (RCC_Constants.ICON_SIZE + 30 + RCC_Constants.CATEGORY_SPACING)
    end
end

-- Create a text header for a category
function RaidConsumableChecker:CreateCategoryHeader(categoryInfo, yOffset)
    local dashString = string.rep("-", categoryInfo.dashes or 0)
    local headerText = dashString .. " " .. categoryInfo.name .. " " .. dashString
    
    local header = self.contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", RCC_Constants.CONTENT_MARGIN_LEFT, yOffset)
    header:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_CATEGORY, "OUTLINE")
    header:SetText(headerText)
    
    local catR, catG, catB, catA = self:HexToRGBA(RCC_Constants.TEXT_COLOR_CATEGORY)
    header:SetTextColor(catR, catG, catB, catA)
    
    if not self.categoryHeaders then self.categoryHeaders = {} end
    table.insert(self.categoryHeaders, header)
    
    return yOffset - RCC_Constants.CATEGORY_HEADER_HEIGHT - 3
end

-- Hide and clear all current UI frames for consumables
function RaidConsumableChecker:ClearConsumableFrames()
    if self.itemFrames then
        for _, frame in ipairs(self.itemFrames) do
            frame:Hide()
        end
    end
    self.itemFrames = {}
    
    if self.categoryHeaders then
        for _, header in ipairs(self.categoryHeaders) do
            header:Hide()
        end
    end
    self.categoryHeaders = {}
end

-- Create an individual item slot UI frame
function RaidConsumableChecker:CreateItemFrame(itemData, xOffset, yOffset)
    local itemFrame = CreateFrame("Button", nil, self.contentFrame)
    itemFrame:SetWidth(RCC_Constants.ICON_SIZE)
    itemFrame:SetHeight(RCC_Constants.ICON_SIZE + 25)
    itemFrame:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", xOffset, yOffset)
    
    -- Icon background
    local iconBg = itemFrame:CreateTexture(nil, "BACKGROUND")
    iconBg:SetWidth(RCC_Constants.ICON_SIZE)
    iconBg:SetHeight(RCC_Constants.ICON_SIZE)
    iconBg:SetPoint("TOP", itemFrame, "TOP", 0, 0)
    iconBg:SetTexture(RCC_Constants.TEXTURE_BORDER)
    iconBg:SetVertexColor(0.2, 0.2, 0.2, 1)
    
    -- Icon texture
    local icon = itemFrame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(RCC_Constants.ICON_SIZE)
    icon:SetHeight(RCC_Constants.ICON_SIZE)
    icon:SetPoint("TOP", itemFrame, "TOP", 0, 0)
    
    local fullPath = self:GetFullIconPath(itemData.iconPath)
    if not icon:SetTexture(fullPath) then
        icon:SetTexture(RCC_Constants.TEXTURE_DEFAULT_ICON)
    end
    
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Icon border
    local border = itemFrame:CreateTexture(nil, "BORDER")
    border:SetWidth(RCC_Constants.ICON_SIZE + RCC_Constants.BORDER_THICKNESS * 2)
    border:SetHeight(RCC_Constants.ICON_SIZE + RCC_Constants.BORDER_THICKNESS * 2)
    border:SetPoint("CENTER", icon, "CENTER", 0, 0)
    border:SetTexture(RCC_Constants.TEXTURE_BORDER)
    
    if itemData.buffName then
        local inactiveR, inactiveG, inactiveB, inactiveA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_INACTIVE)
        border:SetVertexColor(inactiveR, inactiveG, inactiveB, inactiveA)
    else
        local noBuffR, noBuffG, noBuffB, noBuffA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_NO_BUFF)
        border:SetVertexColor(noBuffR, noBuffG, noBuffB, noBuffA)
    end
    
    -- Counter text
    local counterText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    counterText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 2)
    counterText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_COUNTER, "OUTLINE")
    
    if itemData.requiredCount and itemData.requiredCount > 0 then
        counterText:SetText("0/" .. itemData.requiredCount)
    else
        counterText:Hide()
    end

    -- Buff timer
    local buffTimeText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local timerYOffset = (itemData.requiredCount and itemData.requiredCount > 0) and 8 or 0
    buffTimeText:SetPoint("CENTER", icon, "CENTER", 0, timerYOffset)
    buffTimeText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_BUFF_TIME, "OUTLINE")
    buffTimeText:SetTextColor(1, 1, 1, 1)
    buffTimeText:SetText("")
    buffTimeText:Hide()
    
    -- Item label
    if RCC_Constants.SHOW_ITEM_NAMES then
        local nameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("TOP", icon, "BOTTOM", 0, -5)
        nameText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_ITEM_NAME, "")
        
        local displayText = itemData.displayName or itemData.itemName
        if not displayText and itemData.buffName then
            if type(itemData.buffName) == "table" then
                displayText = itemData.buffName[1]
            else
                displayText = itemData.buffName
            end
        end
        
        nameText:SetText(displayText or "")
        nameText:SetWidth(RCC_Constants.ICON_SIZE + 20)
        nameText:SetJustifyH("CENTER")
        itemFrame.nameText = nameText
    end
    
    -- Tooltip events
    itemFrame:EnableMouse(true)
    itemFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        
        local tooltipTitle = itemData.displayName or itemData.itemName
        if not tooltipTitle and itemData.buffName then
            if type(itemData.buffName) == "table" then
                tooltipTitle = itemData.buffName[1]
            else
                tooltipTitle = itemData.buffName
            end
        end
        
        if tooltipTitle then
            GameTooltip:SetText(tooltipTitle, 1, 1, 1)
        end
        
        if itemData.requiredCount and itemData.requiredCount > 0 then
            GameTooltip:AddLine("Required: " .. itemData.requiredCount, 0.8, 0.8, 0.8)
        end
        
        if itemData.buffName then
            if itemData.buffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
                local hasEnchant = RaidConsumableChecker:HasWeaponEnchant()
                if hasEnchant then
                    GameTooltip:AddLine(RCC_Constants.TEXT_TOOLTIP_WEAPON_ENCHANT, 0, 1, 0)
                else
                    GameTooltip:AddLine(RCC_Constants.TEXT_TOOLTIP_WEAPON_ENCHANT, 1, 0, 0)
                end
            else
                local hasBuff = RaidConsumableChecker:HasBuff(itemData.buffName)
                
                local buffDisplayText = "Buff: "
                if type(itemData.buffName) == "table" then
                    buffDisplayText = buffDisplayText .. table.concat(itemData.buffName, " / ")
                else
                    buffDisplayText = buffDisplayText .. itemData.buffName
                end
                
                if hasBuff then
                    GameTooltip:AddLine(buffDisplayText, 0, 1, 0)
                else
                    GameTooltip:AddLine(buffDisplayText, 1, 0, 0)
                end
            end
        end
        
        if itemData.description then
            local descR, descG, descB, descA = RaidConsumableChecker:HexToRGBA(RCC_Constants.TEXT_COLOR_DESCRIPTION)
            GameTooltip:AddLine(itemData.description, descR, descG, descB, true)
        end
        
        if itemData.buffName and itemData.itemName then
            GameTooltip:AddLine(RCC_Constants.TEXT_TOOLTIP_CLICK_TO_USE, 0.5, 0.5, 1)
        end
        
        GameTooltip:Show()
    end)
    itemFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    if itemData.buffName and itemData.itemName then
        itemFrame:RegisterForClicks("LeftButtonUp")
        itemFrame:SetScript("OnClick", function()
            RaidConsumableChecker:UseConsumable(itemData)
        end)
    end
    
    itemFrame.iconBg = iconBg
    itemFrame.icon = icon
    itemFrame.border = border
    itemFrame.counterText = counterText
    itemFrame.itemData = itemData
    itemFrame.buffTimeText = buffTimeText
    
    table.insert(self.itemFrames, itemFrame)
end