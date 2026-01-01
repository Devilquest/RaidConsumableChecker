-- ============================================================================
-- RaidConsumableChecker_Data.lua
-- Consumable items data for raid preparation
-- ============================================================================

RCC_ConsumableData = {}

-- ============================================================================
-- CATEGORIES
-- User can modify these categories to organize consumables
-- ============================================================================
RCC_ConsumableData.Categories = {
    {id = "category1", name = "Flasks / Oil / Food", order = 1, dashes = 15},
    {id = "category2", name = "Main Elixirs", order = 2, dashes = 19},
    {id = "category3", name = "Situational", order = 3, dashes = 19},
    {id = "category4", name = "Protection Potions", order = 4, dashes = 15},
    {id = "category5", name = "Potions", order = 5, dashes = 21},
    {id = "other", name = "Other", order = 99, dashes = 22} -- Default category for uncategorized items
}

-- ============================================================================
-- CONSUMABLE LIST
-- Each entry contains:
--   itemName: Name of the item (must match exact item name in game)
--   itemID: (Optional) Item ID for reference
--   iconPath: Path to the item icon texture
--   requiredCount: How many of this item you should have
--   buffName: (Optional) Name of the buff provided by this consumable (for buff checking)
--             If not specified, item will be treated as having no buff (e.g., instant effect potions like healing/mana)
--   description: (Optional) Description text to show in tooltip
--   category: Category identifier for grouping items
-- ============================================================================

RCC_ConsumableData.Items = {
    -- ========================================================================
    -- FLASKS, OILS & FOOD (Example: 3 items in same category)
    -- ========================================================================
    {
        itemName = "Flask of Supreme Power",
        itemID = 13512,
        iconPath = "Interface\\Icons\\INV_Potion_41",
        requiredCount = 1,
        buffName = "Supreme Power",
        description = "Increases damage done by magical spells and effects by up to 150 for 2 hrs.",
        category = "category1"
    },
    {
        itemName = "Wizard Oil",
        itemID = 20750,
        iconPath = "Interface\\Icons\\INV_Potion_104",
        requiredCount = 4,
        buffName = "EQUIPPED_WEAPON", -- Special case: weapon enchant
        description = "Increases spell damage by up to 24 for 30 min.",
        category = "category1"
    },
    {
        itemName = "Runn Tum Tuber Surprise",
        itemID = 18254,
        iconPath = "Interface\\Icons\\INV_Misc_Food_63",
        requiredCount = 20,
        buffName = "Well Fed",
        description = "Restores 1933 health over 27 sec. Also increases your Intellect by 10 for 10 min.",
        category = "category1"
    },

    -- ========================================================================
    -- MAIN ELIXIRS
    -- ========================================================================
    {
        itemName = "Greater Arcane Elixir",
        itemID = 13454,
        iconPath = "Interface\\Icons\\INV_Potion_25",
        requiredCount = 2,
        buffName = "Greater Arcane Elixir",
        description = "Increases spell damage by up to 35 for 1 hour.",
        category = "category2"
    },
    {
        itemName = "Mighty Troll's Blood Potion",
        itemID = 3826,
        iconPath = "Interface\\Icons\\INV_Potion_79",
        requiredCount = 2,
        buffName = "Regeneration", -- Note: buff name differs from item name
        description = "Regenerate 12 health every 5 sec for 1 hour.",
        category = "category2"
    },

    -- ========================================================================
    -- SITUATIONAL (Example: 2 items, one with buff, one without)
    -- ========================================================================
    {
        itemName = "Juju Ember",
        itemID = 12455,
        iconPath = "Interface\\Icons\\INV_Misc_Monsterscales_15",
        requiredCount = 10,
        buffName = "Juju Ember",
        description = "Increases Fire resistance by 15 for 10 min.",
        category = "category3"
    },
    {
        itemName = "Demonic Rune",
        itemID = 12662,
        iconPath = "Interface\\Icons\\INV_Misc_Rune_04",
        requiredCount = 10,
        -- buffName not specified = instant effect item (no buff to track)
        description = "Restores 900 to 1500 mana at the cost of 600 to 1000 life.",
        category = "category3"
    },

    -- ========================================================================
    -- PROTECTION POTIONS
    -- ========================================================================
    {
        itemName = "Greater Fire Protection Potion",
        itemID = 13457,
        iconPath = "Interface\\Icons\\INV_Potion_117",
        requiredCount = 10,
        buffName = "Fire Protection",
        description = "Absorbs 1950 to 3250 fire damage. Lasts 1 hour.",
        category = "category4"
    },

    -- ========================================================================
    -- POTIONS
    -- ========================================================================
    {
        itemName = "Major Healing Potion",
        itemID = 13446,
        iconPath = "Interface\\Icons\\INV_Potion_54",
        requiredCount = 10,
        -- buffName not specified = instant effect item (no buff to track)
        description = "Restores 1050 to 1750 health.",
        category = "category5"
    }
}

-- ============================================================================
-- HELPER FUNCTION
-- Get total number of consumables defined
-- ============================================================================
function RCC_ConsumableData:GetConsumableCount()
    return table.getn(self.Items)
end