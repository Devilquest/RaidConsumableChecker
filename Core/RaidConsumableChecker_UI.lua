-- ============================================================================
-- RaidConsumableChecker_UI.lua
-- UI frame creation and layout management
-- ============================================================================

-- ============================================================================
-- CALCULATE WINDOW DIMENSIONS
-- ============================================================================
function RaidConsumableChecker:CalculateWindowDimensions()
    -- Group items by category
    local categorizedItems = self:GroupItemsByCategory()
    
    -- Find max items in any category
    local maxItemsInCategory = 0
    for categoryId, items in pairs(categorizedItems) do
        if table.getn(items) > maxItemsInCategory then
            maxItemsInCategory = table.getn(items)
        end
    end
    
    -- Calculate width based on max items
    local calculatedWidth = RCC_Constants.CONTENT_MARGIN_LEFT + 
                           RCC_Constants.CONTENT_MARGIN_RIGHT +
                           (maxItemsInCategory * (RCC_Constants.ICON_SIZE + RCC_Constants.ICON_SPACING_X)) + 
                           RCC_Constants.WINDOW_PADDING * 2
    
    -- Apply minimum width
    if calculatedWidth < RCC_Constants.WINDOW_MIN_WIDTH then
        calculatedWidth = RCC_Constants.WINDOW_MIN_WIDTH
    end
    
    -- Calculate height based on number of non-empty categories
    local numCategories = 0
    for _, _ in pairs(categorizedItems) do
        numCategories = numCategories + 1
    end
    
    local calculatedHeight = RCC_Constants.TITLE_HEIGHT + 40 + -- Title and padding
                            (numCategories * (RCC_Constants.CATEGORY_HEADER_HEIGHT + 
                                            RCC_Constants.ICON_SIZE + 30 + -- Icon + name height
                                            RCC_Constants.CATEGORY_SPACING)) +
                            RCC_Constants.CONTENT_MARGIN_BOTTOM
    
    -- Store calculated dimensions
    self.windowWidth = calculatedWidth
    self.windowHeight = calculatedHeight
end

-- ============================================================================
-- GROUP ITEMS BY CATEGORY
-- ============================================================================
function RaidConsumableChecker:GroupItemsByCategory()
    local categorizedItems = {}
    local itemCount = RCC_ConsumableData:GetConsumableCount()
    
    for i = 1, itemCount do
        local itemData = RCC_ConsumableData.Items[i]
        local category = itemData.category or "other"
        
        -- Validate category exists in constants
        local categoryExists = false
        for _, cat in ipairs(RCC_ConsumableData.Categories) do
            if cat.id == category then
                categoryExists = true
                break
            end
        end
        
        -- If category doesn't exist, assign to "other"
        if not categoryExists then
            category = "other"
        end
        
        -- Initialize category array if needed
        if not categorizedItems[category] then
            categorizedItems[category] = {}
        end
        
        -- Add item to category
        table.insert(categorizedItems[category], itemData)
    end
    
    return categorizedItems
end

-- ============================================================================
-- GET CATEGORY INFO BY ID
-- ============================================================================
function RaidConsumableChecker:GetCategoryInfo(categoryId)
    for _, cat in ipairs(RCC_ConsumableData.Categories) do
        if cat.id == categoryId then
            return cat
        end
    end
    return nil
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================
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
    
    -- Background
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
    
    -- Make title bar draggable
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
    
    -- Content frame
    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", RCC_Constants.WINDOW_PADDING, -(RCC_Constants.TITLE_HEIGHT + 20))
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -RCC_Constants.WINDOW_PADDING, RCC_Constants.WINDOW_PADDING)
    contentFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    self.mainFrame = frame
    self.contentFrame = contentFrame
    
    -- Create consumable item frames
    self:CreateConsumableFrames()
    
    -- Register events
    frame:RegisterEvent("BAG_UPDATE")
    frame:SetScript("OnEvent", function()
        RaidConsumableChecker:OnEvent(event)
    end)
    
    -- OnUpdate for buff scanning
    frame:SetScript("OnUpdate", function()
        RaidConsumableChecker:OnUpdate(arg1)
    end)
    
    -- OnShow/OnHide handlers
    frame:SetScript("OnShow", function()
        RaidConsumableChecker:OnShow()
    end)
    frame:SetScript("OnHide", function()
        RaidConsumableChecker:OnHide()
    end)
end

-- ============================================================================
-- CREATE CONSUMABLE ITEM FRAMES
-- ============================================================================
function RaidConsumableChecker:CreateConsumableFrames()
    -- Group items by category
    local categorizedItems = self:GroupItemsByCategory()
    
    -- Sort categories by order
    local sortedCategories = {}
    for categoryId, items in pairs(categorizedItems) do
        local catInfo = self:GetCategoryInfo(categoryId)
        if catInfo then
            table.insert(sortedCategories, {id = categoryId, info = catInfo, items = items})
        end
    end
    
    table.sort(sortedCategories, function(a, b)
        return a.info.order < b.info.order
    end)
    
    -- Create frames for each category
    local currentYOffset = 0
    
    for _, category in ipairs(sortedCategories) do
        -- Create category header
        currentYOffset = self:CreateCategoryHeader(category.info, currentYOffset)
        
        -- Create items for this category
        for i, itemData in ipairs(category.items) do
            local col = (i - 1)
            local xOffset = RCC_Constants.CONTENT_MARGIN_LEFT + (col * (RCC_Constants.ICON_SIZE + RCC_Constants.ICON_SPACING_X))
            local yOffset = currentYOffset
            
            self:CreateItemFrame(itemData, xOffset, yOffset)
        end
        
        -- Move Y offset down for next category
        currentYOffset = currentYOffset - (RCC_Constants.ICON_SIZE + 30 + RCC_Constants.CATEGORY_SPACING)
    end
end

-- ============================================================================
-- CREATE CATEGORY HEADER
-- ============================================================================
function RaidConsumableChecker:CreateCategoryHeader(categoryInfo, yOffset)
    -- Build header text with dashes
    local dashString = string.rep("-", categoryInfo.dashes or 15)
    local headerText = dashString .. " " .. categoryInfo.name .. " " .. dashString
    
    -- Create header text
    local header = self.contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", RCC_Constants.CONTENT_MARGIN_LEFT, yOffset)
    header:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_CATEGORY, "OUTLINE")
    header:SetText(headerText)
    
    local catR, catG, catB, catA = self:HexToRGBA(RCC_Constants.TEXT_COLOR_CATEGORY)
    header:SetTextColor(catR, catG, catB, catA)
    
    return yOffset - RCC_Constants.CATEGORY_HEADER_HEIGHT - 3
end

-- ============================================================================
-- CREATE SINGLE ITEM FRAME
-- ============================================================================
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
    
    -- Icon
    local icon = itemFrame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(RCC_Constants.ICON_SIZE)
    icon:SetHeight(RCC_Constants.ICON_SIZE)
    icon:SetPoint("TOP", itemFrame, "TOP", 0, 0)
    
    -- Set texture with fallback to question mark if invalid or missing
    if not itemData.iconPath or not icon:SetTexture(itemData.iconPath) then
        icon:SetTexture(RCC_Constants.TEXTURE_DEFAULT_ICON)
    end
    
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Icon border
    local border = itemFrame:CreateTexture(nil, "BORDER")
    border:SetWidth(RCC_Constants.ICON_SIZE + RCC_Constants.BORDER_THICKNESS * 2)
    border:SetHeight(RCC_Constants.ICON_SIZE + RCC_Constants.BORDER_THICKNESS * 2)
    border:SetPoint("CENTER", icon, "CENTER", 0, 0)
    border:SetTexture(RCC_Constants.TEXTURE_BORDER)
    
    -- Set initial border color
    if itemData.buffName then
        local inactiveR, inactiveG, inactiveB, inactiveA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_INACTIVE)
        border:SetVertexColor(inactiveR, inactiveG, inactiveB, inactiveA)
    else
        local noBuffR, noBuffG, noBuffB, noBuffA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_NO_BUFF)
        border:SetVertexColor(noBuffR, noBuffG, noBuffB, noBuffA)
    end
    
    -- Counter text (only if requiredCount is defined)
    local counterText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    counterText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 2)
    counterText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_COUNTER, "OUTLINE")
    
    if itemData.requiredCount then
        counterText:SetText("0/" .. itemData.requiredCount)
    else
        counterText:Hide()
    end

    -- Buff time remaining text
    local buffTimeText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffTimeText:SetPoint("CENTER", icon, "CENTER", 0, 8)
    buffTimeText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_BUFF_TIME, "OUTLINE")
    buffTimeText:SetTextColor(1, 1, 1, 1)
    buffTimeText:SetText("")
    buffTimeText:Hide()
    
    -- Item name text
    if RCC_Constants.SHOW_ITEM_NAMES then
        local nameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("TOP", icon, "BOTTOM", 0, -5)
        nameText:SetFont(RCC_Constants.FONT_NORMAL, RCC_Constants.FONT_SIZE_ITEM_NAME, "")
        
        -- Priority: displayName > itemName > first buffName
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
    
    -- Tooltip
    itemFrame:EnableMouse(true)
    itemFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        
        -- Priority: displayName > itemName > first buffName
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
        
        -- Show required count if defined
        if itemData.requiredCount then
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
                
                -- Display buff name(s)
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
        
        -- Show description if available
        if itemData.description then
            local descR, descG, descB, descA = RaidConsumableChecker:HexToRGBA(RCC_Constants.TEXT_COLOR_DESCRIPTION)
            GameTooltip:AddLine(itemData.description, descR, descG, descB, true) -- true = wrap text
        end
        
        -- Show click hint only if item can be used (has itemName and buffName)
        if itemData.buffName and itemData.itemName then
            GameTooltip:AddLine(RCC_Constants.TEXT_TOOLTIP_CLICK_TO_USE, 0.5, 0.5, 1)
        end
        
        GameTooltip:Show()
    end)
    itemFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Click handler (only if item has both buffName and itemName)
    if itemData.buffName and itemData.itemName then
        itemFrame:RegisterForClicks("LeftButtonUp")
        itemFrame:SetScript("OnClick", function()
            RaidConsumableChecker:UseConsumable(itemData)
        end)
    end
    
    -- Store references
    itemFrame.iconBg = iconBg
    itemFrame.icon = icon
    itemFrame.border = border
    itemFrame.counterText = counterText
    itemFrame.itemData = itemData
    itemFrame.buffTimeText = buffTimeText
    
    table.insert(self.itemFrames, itemFrame)
end