-- ============================================================================
-- RaidConsumableChecker_Buffs.lua
-- Buff checking, consumable usage, and inventory management
-- ============================================================================

-- ============================================================================
-- INVENTORY UPDATES
-- ============================================================================

-- Update inventory counts for all displayed item frames
function RaidConsumableChecker:UpdateConsumables()
    for i, itemFrame in ipairs(self.itemFrames) do
        local itemData = itemFrame.itemData
        
        if itemData.requiredCount and itemData.requiredCount > 0 then
            local count = self:GetItemCount(itemData.itemName)
            local counterText = string.format(RCC_Constants.TEXT_COUNTER_FORMAT, count, itemData.requiredCount)
            itemFrame.counterText:SetText(counterText)
            
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
-- BUFF & BORDER STATUS
-- ============================================================================


-- Refresh all buff-related indicators (timers and borders)
function RaidConsumableChecker:UpdateBuffs()
    for i, itemFrame in ipairs(self.itemFrames) do
        local itemData = itemFrame.itemData
        
        if itemData.buffName then
            local hasBuff = self:HasBuff(itemData.buffName)
            
            if hasBuff then
                local timeRemaining = self:GetBuffTimeRemaining(itemData.buffName)
                if timeRemaining and timeRemaining > 0 then
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
                
                if timeRemaining and timeRemaining > 0 and timeRemaining < RCC_Constants.BUFF_WARNING_THRESHOLD then
                    local warnR, warnG, warnB, warnA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_WARNING)
                    itemFrame.border:SetVertexColor(warnR, warnG, warnB, warnA)
                else
                    local activeR, activeG, activeB, activeA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_ACTIVE)
                    itemFrame.border:SetVertexColor(activeR, activeG, activeB, activeA)
                end
            else
                itemFrame.buffTimeText:Hide()
                local inactiveR, inactiveG, inactiveB, inactiveA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_BUFF_INACTIVE)
                itemFrame.border:SetVertexColor(inactiveR, inactiveG, inactiveB, inactiveA)
            end
        else
            itemFrame.buffTimeText:Hide()
            local noBuffR, noBuffG, noBuffB, noBuffA = self:HexToRGBA(RCC_Constants.BORDER_COLOR_NO_BUFF)
            itemFrame.border:SetVertexColor(noBuffR, noBuffG, noBuffB, noBuffA)
        end
    end
end

-- ============================================================================
-- CONSUMABLE ACTIONS
-- ============================================================================

-- Handle consumable usage with optional confirmation if buff is already active
function RaidConsumableChecker:UseConsumable(itemData)
    if not itemData.itemName then
        return
    end
    
    local itemCount = self:GetItemCount(itemData.itemName)
    if itemCount == 0 then
        return
    end
    
    local hasBuff = self:HasBuff(itemData.buffName)

    if hasBuff then
        local displayName = itemData.buffName
        if itemData.buffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            displayName = itemData.itemName
        elseif type(itemData.buffName) == "table" then
            displayName = itemData.buffName[1]
        end
        
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
        self:DoUseConsumable(itemData.itemName)
    end
end

-- Execute the actual item usage through bag scanning
function RaidConsumableChecker:DoUseConsumable(itemName)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, name = string.find(link, "%[(.+)%]")
                    if name and name == itemName then
                        UseContainerItem(bag, slot)
                        
                        self:UpdateConsumables()
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
-- DATA RETRIEVAL
-- ============================================================================

-- Count occurrences of a specific item across all bags
function RaidConsumableChecker:GetItemCount(itemName)
    local count = 0
    
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, name = string.find(link, "%[(.+)%]")
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

-- Check if player currently has a specific buff active
function RaidConsumableChecker:HasBuff(buffName)
    if not buffName then
        return false
    end
    
    local buffNames = {}
    if type(buffName) == "table" then
        buffNames = buffName
    else
        buffNames = {buffName}
    end
    
    for _, currentBuffName in ipairs(buffNames) do
        if currentBuffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            if self:HasWeaponEnchant() then
                return true
            end
        else
            local trimmedBuffName = string.gsub(currentBuffName, "^%s*(.-)%s*$", "%1")
            local i = 0
            while GetPlayerBuff(i, "HELPFUL") >= 0 do
                local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
                
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

-- Get the remaining duration of an active buff
function RaidConsumableChecker:GetBuffTimeRemaining(buffName)
    if not buffName then
        return nil
    end
    
    local buffNames = {}
    if type(buffName) == "table" then
        buffNames = buffName
    else
        buffNames = {buffName}
    end
    
    for _, currentBuffName in ipairs(buffNames) do
        if currentBuffName == RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON then
            local hasMainHandEnchant, mainHandExpiration, mainHandCharges = GetWeaponEnchantInfo()
            if hasMainHandEnchant and mainHandExpiration then
                return mainHandExpiration / 1000
            end
        else
            local trimmedBuffName = string.gsub(currentBuffName, "^%s*(.-)%s*$", "%1")
            local i = 0
            while GetPlayerBuff(i, "HELPFUL") >= 0 do
                local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
                
                RCCTooltip = RCCTooltip or CreateFrame("GameTooltip", "RCCTooltip", nil, "GameTooltipTemplate")
                RCCTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                RCCTooltip:SetPlayerBuff(buffIndex)
                
                local tooltipText = RCCTooltipTextLeft1:GetText()
                if tooltipText then
                    local trimmedTooltipText = string.gsub(tooltipText, "^%s*(.-)%s*$", "%1")
                    if trimmedTooltipText == trimmedBuffName then
                        return GetPlayerBuffTimeLeft(buffIndex)
                    end
                end
                i = i + 1
            end
        end
    end
    
    return nil
end

-- Convert buff duration in seconds to a human-readable format
function RaidConsumableChecker:FormatBuffTime(timeInSeconds)
    if not timeInSeconds or timeInSeconds <= 0 then
        return ""
    end
    
    if timeInSeconds < 60 then
        return "< 1m"
    end
    if timeInSeconds < 3600 then
        return math.ceil(timeInSeconds / 60) .. "m"
    end
    if timeInSeconds < 86400 then
        return math.ceil(timeInSeconds / 3600) .. "h"
    end
    
    return math.ceil(timeInSeconds / 86400) .. "d"
end

-- Check for any active temporary melee weapon enchant
function RaidConsumableChecker:HasWeaponEnchant()
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges = GetWeaponEnchantInfo()
    if hasMainHandEnchant then
        return true
    end
    return false
end