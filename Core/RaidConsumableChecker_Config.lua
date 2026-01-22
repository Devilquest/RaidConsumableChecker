-- ============================================================================
-- RaidConsumableChecker_Config.lua
-- Configuration UI for adding/editing/deleting consumables
-- ============================================================================

local CONFIG_ITEM_HEIGHT = 20
local CONFIG_ITEMS_SHOWN = 15
local CONFIG_WINDOW_WIDTH = 650
local CONFIG_WINDOW_HEIGHT = 700

local selectedItemIndex = nil
local selectedCategoryIndex = nil
local isNewItem = false
local isNewCategory = false
local activeTab = "items"

-- ============================================================================
-- HELPER: Tab Navigation for EditBoxes
-- ============================================================================
local function SetupTabNavigation(fields)
    local num = table.getn(fields)
    for i = 1, num do
        local current = fields[i]
        local nextIdx = (i == num) and 1 or (i + 1)
        local prevIdx = (i == 1) and num or (i - 1)
        
        current:SetScript("OnTabPressed", function()
            local target
            local function IsFocusable(f)
                return f:IsVisible() and f:GetAlpha() > 0.6
            end

            if IsShiftKeyDown() then
                local idx = prevIdx
                while not IsFocusable(fields[idx]) and idx ~= i do
                    idx = (idx == 1) and num or (idx - 1)
                end
                target = fields[idx]
            else
                local idx = nextIdx
                while not IsFocusable(fields[idx]) and idx ~= i do
                    idx = (idx == num) and 1 or (idx + 1)
                end
                target = fields[idx]
            end
            if target and IsFocusable(target) then
                target:SetFocus()
            end
        end)
    end
end

-- ============================================================================
-- POPUP DIALOGS
-- ============================================================================
StaticPopupDialogs["RCC_CONFIRM_DELETE_CAT"] = {
    text = "Are you sure you want to delete this category?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        RaidConsumableChecker:ConfirmDeleteConfigCategory()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["RCC_CONFIRM_DELETE_ITEM"] = {
    text = "Are you sure you want to delete this item?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        RaidConsumableChecker:ConfirmDeleteConfigItem()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

-- ============================================================================
-- HELPER: Get Item Name for Display (Consistent Fallback)
-- ============================================================================
local function GetItemConfigName(item)
    if not item then return "Unknown" end
    
    if item.displayName and item.displayName ~= "" then
        return item.displayName
    end
    
    if item.itemName and item.itemName ~= "" then
        return item.itemName
    end
    
    if item.buffName then
        if type(item.buffName) == "table" and table.getn(item.buffName) > 0 then
            return item.buffName[1]
        elseif type(item.buffName) == "string" and item.buffName ~= "" then
            return item.buffName
        end
    end
    
    return "Unknown"
end

-- ============================================================================
-- TOGGLE CONFIGURATION WINDOW
-- ============================================================================
function RaidConsumableChecker:ToggleConfig()
    if not self.configFrame then
        self:CreateConfigFrame()
    end
    
    if self.configFrame:IsVisible() then
        self.configFrame:Hide()
    else
        self.configFrame:Show()
        self:UpdateConfigList()
    end
end

-- ============================================================================
-- HELPER: Clear Focus from all Config Edit Boxes
-- ============================================================================
function RaidConsumableChecker:ClearConfigFocus()
    if self.editItemName then self.editItemName:ClearFocus() end
    if self.editDisplayName then self.editDisplayName:ClearFocus() end
    if self.editBuffName then self.editBuffName:ClearFocus() end
    if self.editItemID then self.editItemID:ClearFocus() end
    if self.editRequiredCount then self.editRequiredCount:ClearFocus() end
    if self.editIconPath then self.editIconPath:ClearFocus() end
    if self.editDescription then self.editDescription:ClearFocus() end
    if self.editCatName then self.editCatName:ClearFocus() end
    if self.editCatDashes then self.editCatDashes:ClearFocus() end
end

-- ============================================================================
-- HELPER: Item Type (Consumable vs Buff) UI Management
-- ============================================================================
function RaidConsumableChecker:SetItemConfigType(itemType, isInitial)
    -- Save current values before switching to Buff (so we can restore them if toggled back)
    if not isInitial and itemType == "buff" then
        self.tempItemName = self.editItemName:GetText()
        self.tempRequiredCount = self.editRequiredCount:GetText()
        self.tempItemID = self.editItemID:GetText()
    end

    if itemType == "consumable" then
        self.checkConsumable:SetChecked(1)
        self.checkBuff:SetChecked(nil)
    else
        self.checkConsumable:SetChecked(nil)
        self.checkBuff:SetChecked(1)
    end
    
    self:UpdateItemTypeUI()

    if not isInitial and itemType == "consumable" then
        if self.tempItemName then self.editItemName:SetText(self.tempItemName) end
        if self.tempRequiredCount then self.editRequiredCount:SetText(self.tempRequiredCount) end
        if self.tempItemID then self.editItemID:SetText(self.tempItemID) end
    end
    
    self:UpdateConfigButtonStates()
end

function RaidConsumableChecker:UpdateItemTypeUI()
    local isBuff = self.checkBuff:GetChecked()
    
    local fields = {
        { ref = self.editItemName, label = self.itemNameLabel, default = "" },
        { ref = self.editRequiredCount, label = self.requiredCountLabel, default = "0" },
        { ref = self.editItemID, label = self.itemIDLabel, default = "" }
    }
    
    for _, field in ipairs(fields) do
        local edit = field.ref
        local label = field.label
        if isBuff then
            edit:SetText(field.default)
            edit:EnableMouse(false)
            edit:ClearFocus()
            edit:SetAlpha(0.5)
            edit:SetTextColor(0.6, 0.6, 0.6)
            if label then label:SetTextColor(0.5, 0.5, 0.5) end
        else
            edit:EnableMouse(true)
            edit:SetAlpha(1.0)
            edit:SetTextColor(1, 1, 1)
            if label then label:SetTextColor(1, 0.82, 0) end
        end
    end
end

-- ============================================================================
-- CREATE CONFIGURATION FRAME
-- ============================================================================
function RaidConsumableChecker:CreateConfigFrame()
    local frame = CreateFrame("Frame", "RCCConfigFrame", UIParent)
    frame:SetWidth(CONFIG_WINDOW_WIDTH)
    frame:SetHeight(CONFIG_WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    
    frame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    bg:SetTexture(0, 0, 0)
    bg:SetAlpha(0.8)
    frame.bg = bg
    
    -- Title
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetWidth(256)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", frame, "TOP", 0, 12)
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)
    titleText:SetText("RCC Configuration")
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    frame:SetScript("OnMouseDown", function() 
        RaidConsumableChecker:ClearConfigFocus()
        if arg1 == "LeftButton" then this:StartMoving() end 
    end)
    frame:SetScript("OnMouseUp", function() 
        if arg1 == "LeftButton" then this:StopMovingOrSizing() end 
    end)
    
    frame:SetScript("OnHide", function()
        RaidConsumableChecker:DiscardConfigChanges()
    end)
    
    self.configFrame = frame
    self.initialConfigState = {}
    
    CONFIG_ITEMS_SHOWN = math.floor((CONFIG_WINDOW_HEIGHT - 100) / CONFIG_ITEM_HEIGHT)

    -- ========================================================================
    -- ITEM MANAGEMENT CONTAINER
    -- ========================================================================
    local itemContainer = CreateFrame("Frame", "RCCConfigItemContainer", frame)
    itemContainer:SetAllPoints(frame)
    itemContainer:EnableMouse(true)
    itemContainer:SetScript("OnMouseDown", function() 
        RaidConsumableChecker:ClearConfigFocus()
        if arg1 == "LeftButton" then this:GetParent():StartMoving() end
    end)
    itemContainer:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then this:GetParent():StopMovingOrSizing() end
    end)
    self.itemContainer = itemContainer
    
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "RCCConfigScrollFrame", itemContainer, "FauxScrollFrameTemplate")
    scrollFrame:SetWidth(250)
    scrollFrame:SetHeight((CONFIG_ITEMS_SHOWN * CONFIG_ITEM_HEIGHT) + 10)
    scrollFrame:SetPoint("TOPLEFT", itemContainer, "TOPLEFT", 20, -35)
    
    scrollFrame.bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    scrollFrame.bg:SetAllPoints(scrollFrame)
    scrollFrame.bg:SetTexture(0, 0, 0, 0.45) -- Slightly darker for better contrast
    
    scrollFrame:SetScript("OnVerticalScroll", function()
        local scrollbar = getglobal(this:GetName().."ScrollBar")
        scrollbar:SetValue(arg1)
        this.offset = math.floor((arg1 / CONFIG_ITEM_HEIGHT) + 0.5)
        RaidConsumableChecker:UpdateConfigList()
    end)
    
    self.configScrollFrame = scrollFrame
    
    -- List items (buttons)
    self.configListButtons = {}
    for i = 1, CONFIG_ITEMS_SHOWN do
    local btn = CreateFrame("Button", nil, itemContainer)
    btn:SetWidth(270)
    btn:SetHeight(CONFIG_ITEM_HEIGHT)
        if i == 1 then
            btn:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", self.configListButtons[i-1], "BOTTOMLEFT", 0, 0)
        end
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(16)
        icon:SetHeight(16)
        icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
        btn.icon = icon

        local btnFont = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        btnFont:SetPoint("TOPLEFT", btn, "TOPLEFT", 24, 0)
        btnFont:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -25, 0)
        btnFont:SetJustifyH("LEFT")
        btn:SetFontString(btnFont)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -20, 0)
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        
        local rowBg = btn:CreateTexture(nil, "BACKGROUND")
        rowBg:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        rowBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -20, 0)
        btn.rowBg = rowBg
        
        btn:SetScript("OnClick", function()
            if StaticPopup_Visible("RCC_CONFIRM_DELETE_ITEM") or StaticPopup_Visible("RCC_CONFIRM_DELETE_CAT") then
                return
            end

            if this.entryType == "header" then
                RaidConsumableChecker:SelectConfigCategoryByID(this.catID)
            else
                RaidConsumableChecker:SelectConfigItem(this.itemIndex)
            end
        end)
        
        btn.itemIndex = 0
        btn.catID = nil
        btn.entryType = nil
        table.insert(self.configListButtons, btn)
    end
    
    -- New/Delete Buttons
    local newBtn = CreateFrame("Button", "RCCConfigNewBtn", itemContainer, "UIPanelButtonTemplate")
    newBtn:SetWidth(85)
    newBtn:SetHeight(24)
    newBtn:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    newBtn:SetText("New Item")
    newBtn:SetScript("OnClick", function() RaidConsumableChecker:NewConfigItem() end)
    
    local newCatBtn = CreateFrame("Button", "RCCConfigNewCatBtnItemTab", itemContainer, "UIPanelButtonTemplate")
    newCatBtn:SetWidth(100)
    newCatBtn:SetHeight(24)
    newCatBtn:SetPoint("LEFT", newBtn, "RIGHT", 5, 0)
    newCatBtn:SetText("New Category")
    newCatBtn:SetScript("OnClick", function() RaidConsumableChecker:NewConfigCategory() end)
    
    local deleteBtn = CreateFrame("Button", "RCCConfigDeleteBtn", itemContainer, "UIPanelButtonTemplate")
    deleteBtn:SetWidth(80)
    deleteBtn:SetHeight(24)
    deleteBtn:SetPoint("LEFT", newCatBtn, "RIGHT", 5, 0)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function() RaidConsumableChecker:DeleteConfigItem() end)
    
    -- ========================================================================
    -- RIGHT SIDE: EDIT FORM CONTAINER
    -- ========================================================================
    local itemFormContainer = CreateFrame("Frame", nil, frame)
    itemFormContainer:SetWidth(320)
    itemFormContainer:SetHeight(CONFIG_WINDOW_HEIGHT - 60)
    itemFormContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 310, 0)
    itemFormContainer:Hide()
    self.itemFormContainer = itemFormContainer

    local formX = 0
    local formY = -35
    local fieldSpacing = 45
    local initialDescHeight = 85
    
    -- Helper to create label + editbox
    local function CreateEditField(container, name, label, yOffset, width, xOffset)
        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", container, "TOPLEFT", (xOffset or formX), yOffset)
        lbl:SetText(label)
        
        local edit = CreateFrame("EditBox", name, container, "InputBoxTemplate")
        edit:SetWidth(width or 200)
        edit:SetHeight(20)
        edit:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 5, -5)
        edit:SetAutoFocus(false)
        return edit, lbl
    end

    -- Item Type (Consumable vs Buff)
    local typeLabel = itemFormContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeLabel:SetPoint("TOPLEFT", itemFormContainer, "TOPLEFT", formX, formY)
    typeLabel:SetText("Type")
    
    self.checkConsumable = CreateFrame("CheckButton", "RCCCheckConsumable", itemFormContainer, "UICheckButtonTemplate")
    self.checkConsumable:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, 0)
    self.checkConsumable:SetWidth(24)
    self.checkConsumable:SetHeight(24)
    getglobal(self.checkConsumable:GetName().."Text"):SetText("Consumable")
    self.checkConsumable:SetScript("OnClick", function()
        if this:GetChecked() then
            RaidConsumableChecker:SetItemConfigType("consumable")
        else
            this:SetChecked(1)
        end
    end)
    
    self.checkBuff = CreateFrame("CheckButton", "RCCCheckBuff", itemFormContainer, "UICheckButtonTemplate")
    self.checkBuff:SetPoint("LEFT", self.checkConsumable, "RIGHT", 100, 0)
    self.checkBuff:SetWidth(24)
    self.checkBuff:SetHeight(24)
    getglobal(self.checkBuff:GetName().."Text"):SetText("Buff")
    self.checkBuff:SetScript("OnClick", function()
        if this:GetChecked() then
            RaidConsumableChecker:SetItemConfigType("buff")
        else
            this:SetChecked(1)
        end
    end)
    
    formY = formY - 40
    
    -- Item Name
    self.editItemName, self.itemNameLabel = CreateEditField(itemFormContainer, "RCCEditItemName", "Item Name (Exact)", formY, 308)
    formY = formY - fieldSpacing
    
    -- Display Name
    self.editDisplayName = CreateEditField(itemFormContainer, "RCCEditDisplayName", "Display Name (Optional)", formY, 308)
    formY = formY - fieldSpacing
    
    -- Buff Name
    self.editBuffName = CreateEditField(itemFormContainer, "RCCEditBuffName", "Buff Name(s) (Comma separated)", formY, 308)
    formY = formY - fieldSpacing
    
    -- Required Count
    self.editRequiredCount, self.requiredCountLabel = CreateEditField(itemFormContainer, "RCCEditRequiredCount", "Required Count", formY, 90)
    self.editRequiredCount:SetNumeric(true)
    
    -- Item ID (on the same line)
    self.editItemID, self.itemIDLabel = CreateEditField(itemFormContainer, "RCCEditItemID", "Item ID (Optional)", formY, 198, formX + 110)
    self.editItemID:SetNumeric(true)
    
    formY = formY - fieldSpacing
    
    -- Icon Path
    self.editIconPath, self.iconLabel = CreateEditField(itemFormContainer, "RCCEditIconPath", "Icon Name (e.g. INV_Potion_77)", formY, 265 )
    
    -- Icon preview and handling
    self.iconPreview = itemFormContainer:CreateTexture(nil, "ARTWORK")
    self.iconPreview:SetWidth(32)
    self.iconPreview:SetHeight(32)
    self.iconPreview:SetPoint("LEFT", self.editIconPath, "RIGHT", 10, 0)
    self.iconPreview:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    
    self.editIconPath:SetScript("OnTextChanged", function()
        local path = this:GetText()
        local fullPath = RaidConsumableChecker:GetFullIconPath(path)
        
        if not RaidConsumableChecker.iconPreview:SetTexture(fullPath) then
            RaidConsumableChecker.iconPreview:SetTexture(RCC_Constants.TEXTURE_DEFAULT_ICON)
        end
        RaidConsumableChecker:UpdateConfigButtonStates()
    end)
    
    formY = formY - fieldSpacing
    
    -- Description
    local descLabel = itemFormContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", itemFormContainer, "TOPLEFT", formX, formY)
    descLabel:SetText("Description")
    
    self.editDescription = CreateFrame("EditBox", nil, itemFormContainer)
    self.editDescription:SetWidth(315)
    self.editDescription:SetHeight(initialDescHeight)
    self.editDescription:SetPoint("TOPLEFT", descLabel, "BOTTOMLEFT", 0, -5)
    self.editDescription:SetMultiLine(true)
    self.editDescription:SetFontObject("GameFontNormal")
    self.editDescription:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    self.editDescription:SetBackdropColor(0, 0, 0, 0.5)
    self.editDescription:SetAutoFocus(false)
    self.editDescription:SetTextInsets(10, 10, 10, 10)
    self.editDescription:SetMaxLetters(255)
    self.editDescription:SetJustifyV("TOP")
    
    local measureFS = itemFormContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    measureFS:SetWidth(295)
    measureFS:Hide()
    
    self.editDescription:SetScript("OnTextChanged", function()
        measureFS:SetText(this:GetText() or "")
        local height = math.max(initialDescHeight, measureFS:GetHeight() + 20)
        this:SetHeight(height)
        RaidConsumableChecker:UpdateConfigButtonStates()
    end)
    
    -- Ensure Display Order is anchored to the dynamic EditBox
    local orderLabel = itemFormContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    orderLabel:SetPoint("TOPLEFT", self.editDescription, "BOTTOMLEFT", 0, -10)
    orderLabel:SetText("Display Order")
    
    local moveUpBtn = CreateFrame("Button", nil, itemFormContainer, "UIPanelButtonTemplate")
    moveUpBtn:SetWidth(40)
    moveUpBtn:SetHeight(22)
    moveUpBtn:SetPoint("TOPLEFT", orderLabel, "BOTTOMLEFT", 5, -5)
    moveUpBtn:SetText("Up")
    moveUpBtn:SetScript("OnClick", function() RaidConsumableChecker:MoveConfigItem("up") end)
    self.itemMoveUpBtn = moveUpBtn
    
    local moveDownBtn = CreateFrame("Button", nil, itemFormContainer, "UIPanelButtonTemplate")
    moveDownBtn:SetWidth(45)
    moveDownBtn:SetHeight(22)
    moveDownBtn:SetPoint("LEFT", moveUpBtn, "RIGHT", 5, 0)
    moveDownBtn:SetText("Down")
    moveDownBtn:SetScript("OnClick", function() RaidConsumableChecker:MoveConfigItem("down") end)
    self.itemMoveDownBtn = moveDownBtn
    
    local fields = { self.editItemName, self.editDisplayName, self.editBuffName, self.editRequiredCount, self.editItemID }
    for _, field in ipairs(fields) do
        field:SetScript("OnTextChanged", function() RaidConsumableChecker:UpdateConfigButtonStates() end)
    end

    -- Setup Tab Navigation for Item Form
    local itemTabFields = { 
        self.editItemName, 
        self.editDisplayName, 
        self.editBuffName, 
        self.editRequiredCount, 
        self.editItemID, 
        self.editIconPath, 
        self.editDescription 
    }
    SetupTabNavigation(itemTabFields)

    -- Coming Soon Tab
    local comingSoonContainer = CreateFrame("Frame", "RCCConfigComingSoonContainer", frame)
    comingSoonContainer:SetAllPoints(frame)
    comingSoonContainer:EnableMouse(true)
    comingSoonContainer:SetScript("OnMouseDown", function() 
        RaidConsumableChecker:ClearConfigFocus()
        if arg1 == "LeftButton" then this:GetParent():StartMoving() end
    end)
    comingSoonContainer:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then this:GetParent():StopMovingOrSizing() end
    end)
    comingSoonContainer:Hide()
    self.comingSoonContainer = comingSoonContainer
    
    local comingSoon = comingSoonContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    comingSoon:SetPoint("CENTER", comingSoonContainer, "CENTER", 0, 0)
    comingSoon:SetText("Coming Soon...")
    local r, g, b = self:HexToRGBA(RCC_Constants.TEXT_COLOR_ADDON_NAME)
    comingSoon:SetTextColor(r, g, b)
    
    -- Category Edit Form
    local catFormContainer = CreateFrame("Frame", nil, frame)
    catFormContainer:SetWidth(320)
    catFormContainer:SetHeight(CONFIG_WINDOW_HEIGHT - 60)
    catFormContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 310, 0)
    catFormContainer:Hide()
    self.catFormContainer = catFormContainer

    local catFormY = -35
    self.editCatName = CreateEditField(catFormContainer, "RCCEditCatName", "Category Name (Display)", catFormY, 308)
    self.editCatName:SetScript("OnTextChanged", function() RaidConsumableChecker:UpdateConfigButtonStates() end)
    
    catFormY = catFormY - fieldSpacing
    
    self.editCatDashes, self.catDashesLabel = CreateEditField(catFormContainer, "RCCEditCatDashes", "Dashes (UI style)", catFormY, 80)
    self.editCatDashes:SetNumeric(true)
    self.editCatDashes:SetScript("OnTextChanged", function() RaidConsumableChecker:UpdateConfigButtonStates() end)
    
    catFormY = catFormY - fieldSpacing
    
    -- Setup Tab Navigation for Category Form
    local catTabFields = { 
        self.editCatName, 
        self.editCatDashes 
    }
    SetupTabNavigation(catTabFields)

    -- Order Section
    local orderLabel = catFormContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    orderLabel:SetPoint("TOPLEFT", catFormContainer, "TOPLEFT", 0, catFormY)
    orderLabel:SetText("Display Order")
    
    local moveUpBtn = CreateFrame("Button", nil, catFormContainer, "UIPanelButtonTemplate")
    moveUpBtn:SetWidth(40)
    moveUpBtn:SetHeight(22)
    moveUpBtn:SetPoint("TOPLEFT", orderLabel, "BOTTOMLEFT", 5, -5)
    moveUpBtn:SetText("Up")
    moveUpBtn:SetScript("OnClick", function() RaidConsumableChecker:MoveConfigCategory("up") end)
    self.catMoveUpBtn = moveUpBtn
    
    local moveDownBtn = CreateFrame("Button", nil, catFormContainer, "UIPanelButtonTemplate")
    moveDownBtn:SetWidth(45)
    moveDownBtn:SetHeight(22)
    moveDownBtn:SetPoint("LEFT", moveUpBtn, "RIGHT", 5, 0)
    moveDownBtn:SetText("Down")
    moveDownBtn:SetScript("OnClick", function() RaidConsumableChecker:MoveConfigCategory("down") end)
    self.catMoveDownBtn = moveDownBtn
    
    -- Tabs Initialization
    local function CreateTab(id, text, xOffset)
        local tab = CreateFrame("Button", "RCCConfigTab"..id, frame, "CharacterFrameTabButtonTemplate")
        tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", xOffset, 8)
        tab:SetText(text)
        tab:SetScript("OnClick", function() RaidConsumableChecker:SwitchConfigTab(id) end)
        return tab
    end
    
    self.tabItems = CreateTab("items", "Consumables & Categories", 5)
    self.tabCategories = CreateTab("categories", "Coming Soon", 175)
    
    -- Action Buttons
    local saveBtn = CreateFrame("Button", "RCCConfigSaveBtn", frame, "UIPanelButtonTemplate")
    saveBtn:SetWidth(100)
    saveBtn:SetHeight(30)
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function() RaidConsumableChecker:SaveConfig() end)
    saveBtn:SetFrameLevel(frame:GetFrameLevel() + 10)
    self.configSaveBtn = saveBtn

    local discardBtn = CreateFrame("Button", "RCCConfigDiscardBtn", frame, "UIPanelButtonTemplate")
    discardBtn:SetWidth(100)
    discardBtn:SetHeight(30)
    discardBtn:SetPoint("RIGHT", saveBtn, "LEFT", -5, 0)
    discardBtn:SetText("Discard")
    discardBtn:SetScript("OnClick", function() RaidConsumableChecker:DiscardConfigChanges() end)
    discardBtn:SetFrameLevel(frame:GetFrameLevel() + 10)
    self.configDiscardBtn = discardBtn
    
    PanelTemplates_SetNumTabs(frame, 2)
    RaidConsumableChecker:SwitchConfigTab("items")
    
    frame:Hide()
end

-- ============================================================================
-- SWITCH TAB
-- ============================================================================
function RaidConsumableChecker:SwitchConfigTab(id)
    activeTab = id
    
    selectedItemIndex = nil
    selectedCategoryIndex = nil
    isNewItem = false
    isNewCategory = false

    self.itemContainer:Hide()
    self.comingSoonContainer:Hide()
    self.itemFormContainer:Hide()
    self.catFormContainer:Hide()
    
    if id == "items" then
        self.itemContainer:Show()
        PanelTemplates_SelectTab(self.tabItems)
        PanelTemplates_DeselectTab(self.tabCategories)
    else
        self.comingSoonContainer:Show()
        PanelTemplates_SelectTab(self.tabCategories)
        PanelTemplates_DeselectTab(self.tabItems)
    end
    self:UpdateConfigList()
    self:UpdateConfigButtonStates()
end

-- ============================================================================
-- DISCARD CHANGES
-- ============================================================================
function RaidConsumableChecker:DiscardConfigChanges()
    if isNewItem then
        isNewItem = false
        selectedItemIndex = nil
        selectedCategoryIndex = nil
        if self.itemFormContainer then self.itemFormContainer:Hide() end
        if self.catFormContainer then self.catFormContainer:Hide() end
        self:UpdateConfigList()
    elseif selectedItemIndex then
        self:SelectConfigItem(selectedItemIndex)
    elseif isNewCategory then
        isNewCategory = false
        selectedCategoryIndex = nil
        if self.catFormContainer then self.catFormContainer:Hide() end
        if self.itemFormContainer then self.itemFormContainer:Hide() end
        self:UpdateConfigList()
    elseif selectedCategoryIndex then
        self:SelectConfigCategory(selectedCategoryIndex)
    end

    self:ClearConfigFocus()
end

-- ============================================================================
-- BUTTON STATE MANAGEMENT
-- ============================================================================

-- Capture initial state of the form to detect changes
function RaidConsumableChecker:CaptureInitialConfigState()
    if not self.initialConfigState then self.initialConfigState = {} end
    
    if isNewItem or selectedItemIndex then
        self.initialConfigState = {
            entryType = self.checkBuff:GetChecked() and "buff" or "consumable",
            itemName = self.editItemName:GetText() or "",
            displayName = self.editDisplayName:GetText() or "",
            buffName = self.editBuffName:GetText() or "",
            itemID = self.editItemID:GetText() or "",
            requiredCount = self.editRequiredCount:GetText() or "",
            iconPath = self.editIconPath:GetText() or "",
            description = self.editDescription:GetText() or ""
        }
    elseif isNewCategory or selectedCategoryIndex then
        self.initialConfigState = {
            name = self.editCatName:GetText() or "",
            dashes = self.editCatDashes:GetText() or ""
        }
    end
    self:UpdateConfigButtonStates()
end

-- Update enabled/disabled state of Save & Discard buttons
function RaidConsumableChecker:UpdateConfigButtonStates()
    local isDirty = false
    local canDiscard = false
    local showButtons = false
    
    if activeTab == "items" then
        if isNewItem or selectedItemIndex then
            showButtons = true

            local nameText = self.editItemName:GetText()
            local buffText = self.editBuffName:GetText()
            local isValid = (nameText ~= "") or (buffText ~= "")
            
            if isNewItem then
                local currentType = self.checkBuff:GetChecked() and "buff" or "consumable"
                isDirty = (currentType ~= "consumable") or
                          (self.editItemName:GetText() ~= "") or
                          (self.editDisplayName:GetText() ~= "") or
                          (self.editBuffName:GetText() ~= "") or
                          (self.editItemID:GetText() ~= "") or
                          (self.editRequiredCount:GetText() ~= "1") or
                          (self.editIconPath:GetText() ~= "INV_Misc_QuestionMark") or
                          (self.editDescription:GetText() ~= "")
                canDiscard = true
            elseif selectedItemIndex then
                if not self.initialConfigState or not self.initialConfigState.entryType then 
                    return 
                end
                
                local currentType = self.checkBuff:GetChecked() and "buff" or "consumable"
                local init = self.initialConfigState
                
                isDirty = (currentType ~= (init.entryType or "consumable")) or
                          (self.editItemName:GetText() ~= (init.itemName or "")) or
                          (self.editDisplayName:GetText() ~= (init.displayName or "")) or
                          (self.editBuffName:GetText() ~= (init.buffName or "")) or
                          (self.editIconPath:GetText() ~= (init.iconPath or "")) or
                          (self.editDescription:GetText() ~= (init.description or "")) or
                          ((tonumber(self.editItemID:GetText()) or 0) ~= (tonumber(init.itemID) or 0)) or
                          ((tonumber(self.editRequiredCount:GetText()) or 0) ~= (tonumber(init.requiredCount) or 0))

                canDiscard = isDirty
            end
            
            isDirty = isDirty and isValid
        elseif isNewCategory or selectedCategoryIndex then
            showButtons = true
            
            local catName = self.editCatName:GetText()
            local isCatValid = (catName ~= "")
            
            if isNewCategory then
                isDirty = true
                canDiscard = true
            elseif selectedCategoryIndex then
                if not self.initialConfigState or not self.initialConfigState.name then 
                    return 
                end
                isDirty = (catName ~= (self.initialConfigState.name or "")) or
                          (self.editCatDashes:GetText() ~= (self.initialConfigState.dashes or ""))
                canDiscard = isDirty
            end
            
            isDirty = isDirty and isCatValid
        end
    end
    
    if showButtons then
        self.configSaveBtn:Show()
        self.configDiscardBtn:Show()
        
        if isDirty then
            self.configSaveBtn:Enable()
        else
            self.configSaveBtn:Disable()
        end
        
        if canDiscard then
            self.configDiscardBtn:Enable()
        else
            self.configDiscardBtn:Disable()
        end
    else
        self.configSaveBtn:Hide()
        self.configDiscardBtn:Hide()
    end
end

-- ============================================================================
-- SAVE DISPATCHER
-- ============================================================================
-- Decide which save function to call based on current context
function RaidConsumableChecker:SaveConfig()
    if isNewItem or selectedItemIndex then
        self:SaveConfigItem()
    elseif isNewCategory or selectedCategoryIndex then
        self:SaveConfigCategory()
    end
end

-- ============================================================================
-- UPDATE CONFIG LIST
-- ============================================================================
function RaidConsumableChecker:UpdateConfigList()
    if activeTab == "items" then
        self:UpdateItemsList()
    end
    self:UpdateCatMoveButtonsState()
end

-- Refresh the list of items in the config window
function RaidConsumableChecker:UpdateItemsList()
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local items = RaidConsumableCheckerDB.ConsumableData.Items
    
    local displayList = self:GetItemsDisplayList()
    local numEntries = table.getn(displayList)
    local entriesToDisplay = math.floor(self.configScrollFrame:GetHeight() / CONFIG_ITEM_HEIGHT)
    
    FauxScrollFrame_Update(self.configScrollFrame, numEntries, entriesToDisplay, CONFIG_ITEM_HEIGHT)
    
    local offset = FauxScrollFrame_GetOffset(self.configScrollFrame)
    
    for i = 1, CONFIG_ITEMS_SHOWN do
        local btn = self.configListButtons[i]
        local listIdx = offset + i
        
        if i <= entriesToDisplay and listIdx <= numEntries then
            local entry = displayList[listIdx]
            btn:SetText(entry.label)
            btn:Show()
            
            if entry.type == "header" then
                btn.rowBg:SetTexture(0.2, 0.15, 0.05, 0.8)
            else
                if math.mod(entry.itemPosition, 2) == 0 then
                    btn.rowBg:SetTexture(0.2, 0.2, 0.25, 0.6)
                else
                    btn.rowBg:SetTexture(0.1, 0.1, 0.15, 0.4)
                end
            end
            
            btn.entryType = entry.type
            btn.catID = entry.id
            btn.itemIndex = entry.index
            
            if entry.type == "header" then
                btn.icon:Hide()
                local r, g, b = self:HexToRGBA(RCC_Constants.TEXT_COLOR_ADDON_NAME)
                btn:GetFontString():SetTextColor(r, g, b)
                btn:GetFontString():SetJustifyH("CENTER")
                btn:UnlockHighlight()
                btn:Enable()
                if entry.id == (selectedCategoryIndex and cats[selectedCategoryIndex].id) then
                    btn:LockHighlight()
                end
            else
                btn.icon:Show()
                local fullPath = RaidConsumableChecker:GetFullIconPath(entry.icon or "INV_Misc_QuestionMark")
                btn.icon:SetTexture(fullPath)
                
                btn:GetFontString():SetTextColor(1, 1, 1)
                btn:GetFontString():SetJustifyH("LEFT")
                btn:Enable()
                if entry.index == selectedItemIndex then
                    btn:LockHighlight()
                else
                    btn:UnlockHighlight()
                end
            end
        else
            btn:Hide()
        end
    end
    
    if self.itemMoveUpBtn and self.itemMoveDownBtn then
        if selectedItemIndex then
            local cats = RaidConsumableCheckerDB.ConsumableData.Categories
            local items = RaidConsumableCheckerDB.ConsumableData.Items
            local currentCatId = items[selectedItemIndex].category
            
            local currentPos = nil
            for j, entry in ipairs(displayList) do
                if entry.type == "item" and entry.index == selectedItemIndex then
                    currentPos = j
                    break
                end
            end
            
            local canUp = false
            local canDown = false
            
            if currentPos then
                if currentPos > 1 then
                    local targetEntry = displayList[currentPos - 1]
                    if targetEntry.type == "item" then
                        canUp = true
                    else
                        local catIdx = 1
                        for k, cat in ipairs(cats) do
                            if cat.id == currentCatId then catIdx = k break end
                        end
                        if catIdx > 1 then canUp = true end
                    end
                end
                
                if currentPos < numEntries then
                    local targetEntry = displayList[currentPos + 1]
                    if targetEntry.type == "item" then
                        canDown = true
                    else
                        local catIdx = 1
                        for k, cat in ipairs(cats) do
                            if cat.id == currentCatId then catIdx = k break end
                        end
                        if catIdx < table.getn(cats) then canDown = true end
                    end
                end
            end
            
            if canUp then self.itemMoveUpBtn:Enable() else self.itemMoveUpBtn:Disable() end
            if canDown then self.itemMoveDownBtn:Enable() else self.itemMoveDownBtn:Disable() end
        else
            self.itemMoveUpBtn:Disable()
            self.itemMoveDownBtn:Disable()
        end
    end
end

-- Update the enabled state of category movement buttons
function RaidConsumableChecker:UpdateCatMoveButtonsState()
    if not (self.catMoveUpBtn and self.catMoveDownBtn) then return end
    
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local numCats = table.getn(cats)
    
    if selectedCategoryIndex then
        if selectedCategoryIndex <= 1 then
            self.catMoveUpBtn:Disable()
        else
            self.catMoveUpBtn:Enable()
        end
        
        if selectedCategoryIndex >= numCats then
            self.catMoveDownBtn:Disable()
        else
            self.catMoveDownBtn:Enable()
        end
    elseif isNewCategory then
        self.catMoveUpBtn:Disable()
        self.catMoveDownBtn:Disable()
    end
end

-- Helper to get the display list with headers and items
function RaidConsumableChecker:GetItemsDisplayList()
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local items = RaidConsumableCheckerDB.ConsumableData.Items
    local displayList = {}
    for _, cat in ipairs(cats) do
        table.insert(displayList, { type = "header", label = "-- " .. string.upper(cat.name or "Unknown") .. " --", id = cat.id })
        local itemPos = 0
        for idx, item in ipairs(items) do
            if item.category == cat.id then
                itemPos = itemPos + 1
                table.insert(displayList, { type = "item", label = GetItemConfigName(item), index = idx, itemPosition = itemPos, icon = item.iconPath })
            end
        end
    end
    return displayList
end

-- Select a category and populate the category edit form
function RaidConsumableChecker:SelectConfigCategory(index)
    selectedCategoryIndex = index
    selectedItemIndex = nil
    isNewCategory = false
    isNewItem = false
    
    self:UpdateConfigList()
    self.itemFormContainer:Hide()
    self.catFormContainer:Show()
    
    local cat = RaidConsumableCheckerDB.ConsumableData.Categories[index]
    if not cat then return end
    
    self.editCatName:SetText(cat.name or "")
    self.editCatDashes:SetText(cat.dashes or "")
    
    self:CaptureInitialConfigState()
end

-- Find and select a category by its internal ID
function RaidConsumableChecker:SelectConfigCategoryByID(catID)
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    for i, cat in ipairs(cats) do
        if cat.id == catID then
            self:SelectConfigCategory(i)
            return
        end
    end
end

-- Initialize the form for a new category
function RaidConsumableChecker:NewConfigCategory()
    selectedCategoryIndex = nil
    isNewCategory = true
    selectedItemIndex = nil
    isNewItem = false
    self:UpdateConfigList()
    self.itemFormContainer:Hide()
    self.catFormContainer:Show()
    
    self.editCatName:SetText("New Category")
    self.editCatDashes:SetText("20")
    
    self.editCatName:SetFocus()
    self:CaptureInitialConfigState()
end

-- Save the current category form data to the database
function RaidConsumableChecker:SaveConfigCategory()
    local name = self.editCatName:GetText()
    
    if not name or name == "" then
        self:Print("Category Name is required.", "error")
        return
    end
    
    local id
    if isNewCategory then
        local cleanName = string.lower(string.gsub(name, "[^%w]", ""))
        id = "cat_" .. cleanName .. "_" .. time()
    else
        id = RaidConsumableCheckerDB.ConsumableData.Categories[selectedCategoryIndex].id
    end

    local newCat = {
        id = id,
        name = name,
        dashes = tonumber(self.editCatDashes:GetText()) or 0
    }
    
    if isNewCategory then
        table.insert(RaidConsumableCheckerDB.ConsumableData.Categories, newCat)
        isNewCategory = false
        selectedCategoryIndex = table.getn(RaidConsumableCheckerDB.ConsumableData.Categories)
    elseif selectedCategoryIndex then
        RaidConsumableCheckerDB.ConsumableData.Categories[selectedCategoryIndex] = newCat
    else
        return
    end
    
    self:UpdateConfigList()
    self:RefreshMainUI()
    self:Print("Category '" .. newCat.name .. "' Saved.", "success")
    self:CaptureInitialConfigState()
end

-- Trigger deletion of a category with a confirmation popup
function RaidConsumableChecker:DeleteConfigCategory()
    if not selectedCategoryIndex then return end
    
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local cat = cats[selectedCategoryIndex]
    local catId = cat.id
    local used = false
    
    for _, item in ipairs(RaidConsumableCheckerDB.ConsumableData.Items) do
        if item.category == catId then
            used = true
            break
        end
    end
    
    if used then
        local catName = cat.name or "Unknown"
        self:Print("Cannot delete category '" .. catName .. "'. It is being used by items.", "error")
        return
    end
    
    local indexToDelete = selectedCategoryIndex
    
    StaticPopupDialogs["RCC_CONFIRM_DELETE_CAT"].text = "Are you sure you want to delete category '" .. (cat.name or "Unknown") .. "'?"
    StaticPopupDialogs["RCC_CONFIRM_DELETE_CAT"].OnAccept = function() 
        RaidConsumableChecker:ConfirmDeleteConfigCategory(indexToDelete) 
    end
    StaticPopup_Show("RCC_CONFIRM_DELETE_CAT")
end

-- Action to delete a category and notify the user
function RaidConsumableChecker:ConfirmDeleteConfigCategory(targetIndex)
    local index = targetIndex or selectedCategoryIndex
    if not index or not RaidConsumableCheckerDB.ConsumableData.Categories[index] then return end
    
    local catName = RaidConsumableCheckerDB.ConsumableData.Categories[index].name or "Unknown"
    
    table.remove(RaidConsumableCheckerDB.ConsumableData.Categories, index)
    
    if selectedCategoryIndex == index then
        selectedCategoryIndex = nil
        self.catFormContainer:Hide()
        self.editCatName:SetText("")
        self.editCatDashes:SetText("")
    elseif selectedCategoryIndex and selectedCategoryIndex > index then
        selectedCategoryIndex = selectedCategoryIndex - 1
    end
    
    self:UpdateConfigList()
    self:RefreshMainUI()
    self:Print("Category '" .. catName .. "' Deleted.", "success")
end

-- Move a category up or down in the list
function RaidConsumableChecker:MoveConfigCategory(direction)
    if not selectedCategoryIndex then return end
    
    local data = RaidConsumableCheckerDB.ConsumableData.Categories
    local newIndex = selectedCategoryIndex
    
    if direction == "up" then
        newIndex = selectedCategoryIndex - 1
    else
        newIndex = selectedCategoryIndex + 1
    end
    
    if newIndex < 1 or newIndex > table.getn(data) then
        return
    end
    
    local temp = data[selectedCategoryIndex]
    data[selectedCategoryIndex] = data[newIndex]
    data[newIndex] = temp
    
    selectedCategoryIndex = newIndex
    
    self:UpdateConfigList()
    self:RefreshMainUI()
end

-- Select an item from the list and populate the edit form
function RaidConsumableChecker:SelectConfigItem(index)
    selectedItemIndex = index
    selectedCategoryIndex = nil
    isNewItem = false
    isNewCategory = false
    
    self:UpdateConfigList()
    self.catFormContainer:Hide()
    self.itemFormContainer:Show()
    
    local item = RaidConsumableCheckerDB.ConsumableData.Items[index]
    if not item then return end
    
    self.tempItemName = nil
    self.tempRequiredCount = nil
    self.tempItemID = nil
    
    self:SetItemConfigType(item.entryType or "consumable", true)
    
    self.editItemName:SetText(item.itemName or "")
    self.editDisplayName:SetText(item.displayName or "")
    
    if type(item.buffName) == "table" then
        self.editBuffName:SetText(table.concat(item.buffName, ", "))
    else
        self.editBuffName:SetText(item.buffName or "")
    end
    
    self.editItemID:SetText(item.itemID or "")
    self.editRequiredCount:SetText(item.requiredCount or "")
    
    self.currentCategory = item.category or "category1"
    
    local displayPath = item.iconPath or ""
    displayPath = string.gsub(displayPath, "[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee]\\[Ii][Cc][Oo][Nn][Ss]\\", "")
    displayPath = string.gsub(displayPath, "[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee]/[Ii][Cc][Oo][Nn][Ss]/", "")
    
    self.editIconPath:SetText(displayPath)
    self.editDescription:SetText(item.description or "")
    
    self:CaptureInitialConfigState()
end

-- ============================================================================
-- NEW ITEM
-- ============================================================================
-- Initialize the form for a new item
function RaidConsumableChecker:NewConfigItem()
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local numCats = table.getn(cats)
    local targetCatID = nil
    local targetCatIdx = nil
    
    if selectedItemIndex then
        local item = RaidConsumableCheckerDB.ConsumableData.Items[selectedItemIndex]
        if item then
            targetCatID = item.category
            for i, cat in ipairs(cats) do
                if cat.id == targetCatID then
                    targetCatIdx = i
                    break
                end
            end
        end
    elseif selectedCategoryIndex and cats[selectedCategoryIndex] then
        targetCatID = cats[selectedCategoryIndex].id
        targetCatIdx = selectedCategoryIndex
    elseif numCats > 0 then
        targetCatID = cats[numCats].id
        targetCatIdx = numCats
    end

    selectedItemIndex = nil
    isNewItem = true
    selectedCategoryIndex = targetCatIdx
    isNewCategory = false
    self.currentCategory = targetCatID or "category1"
    
    self:UpdateConfigList()
    self.catFormContainer:Hide()
    self.itemFormContainer:Show()
    
    self:SetItemConfigType("consumable")
    
    self.editItemName:SetText("")
    self.editDisplayName:SetText("")
    self.editBuffName:SetText("")
    self.editItemID:SetText("")
    self.editRequiredCount:SetText("1")
    self.editIconPath:SetText("INV_Misc_QuestionMark")
    self.editDescription:SetText("")
    
    self.editItemName:SetFocus()
    self:CaptureInitialConfigState()
end


-- Save the current item form data to the database
function RaidConsumableChecker:SaveConfigItem()
    local name = self.editItemName:GetText()
    local buff = self.editBuffName:GetText() 
    
    if (name == nil or name == "") and (buff == nil or buff == "") then
        self:Print("Must provide at least Item Name or Buff Name.", "error")
        return
    end
    
    local newItem = {}
    if name and name ~= "" then newItem.itemName = name end
    
    local dName = self.editDisplayName:GetText()
    if dName and dName ~= "" then newItem.displayName = dName end
    
    if buff and buff ~= "" then
        if string.find(buff, ",") then
            newItem.buffName = {}
            for s in string.gfind(buff, "([^,]+)") do
                s = string.gsub(s, "^%s*(.-)%s*$", "%1")
                table.insert(newItem.buffName, s)
            end
        else
            newItem.buffName = buff
        end
    end
    
    local id = tonumber(self.editItemID:GetText())
    if id then newItem.itemID = id end
    
    local req = tonumber(self.editRequiredCount:GetText())
    if req and req > 0 then newItem.requiredCount = req end
    
    local isBuffMode = self.checkBuff:GetChecked()
    local finalType = isBuffMode and "buff" or "consumable"
    
    if not isBuffMode then
        local hasItemName = (newItem.itemName and newItem.itemName ~= "")
        local hasReqCount = (newItem.requiredCount and newItem.requiredCount > 0)
        local hasBuffs = false
        if type(newItem.buffName) == "table" then
            hasBuffs = (table.getn(newItem.buffName) > 0)
        else
            hasBuffs = (newItem.buffName and newItem.buffName ~= "")
        end
        
        if not hasItemName and not hasReqCount and hasBuffs then
            finalType = "buff"
        end
    end
    
    newItem.entryType = finalType
    newItem.category = self.currentCategory
    local normalizedIcon = self:NormalizeIconPath(self.editIconPath:GetText())
    newItem.iconPath = normalizedIcon
    self.editIconPath:SetText(normalizedIcon)
    
    newItem.description = self.editDescription:GetText()
    
    if isNewItem then
        table.insert(RaidConsumableCheckerDB.ConsumableData.Items, newItem)
        isNewItem = false
        selectedItemIndex = table.getn(RaidConsumableCheckerDB.ConsumableData.Items)
    elseif selectedItemIndex then
        RaidConsumableCheckerDB.ConsumableData.Items[selectedItemIndex] = newItem
    else
        return
    end
    
    selectedCategoryIndex = nil
    self:UpdateConfigList()
    self:RefreshMainUI()
    
    local itemName = GetItemConfigName(newItem)
    self:Print("Item '" .. itemName .. "' Saved.", "success")
    
    self:SetItemConfigType(finalType, true)
    self:CaptureInitialConfigState()
end

-- Trigger deletion of an item or category with confirmation
function RaidConsumableChecker:DeleteConfigItem()
    if selectedItemIndex then
        local item = RaidConsumableCheckerDB.ConsumableData.Items[selectedItemIndex]
        if not item then return end
        
        local itemName = GetItemConfigName(item)
        local indexToDelete = selectedItemIndex
        
        StaticPopupDialogs["RCC_CONFIRM_DELETE_ITEM"].text = "Are you sure you want to delete item '" .. itemName .. "'?"
        StaticPopupDialogs["RCC_CONFIRM_DELETE_ITEM"].OnAccept = function() 
            RaidConsumableChecker:DoDeleteConfigItem(indexToDelete) 
        end
        StaticPopup_Show("RCC_CONFIRM_DELETE_ITEM")
    elseif selectedCategoryIndex then
        self:DeleteConfigCategory()
    else
        self:Print("Please select an item or category to delete.", "error")
    end
end

-- Action to delete an item and notify the user
function RaidConsumableChecker:DoDeleteConfigItem(targetIndex)
    local index = targetIndex or selectedItemIndex
    if not index or not RaidConsumableCheckerDB.ConsumableData.Items[index] then return end
    
    local item = RaidConsumableCheckerDB.ConsumableData.Items[index]
    local itemName = GetItemConfigName(item)
    
    table.remove(RaidConsumableCheckerDB.ConsumableData.Items, index)
    
    if selectedItemIndex == index then
        selectedItemIndex = nil
        self.itemFormContainer:Hide()
        self.editItemName:SetText("")
        self.editDisplayName:SetText("")
        self.editBuffName:SetText("")
        self.editItemID:SetText("")
        self.editRequiredCount:SetText("")
        self.editIconPath:SetText("")
        self.editDescription:SetText("")
    elseif selectedItemIndex and selectedItemIndex > index then
        selectedItemIndex = selectedItemIndex - 1
    end
    
    self:UpdateConfigList()
    self:RefreshMainUI()
    self:Print("Item '" .. itemName .. "' Deleted.", "success")
end

-- Move an item up or down, potentially across category headers
function RaidConsumableChecker:MoveConfigItem(direction)
    if not selectedItemIndex then return end
    
    local items = RaidConsumableCheckerDB.ConsumableData.Items
    local cats = RaidConsumableCheckerDB.ConsumableData.Categories
    local displayList = self:GetItemsDisplayList()
    
    local currentPos = nil
    for i, entry in ipairs(displayList) do
        if entry.type == "item" and entry.index == selectedItemIndex then
            currentPos = i
            break
        end
    end
    
    if not currentPos then return end
    
    local targetPos = (direction == "up") and (currentPos - 1) or (currentPos + 1)
    if targetPos < 1 or targetPos > table.getn(displayList) then return end
    
    local targetEntry = displayList[targetPos]
    
    if targetEntry.type == "item" then
        local temp = items[selectedItemIndex]
        items[selectedItemIndex] = items[targetEntry.index]
        items[targetEntry.index] = temp
        selectedItemIndex = targetEntry.index
    else
        local item = items[selectedItemIndex]
        local currentCatId = item.category
        
        local catIdx = 1
        for i, cat in ipairs(cats) do
            if cat.id == currentCatId then catIdx = i break end
        end
        
        if direction == "up" then
            if catIdx > 1 then
                item.category = cats[catIdx-1].id
                local itemToMove = table.remove(items, selectedItemIndex)
                table.insert(items, itemToMove)
                selectedItemIndex = table.getn(items)
            end
        else
            if catIdx < table.getn(cats) then
                item.category = cats[catIdx+1].id
                local itemToMove = table.remove(items, selectedItemIndex)
                table.insert(items, 1, itemToMove)
                selectedItemIndex = 1
            end
        end
    end
    
    self:UpdateConfigList()
    self:RefreshMainUI()
end

-- Refresh the main addon window dimensions and content
function RaidConsumableChecker:RefreshMainUI()
    self:CalculateWindowDimensions()
    self.mainFrame:SetWidth(self.windowWidth)
    self.mainFrame:SetHeight(self.windowHeight)
    self.mainFrame:SetBackdropColor(self:HexToRGBA(RCC_Constants.BACKGROUND_COLOR))
    
    if self.titleBar then
        self.titleBar:SetWidth(self.windowWidth - 20)
    end
    
    self:CreateConsumableFrames()
    self:UpdateConsumables()
    self:UpdateBuffs()
end