-- ============================================================================
-- RaidConsumableChecker_Constants.lua
-- All constants, texts, and configurable values
-- ============================================================================
RCC_Constants = {}

-- ============================================================================
-- ADDON INFO
-- ============================================================================
RCC_Constants.ADDON_NAME = "RaidConsumableChecker"
RCC_Constants.ADDON_VERSION = "2.1.0"

-- ============================================================================
-- UI DIMENSIONS
-- ============================================================================
RCC_Constants.WINDOW_WIDTH = 850 -- Default window width (auto-calculated based on items)
RCC_Constants.WINDOW_HEIGHT = 300 -- Default window height (auto-calculated based on categories)
RCC_Constants.WINDOW_MIN_WIDTH = 400 -- Minimum window width
RCC_Constants.WINDOW_PADDING = 15 -- Outer padding around window content
RCC_Constants.TITLE_HEIGHT = 30 -- Height of the title bar
RCC_Constants.CONTENT_MARGIN_LEFT = 15 -- Left margin for content area
RCC_Constants.CONTENT_MARGIN_RIGHT = -5 -- Right margin for content area
RCC_Constants.CONTENT_MARGIN_BOTTOM = 15 -- Bottom margin for content area

-- Icon and item display
RCC_Constants.ICON_SIZE = 45 -- Size of item icons (width and height)
RCC_Constants.ICON_SPACING_X = 25 -- Horizontal spacing between item icons

-- Category display
RCC_Constants.CATEGORY_HEADER_HEIGHT = 25 -- Height of category header text
RCC_Constants.CATEGORY_SPACING = 30 -- Vertical space between categories

-- Frame borders
RCC_Constants.BORDER_THICKNESS = 4 -- Thickness of item icon borders

-- ============================================================================
-- COLORS (Hex format)
-- ============================================================================
-- Frame background
RCC_Constants.BACKGROUND_COLOR = "CC000000" -- Main window background color (Black with 80% alpha)

-- Title bar
RCC_Constants.TITLE_BG_COLOR = "E61A1A1A" -- Title bar background color (Dark gray)
RCC_Constants.TITLE_TEXT_COLOR = "FFFFD100" -- Title bar text color (Gold)

-- Item status borders
RCC_Constants.BORDER_COLOR_BUFF_ACTIVE = "FF00FF00" -- Border when buff is active with >5 min remaining (Green)
RCC_Constants.BORDER_COLOR_BUFF_WARNING = "FFFF8800" -- Border when buff is active with <5 min remaining (Orange)
RCC_Constants.BORDER_COLOR_BUFF_INACTIVE = "FFFF0000" -- Border when buff is not active (Red)
RCC_Constants.BORDER_COLOR_NO_BUFF = "FF000000" -- Border for items without buff tracking, like potions (Black)

-- Text colors
RCC_Constants.TEXT_COLOR_NORMAL = "FFFFFFFF" -- Normal text color (White)
RCC_Constants.TEXT_COLOR_SUFFICIENT = "FF00FF00" -- Text color when you have enough items (Green)
RCC_Constants.TEXT_COLOR_INSUFFICIENT = "FFFF0000" -- Text color when you need more items (Red)
RCC_Constants.TEXT_COLOR_CATEGORY = "FFFFD100" -- Category header text color (Gold)
RCC_Constants.TEXT_COLOR_ADDON_NAME = "FF3FC7EB" -- Addon name color in chat messages (Light blue)
RCC_Constants.TEXT_COLOR_GOLD = "FFFFDB00" -- Highlight color for commands in chat (Gold)
RCC_Constants.TEXT_COLOR_HIGHLIGHT = "FFFFFFFF" -- Highlight color for item/category names in chat (White)
RCC_Constants.TEXT_COLOR_DESCRIPTION = "FFCCCCCC" -- Item description text color in tooltips (Gray)

-- ============================================================================
-- FONTS
-- ============================================================================
RCC_Constants.FONT_TITLE = "Fonts\\FRIZQT__.TTF" -- Font file for title text
RCC_Constants.FONT_NORMAL = "Fonts\\FRIZQT__.TTF" -- Font file for normal text
RCC_Constants.FONT_SIZE_TITLE = 14 -- Font size for window title
RCC_Constants.FONT_SIZE_CATEGORY = 13 -- Font size for category headers
RCC_Constants.FONT_SIZE_ITEM_NAME = 11 -- Font size for item names under icons
RCC_Constants.FONT_SIZE_COUNTER = 14 -- Font size for item count numbers
RCC_Constants.FONT_SIZE_BUFF_TIME = 14 -- Font size for buff time remaining display

-- ============================================================================
-- TIMERS AND PERFORMANCE
-- ============================================================================
RCC_Constants.BUFF_SCAN_INTERVAL = 2.0 -- Seconds between buff scans (only when window is open)
RCC_Constants.BUFF_UPDATE_DELAY_AFTER_USE = 0.2 -- Seconds to wait after using item before updating buffs
RCC_Constants.BUFF_WARNING_THRESHOLD = 300 -- Buff warning threshold in seconds - shows orange border

-- ============================================================================
-- TEXTS
-- ============================================================================
RCC_Constants.TEXT_WINDOW_TITLE = "Raid Consumable Checker" -- Main window title text
RCC_Constants.TEXT_COUNTER_FORMAT = "%d/%d" -- Format for item counter display: current/required (e.g., "5/10")

-- Slash Commands
RCC_Constants.SLASH_COMMANDS = {
    PRIMARY = "/rcc", -- Primary slash command
    SECONDARY = "/raidcheck", -- Alternative slash command
    TERTIARY = "/consumables" -- Third alternative slash command
}

-- Tooltips
RCC_Constants.TEXT_TOOLTIP_WEAPON_ENCHANT = "Weapon enchant" -- Tooltip text for weapon enchant status
RCC_Constants.TEXT_TOOLTIP_CLICK_TO_USE = "Click to use" -- Tooltip hint for clickable items

-- Confirmation dialog
RCC_Constants.TEXT_CONFIRM_MESSAGE = "You already have the buff '%s'. Do you want to use another %s?" -- Confirmation message when buff already active
RCC_Constants.TEXT_CONFIRM_ACCEPT = "Yes" -- Accept button text for confirmation dialog
RCC_Constants.TEXT_CONFIRM_CANCEL = "No" -- Cancel button text for confirmation dialog

-- ============================================================================
-- TEXTURES AND PATHS
-- ============================================================================
RCC_Constants.TEXTURE_ICON_BASE_PATH = "Interface\\Icons\\" -- Base path for all item icons
RCC_Constants.TEXTURE_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark" -- Fallback icon when item icon path is invalid or missing
RCC_Constants.TEXTURE_BORDER = "Interface\\Buttons\\WHITE8X8" -- Texture used for borders and backgrounds

-- ============================================================================
-- BEHAVIOR
-- ============================================================================
RCC_Constants.SHOW_ITEM_NAMES = true -- Show item names below icons

-- Special buff names
RCC_Constants.SPECIAL_BUFF_EQUIPPED_WEAPON = "EQUIPPED_WEAPON" -- Special identifier for weapon enchants like Wizard Oil

-- ============================================================================
-- DEFAULT SAVED VARIABLES
-- ============================================================================
RCC_Constants.DEFAULT_POSITION = {
    point = "CENTER", -- Anchor point for window position
    x = 0, -- X offset from anchor point
    y = 0 -- Y offset from anchor point
}

-- ============================================================================
-- Default (for new installations)
-- ============================================================================
-- Default Categories
RCC_Constants.DEFAULT_CATEGORIES = {
    {id = "category1", name = "Flasks / Oil / Food", dashes = 20},
    {id = "category2", name = "Main Elixirs", dashes = 24},
    {id = "category3", name = "Potions", dashes = 26},
    {id = "category4", name = "Buffs", dashes = 27}
}

-- Default Items
RCC_Constants.DEFAULT_ITEMS = {
    {
        itemName = "Flask of Supreme Power",
        itemID = 13512,
        iconPath = "INV_Potion_41",
        requiredCount = 1,
        buffName = "Supreme Power",
        description = "Increases damage done by magical spells and effects by up to 150 for 2 hrs. You can only have the effect of one flask at a time. This effect persists through death.",
        category = "category1",
        entryType = "consumable"
    },
    {
        itemName = "Wizard Oil",
        itemID = 20750,
        iconPath = "INV_Potion_104",
        requiredCount = 4,
        buffName = "EQUIPPED_WEAPON",
        description = "While applied to target weapon it increases spell damage by up to 24. Lasts for 30 minutes.",
        category = "category1",
        entryType = "consumable"
    },
    {
        itemName = "Runn Tum Tuber Surprise",
        itemID = 18254,
        iconPath = "INV_Misc_Food_63",
        requiredCount = 12,
        buffName = "Well Fed",
        description = "Restores 1933 health over 27 sec. Must remain seated while eating. Also increases your Intellect by 10 for 10 min.",
        category = "category1",
        entryType = "consumable"
    },
    {
        itemName = "Greater Arcane Elixir",
        itemID = 13454,
        iconPath = "INV_Potion_25",
        requiredCount = 2,
        buffName = "Greater Arcane Elixir",
        description = "Increases spell damage by up to 35 for 1 hour.",
        category = "category2",
        entryType = "consumable"
    },
    {
        itemName = "Major Healing Potion",
        itemID = 13446,
        iconPath = "INV_Potion_54",
        requiredCount = 10,
        description = "Restores 1050 to 1750 health.",
        category = "category3",
        entryType = "consumable"
    },
    {
        itemName = "Major Mana Potion",
        itemID = 13444,
        iconPath = "INV_Potion_76",
        requiredCount = 10,
        description = "Restores 1350 to 2250 mana.",
        category = "category3",
        entryType = "consumable"
    },
    {
        displayName = "Thorns",
        iconPath = "SPELL_Nature_Thorns",
        buffName = "Thorns",
        description = "Thorns sprout from the friendly target causing 18 Nature damage to attackers when hit. Lasts 10 min.",
        category = "category4",
        entryType = "buff"
    },
    {
        displayName = "Mage Intellect",
        iconPath = "SPELL_Holy_Magicalsentry",
        buffName = { "Arcane Intellect", "Arcane Brilliance" },
        description = "Increases Intellect by 31 for 30 min.",
        category = "category4",
        entryType = "buff"
    }
}