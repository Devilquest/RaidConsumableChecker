-- ============================================================================
-- RaidConsumableChecker_Buffs.lua
-- Buff checking, consumable usage, and inventory management
-- ============================================================================

-- ============================================================================
-- UPDATE CONSUMABLE DISPLAY (inventory count only)
-- Only updates if requiredCount is defined
-- ============================================================================
function RaidConsumableChecker:UpdateConsumables()
    for i, itemFrame in ipairs(self.itemFrames) do
        local itemData = itemFrame.itemData
        
        -- Only update counter if requiredCount is defined
        if itemData.requiredCount then
            local count = self:GetItemCount(itemData.itemName)
            
            -- Update counter text
            local counterText = string.format(RCC_Constants.TEXT_COUNTER_FORMAT, count, itemData.requiredCount)
            itemFrame.counterText:SetText(counterText)
            
            -- Update counter text color based on inventory count
            if count >= itemData.requiredCount then
                local textSuffR, textSuffG, textSuffB = self:HexToRGBA(RCC_Constants.TEXT_COLOR_SUFFICIENT)
                itemFrame.counterText:SetTextColor(textSuffR, textSuffG, textSuffB)
            else
                local textInsuffR, textInsuffG, textInsuffB = self:HexToRGBA(RCC_Constants.TEXT_COLOR_INSUFFICIENT)
                itemFrame.counterText:SetTextColor(textInsuffR, textInsuffG, textInsuffB)
            end
        end
    end
end

-- ============================================================================
-- UPDATE BORDER COLORS BASED ON BUFF STATUS
-- ============================================================================
function RaidConsumableChecker:UpdateBordersByBuffStatus()
    for i, itemFrame in ipairs(self.itemFrames) do
        local itemData = itemFrame.itemData
        
        -- Only update border for items with buffs
        if itemData.buffName then
            local hasBuff = self:HasBuff(itemData.buffName)
            
            if hasBuff then
                -- Get time remaining to determine color
                local timeRemaining = self:GetBuffTimeRemaining(itemData.buffName)
                
                if timeRemaining and timeRemaining < RCC_Constants.BUFF_WARNING_THRESHOLD then
                    -- Orange - buff active but less than 5 minutes remaining
                    local warnR, warnG, warnB, warnA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_WARNING)
                    itemFrame.border:SetVertexColor(warnR, warnG, warnB, warnA)
                else
                    -- Green - buff active with more than 5 minutes
                    local activeR, activeG, activeB, activeA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_ACTIVE)
                    itemFrame.border:SetVertexColor(activeR, activeG, activeB, activeA)
                end
            else
                -- Red - buff not active
                local inactiveR, inactiveG, inactiveB, inactiveA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_INACTIVE)
                itemFrame.border:SetVertexColor(inactiveR, inactiveG, inactiveB, inactiveA)
            end
        end
    end
end

-- ============================================================================
-- UPDATE BUFF INDICATORS AND BORDERS
-- ============================================================================
function RaidConsumableChecker:UpdateBuffs()
    for i, itemFrame in ipairs(self.itemFrames) do
        local itemData = itemFrame.itemData
        
        if itemData.buffName then
            local hasBuff = self:HasBuff(itemData.buffName)
            
            if hasBuff then
                -- Update buff time text
                local timeRemaining = self:GetBuffTimeRemaining(itemData.buffName)
                if timeRemaining then
                    local formattedTime = self:FormatBuffTime(timeRemaining)
                    if formattedTime ~= "" then
                        itemFrame.buffTimeText:SetText(formattedTime)
                        itemFrame.buffTimeText:Show()
                    else
                        itemFrame.buffTimeText:Hide()
                    end
                else
                    itemFrame.buffTimeText:Hide()
                end
            else
                -- Hide buff time text when buff is not active
                itemFrame.buffTimeText:Hide()
            end
        else
            -- No buff for this item, hide time
            itemFrame.buffTimeText:Hide()
        end
    end
    
    -- Also update borders based on buff status
    self:UpdateBordersByBuffStatus()
end

-- ============================================================================
-- USE CONSUMABLE
-- ============================================================================
function RaidConsumableChecker:UseConsumable(itemData)
    -- If no itemName, this is a buff-only entry (cannot be used)
    if not itemData.itemName then
        return
    end
    
    -- Check if player has the item in bags
    local itemCount = self:GetItemCount(itemData.itemName)
    if itemCount == 0 then
        return
    end
    
    -- Check if player already has the buff
    local hasBuff = self:HasBuff(itemData.buffName)

    if hasBuff then
        -- For weapon enchants, show item name instead of EQUIPPED_WEAPON
        local displayName = itemData.buffName
        if itemData.buffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            displayName = itemData.itemName
        elseif type(itemData.buffName) == "table" then
            -- If buffName is a table, show the first one for display
            displayName = itemData.buffName[1]
        end
        
        -- Show confirmation dialog
        StaticPopupDialogs["RCC_CONFIRM_USE"] = {
            text = string.format(RCC_Constants.TEXT_CONFIRM_MESSAGE, displayName, itemData.itemName),
            button1 = RCC_Constants.TEXT_CONFIRM_ACCEPT,
            button2 = RCC_Constants.TEXT_CONFIRM_CANCEL,
            OnAccept = function()
                RaidConsumableChecker:DoUseConsumable(itemData.itemName)
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1
        }
        StaticPopup_Show("RCC_CONFIRM_USE")
    else
        -- Use directly if no buff active
        self:DoUseConsumable(itemData.itemName)
    end
end

-- ============================================================================
-- ACTUALLY USE THE CONSUMABLE
-- ============================================================================
function RaidConsumableChecker:DoUseConsumable(itemName)
    -- Find the item in bags and use it
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local name = string.match(link, "%[(.+)%]")
                    if name and name == itemName then
                        UseContainerItem(bag, slot)
                        
                        -- Update consumables count immediately
                        self:UpdateConsumables()
                        
                        -- Schedule buff update after a short delay
                        self.pendingBuffUpdate = true
                        self.buffUpdateTimer = 0
                        
                        return
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- GET ITEM COUNT IN BAGS
-- ============================================================================
function RaidConsumableChecker:GetItemCount(itemName)
    local count = 0
    
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local name = string.match(link, "%[(.+)%]")
                    if name and name == itemName then
                        local _, stackCount = GetContainerItemInfo(bag, slot)
                        count = count + math.abs(stackCount or 1)
                    end
                end
            end
        end
    end
    
    return count
end

-- ============================================================================
-- CHECK IF PLAYER HAS BUFF
-- Supports both single buff name (string) and multiple buff names (table)
-- ============================================================================
function RaidConsumableChecker:HasBuff(buffName)
    -- Handle nil case
    if not buffName then
        return false
    end
    
    -- Convert single string to table for unified processing
    local buffNames = {}
    if type(buffName) == "table" then
        buffNames = buffName
    else
        buffNames = {buffName}
    end
    
    -- Check each buff name in the list
    for _, currentBuffName in ipairs(buffNames) do
        -- Handle special case: EQUIPPED_WEAPON (for weapon enchants)
        if currentBuffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            if self:HasWeaponEnchant() then
                return true
            end
        else
            -- Trim the buff name
            local trimmedBuffName = string.gsub(currentBuffName, "^%s*(.-)%s*$", "%1")
            
            -- Use old API: GetPlayerBuff
            local i = 0
            while GetPlayerBuff(i, "HELPFUL") >= 0 do
                local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
                
                -- Use tooltip to get buff name
                RCCTooltip = RCCTooltip or CreateFrame("GameTooltip", "RCCTooltip", nil, "GameTooltipTemplate")
                RCCTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                RCCTooltip:SetPlayerBuff(buffIndex)
                
                local tooltipText = RCCTooltipTextLeft1:GetText()
                
                if tooltipText then
                    local trimmedTooltipText = string.gsub(tooltipText, "^%s*(.-)%s*$", "%1")
                    
                    if trimmedTooltipText == trimmedBuffName then
                        return true
                    end
                end
                
                i = i + 1
            end
        end
    end
    
    return false
end

-- ============================================================================
-- GET BUFF TIME REMAINING
-- Supports both single buff name (string) and multiple buff names (table)
-- Returns time remaining for the first matching buff found
-- ============================================================================
function RaidConsumableChecker:GetBuffTimeRemaining(buffName)
    -- Handle nil case
    if not buffName then
        return nil
    end
    
    -- Convert single string to table for unified processing
    local buffNames = {}
    if type(buffName) == "table" then
        buffNames = buffName
    else
        buffNames = {buffName}
    end
    
    -- Check each buff name in the list
    for _, currentBuffName in ipairs(buffNames) do
        -- Handle special case: EQUIPPED_WEAPON
        if currentBuffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            local hasMainHandEnchant, mainHandExpiration, mainHandCharges = GetWeaponEnchantInfo()
            if hasMainHandEnchant and mainHandExpiration then
                local timeInSeconds = mainHandExpiration / 1000
                return timeInSeconds
            end
        else
            -- Trim the buff name
            local trimmedBuffName = string.gsub(currentBuffName, "^%s*(.-)%s*$", "%1")
            
            -- Use old API: GetPlayerBuff + GetPlayerBuffTimeLeft
            local i = 0
            while GetPlayerBuff(i, "HELPFUL") >= 0 do
                local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
                
                -- Use tooltip to get buff name
                RCCTooltip = RCCTooltip or CreateFrame("GameTooltip", "RCCTooltip", nil, "GameTooltipTemplate")
                RCCTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                RCCTooltip:SetPlayerBuff(buffIndex)
                
                local tooltipText = RCCTooltipTextLeft1:GetText()
                
                if tooltipText then
                    local trimmedTooltipText = string.gsub(tooltipText, "^%s*(.-)%s*$", "%1")
                    
                    if trimmedTooltipText == trimmedBuffName then
                        local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
                        return timeLeft
                    end
                end
                
                i = i + 1
            end
        end
    end
    
    return nil
end

-- ============================================================================
-- FORMAT BUFF TIME FOR DISPLAY
-- ============================================================================
function RaidConsumableChecker:FormatBuffTime(timeInSeconds)
    if not timeInSeconds or timeInSeconds <= 0 then
        return ""
    end
    
    -- Less than 1 minute
    if timeInSeconds < 60 then
        return "< 1m"
    end
    
    -- Less than 1 hour (show minutes)
    if timeInSeconds < 3600 then
        local minutes = math.ceil(timeInSeconds / 60)
        return minutes .. "m"
    end
    
    -- Less than 1 day (show hours)
    if timeInSeconds < 86400 then
        local hours = math.ceil(timeInSeconds / 3600)
        return hours .. "h"
    end
    
    -- 1 day or more (show days)
    local days = math.ceil(timeInSeconds / 86400)
    return days .. "d"
end

-- ============================================================================
-- CHECK IF PLAYER HAS WEAPON ENCHANT
-- ============================================================================
function RaidConsumableChecker:HasWeaponEnchant()
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges = GetWeaponEnchantInfo()
    
    if hasMainHandEnchant then
        return true
    end
    
    return false
end