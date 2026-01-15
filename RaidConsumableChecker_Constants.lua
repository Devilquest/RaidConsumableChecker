-- ============================================================================
-- RaidConsumableChecker_Constants.lua
-- All constants, texts, and configurable values
-- ============================================================================

RCC_Constants = {}

-- ============================================================================
-- ADDON INFO
-- ============================================================================
RCC_Constants.ADDON_NAME = "RaidConsumableChecker" -- Internal addon identifier
RCC_Constants.ADDON_VERSION = "1.1.0" -- Current version number

-- ============================================================================
-- UI DIMENSIONS
-- ============================================================================
RCC_Constants.WINDOW_WIDTH = 850 -- Default window width (auto-calculated based on items)
RCC_Constants.WINDOW_HEIGHT = 300 -- Default window height (auto-calculated based on categories)
RCC_Constants.WINDOW_MIN_WIDTH = 350 -- Minimum window width
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
RCC_Constants.BACKGROUND_COLOR = "000000CC" -- Main window background color (Black with alpha)

-- Title bar
RCC_Constants.TITLE_BG_COLOR = "1A1A1AE6" -- Title bar background color (Dark gray)
RCC_Constants.TITLE_TEXT_COLOR = "FFD100FF" -- Title bar text color (Gold)

-- Item status borders (now based on buff status)
RCC_Constants.BORDER_COLOR_BUFF_ACTIVE = "00FF00FF" -- Border when buff is active with >5 min remaining (Green)
RCC_Constants.BORDER_COLOR_BUFF_WARNING = "FF8800FF" -- Border when buff is active with <5 min remaining (Orange)
RCC_Constants.BORDER_COLOR_BUFF_INACTIVE = "FF0000FF" -- Border when buff is not active (Red)
RCC_Constants.BORDER_COLOR_NO_BUFF = "000000FF" -- Border for items without buff tracking, like potions (Black)

-- Text colors
RCC_Constants.TEXT_COLOR_NORMAL = "FFFFFFFF" -- Normal text color (White)
RCC_Constants.TEXT_COLOR_SUFFICIENT = "00FF00FF" -- Text color when you have enough items (Green)
RCC_Constants.TEXT_COLOR_INSUFFICIENT = "FF0000FF" -- Text color when you need more items (Red)
RCC_Constants.TEXT_COLOR_CATEGORY = "FFD100FF" -- Category header text color (Gold)
RCC_Constants.TEXT_COLOR_ADDON_NAME = "FF3FC7EB" -- Addon name color in chat messages (Light blue)
RCC_Constants.TEXT_COLOR_GOLD = "FFFFDB00" -- Highlight color for commands in chat (Gold)
RCC_Constants.TEXT_COLOR_DESCRIPTION = "CCCCCCFF" -- Item description text color in tooltips (Gray)

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