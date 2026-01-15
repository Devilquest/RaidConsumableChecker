# Raid Consumable Checker

A visual tracker addon for World of Warcraft Vanilla 1.12 that helps you monitor your raid consumables with real-time inventory counts and buff timers.

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![WoW Version](https://img.shields.io/badge/wow-1.12.x-orange.svg)

## Features

- **Visual Inventory Tracking**: See all your raid consumables in one organized window
- **Real-Time Buff Monitoring**: Color-coded borders show buff status at a glance
  - 🟢 **Green**: Buff active with more than 5 minutes remaining
  - 🟠 **Orange**: Buff active with less than 5 minutes remaining (warning)
  - 🔴 **Red**: Buff not active
  - ⚫ **Black**: Items without buff tracking (instant effect items like healing potions)
- **Buff Time Display**: Shows remaining time for active buffs (e.g., "45m", "2h")
- **Item Counter**: Displays current/required count for each consumable (e.g., "5/10")
- **Click to Use**: Left-click any consumable to use it directly from the window
- **Smart Confirmation**: Warns you before using a consumable when you already have the buff active
- **Organized Categories**: Consumables grouped into customizable categories
- **Dynamic Window Size**: Window automatically adjusts based on your consumable list
- **Weapon Enchant Tracking**: Special support for temporary weapon enchants (Wizard Oil, etc.)
- **Fallback Icons**: Missing or invalid icons automatically display a question mark

## Installation

### Method 1: Direct Download (Recommended)

1. Click the green **`<> Code`** button at the top of this page
2. Select **Download ZIP**
3. Extract the ZIP file
4. Rename the folder from `RaidConsumableChecker-main` to `RaidConsumableChecker` (if needed)
5. Move the `RaidConsumableChecker` folder to `World of Warcraft/Interface/AddOns/`
6. Restart WoW or type `/reload` in-game

### Method 2: Git Clone

Navigate to your WoW installation folder's `Interface/AddOns/` directory and run:
```bash
git clone https://github.com/Devilquest/RaidConsumableChecker.git
```

### Verification

After installation, your folder structure should look like this:
```
World of Warcraft/
└── Interface/
    └── AddOns/
        └── RaidConsumableChecker/
            ├── RaidConsumableChecker.toc
            ├── RaidConsumableChecker_Constants.lua
            ├── RaidConsumableChecker_Data.lua
            └── Core/
                ├── RaidConsumableChecker_Core.lua
                ├── RaidConsumableChecker_UI.lua
                └── RaidConsumableChecker_Buffs.lua
```

**Common Issues:**
- ❌ `AddOns/RaidConsumableChecker-main/RaidConsumableChecker/` (too nested)
- ✅ `AddOns/RaidConsumableChecker/` (correct!)

## Usage

### Commands

- `/rcc` - Toggle the Raid Consumable Checker window
- `/raidcheck` - Alternative command to toggle the window
- `/consumables` - Another alternative command

**Tip:** Create a macro with `/rcc` and drag it to your action bar for quick access!

### Interface Controls

**Window Interactions:**
- **Left Click on Item**: Use the consumable
- **Hover over Item**: View tooltip with item details, buff status, and description
- **Drag Title Bar**: Move the window
- **Click X Button**: Close the window

**Visual Indicators:**
- **Item Border Colors**:
  - 🟢 Green = Buff active (>5 minutes remaining)
  - 🟠 Orange = Buff expiring soon (<5 minutes)
  - 🔴 Red = Buff not active
  - ⚫ Black = No buff to track (instant effect items)
- **Item Counter** (bottom of icon): Current inventory / Required amount
  - Green = You have enough
  - Red = You need more
- **Buff Timer** (center of icon): Time remaining on active buffs

**Smart Features:**
- Automatically scans buffs every 2 seconds when window is open
- Updates inventory counts when you loot or use items
- Confirmation dialog prevents accidental buff overwrites
- Question mark icon appears for missing/invalid item icons

## Configuration

### Customizing Your Consumables

The addon comes with example consumables. You'll want to customize `RaidConsumableChecker_Data.lua` with your own consumable list.

This file contains two main sections:

1. **Categories** - Define how consumables are organized
2. **Consumable Items** - Your actual list of consumables

---

### Categories Configuration

Categories define how your consumables are organized into sections. Edit the `RCC_ConsumableData.Categories` table:

```lua
RCC_ConsumableData.Categories = {
    {id = "category1", name = "Flasks / Oil / Food", order = 1, dashes = 15},
    {id = "category2", name = "Main Elixirs", order = 2, dashes = 19},
    {id = "category3", name = "Situational", order = 3, dashes = 19},
    {id = "category4", name = "Protection Potions", order = 4, dashes = 15},
    {id = "category5", name = "Potions", order = 5, dashes = 21},
    {id = "other", name = "Other", order = 99, dashes = 22}
}
```

**Field Explanations:**
- **id**: Unique identifier (use `category1`, `category2`, etc., or `other` for uncategorized items)
- **name**: Display name shown in the window
- **order**: Display order (lower numbers appear first, `99` for last)
- **dashes**: Number of dashes in the category header line (adjust for visual preference)

**Note:** The `other` category is special - items without a valid category automatically go here.

---

### Consumable Items Configuration

Each consumable item is defined in the `RCC_ConsumableData.Items` table with the following structure:

```lua
{
    displayName = "Spell Damage Flask",            -- Optional (custom label in UI)
    itemName = "Flask of Supreme Power",           -- Optional (required for clickable items)
    itemID = 13512,                                -- Optional (but recommended)
    iconPath = "Interface\\Icons\\INV_Potion_41",  -- REQUIRED
    requiredCount = 1,                             -- Optional (omit for buff-only tracking)
    buffName = "Supreme Power",                    -- Optional (can also be a table)
    description = "Increases spell damage...",     -- Optional
    category = "category1"                         -- REQUIRED
}
```

#### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| **displayName** | ❌ No | Custom name to display in UI (below icon and in tooltip)<br>**Priority**: displayName > itemName > buffName<br>Useful for buff-only items where you want a custom label (e.g., "Mage Intellect" instead of "Arcane Brilliance") |
| **itemName** | ❌ No | Exact item name as it appears in-game (case-sensitive)<br>**Required if you want to click to use the item**<br>Can be omitted for buff-only tracking (e.g., buffs from other players) |
| **itemID** | ❌ No | Item ID from Wowhead (not currently used by addon, but recommended for reference) |
| **iconPath** | ✅ Yes | Game texture path for the item icon (use double backslashes `\\`) |
| **requiredCount** | ❌ No | How many of this item you should have for raiding<br>**If omitted, inventory count will not be displayed or checked**<br>Useful for tracking buffs you don't carry (like Arcane Intellect from mages) |
| **buffName** | ❌ No | Name of the buff to track (must match exact buff name in-game)<br>Can be a **single string**: `buffName = "Arcane Intellect"`<br>Or a **table of strings**: `buffName = { "Arcane Intellect", "Arcane Brilliance" }`<br>When using a table, any matching buff will be considered active<br>**Omit this for instant effect items** like healing/mana potions |
| **description** | ❌ No | Custom description text shown in tooltip |
| **category** | ✅ Yes | Category ID (must match one from Categories section) |

---

### Item Examples

#### Example 1: Flask with Buff Tracking
```lua
{
    displayName = "Spell Damage Flask",
    itemName = "Flask of Supreme Power",
    itemID = 13512,
    iconPath = "Interface\\Icons\\INV_Potion_41",
    requiredCount = 1,
    buffName = "Supreme Power",
    description = "Increases damage done by magical spells and effects by up to 150 for 2 hrs.",
    category = "category1"
}
```
- **`displayName`**: Shows "Spell Damage Flask" as the label instead of the item name
- Has buff tracking (border will be green/orange/red based on buff status)
- Description appears in tooltip
- Clicking uses the flask

#### Example 2: Weapon Enchant (Special Case)
```lua
{
    itemName = "Wizard Oil",
    itemID = 20750,
    iconPath = "Interface\\Icons\\INV_Potion_104",
    requiredCount = 4,
    buffName = "EQUIPPED_WEAPON",  -- Special keyword for weapon enchants
    description = "Increases spell damage by up to 24 for 30 min.",
    category = "category1"
}
```
- Use `buffName = "EQUIPPED_WEAPON"` for temporary weapon enchants
- Tracks whether your main hand weapon has an enchant active
- Border shows green when enchanted, red when not

#### Example 3: Instant Effect Item (No Buff)
```lua
{
    itemName = "Major Healing Potion",
    itemID = 13446,
    iconPath = "Interface\\Icons\\INV_Potion_54",
    requiredCount = 10,
    -- No buffName field - this is an instant effect item
    description = "Restores 1050 to 1751 health.",
    category = "category5"
}
```
- No `buffName` means no buff tracking
- Border will always be black
- No buff time displayed
- Still shows inventory count
- Can still be clicked to use

#### Example 4: Elixir with Buff
```lua
{
    itemName = "Greater Arcane Elixir",
    itemID = 13454,
    iconPath = "Interface\\Icons\\INV_Potion_25",
    requiredCount = 2,
    buffName = "Greater Arcane Elixir",
    description = "Increases spell damage by up to 35 for 1 hour.",
    category = "category2"
}
```
- Full buff tracking enabled
- Shows remaining buff time when active
- Warning (orange border) when less than 5 minutes remain

#### Example 5: Item with Different Buff Name
```lua
{
    itemName = "Mighty Troll's Blood Potion",
    itemID = 3826,
    iconPath = "Interface\\Icons\\INV_Potion_79",
    requiredCount = 2,
    buffName = "Regeneration",  -- Buff name is different from item name!
    description = "Regenerate 12 health every 5 sec for 1 hour.",
    category = "category2"
}
```
- **Important**: The item name is "Mighty Troll's Blood Potion" but the buff it gives is called "Regeneration"
- Always check Wowhead or hover over the buff in-game to get the correct buff name
- Many items have buff names that differ from the item name

#### Example 6: Buff-Only Tracking (Mage Intellect)
```lua
{
    displayName = "Mage Intellect",
    iconPath = "Interface\\Icons\\spell_holy_magicalsentry",
    buffName = "Arcane Intellect",
    description = "Increases Intellect by 31 for 30 min.",
    category = "category5"
}
```
- **No `itemName`**: This is a buff you receive from mages
- **No `requiredCount`**: No inventory tracking needed
- **`displayName`**: Shows "Mage Intellect" as the label
- Border shows green when you have the buff, red when you don't
- Shows remaining time when buff is active
- Cannot be clicked (no item to use)
- Perfect for tracking raid buffs from other players

#### Example 7: Druid Buffs (Mark of the Wild)
```lua
{
    displayName = "Druid Buffs",
    iconPath = "Interface\\Icons\\spell_nature_regeneration",
    buffName = { "Mark of the Wild", "Gift of the Wild" },
    description = "Increases armor and all resistances.",
    category = "category5"
}
```
- Tracks both single-target and raid-wide versions
- Custom display name for clarity
- No inventory management
- Pure buff tracking

#### Example 8: Priest Fortitude
```lua
{
    iconPath = "Interface\\Icons\\spell_holy_wordfortitude",
    buffName = { "Power Word: Fortitude", "Prayer of Fortitude" },
    description = "Increases Stamina.",
    category = "category5"
}
```
- Tracks both single-target and group versions
- **Missing `displayName`**: UI falls back to showing the first buff name ("Power Word: Fortitude")
- Shows remaining buff time
- Visual indicator when buff expires

### Finding Item Information

**Item Names:**
- Must match **exactly** as shown in your bags
- Case-sensitive
- Include any colons, apostrophes, or special characters

**Item IDs:**
- Find on [Wowhead Classic](https://www.wowhead.com/classic/)
- Look at the URL: `wowhead.com/classic/item=13512` → ID is `13512`
- Optional field (not used by addon, just for reference)

**Icon Paths:**
- Format: `Interface\\Icons\\IconName` (use double backslashes)
- Find icon names on Wowhead item pages
- Common pattern: `Interface\\Icons\\INV_Potion_XX` or `Interface\\Icons\\Spell_XX`
- If path is invalid or missing, a question mark icon will appear

**Buff Names:**
- Must match **exactly** as it appears in your buff bar tooltip
- Check by hovering over the buff icon in-game
- Case-sensitive
- **Important**: Some items have buff names that differ from the item name
  - Example: "Mighty Troll's Blood Potion" gives buff "Regeneration"
  - Always verify the buff name on [Wowhead](https://www.wowhead.com/classic/) or in-game
- Special value: `"EQUIPPED_WEAPON"` for weapon enchants

---

### Tips for Configuration

1. **Start Simple**: Begin with just a few consumables you actually use
2. **Test as You Go**: Add items one at a time and use `/reload` to test
3. **Check Buff Names**: Hover over your buffs in-game to verify exact spelling
4. **Use Comments**: Add `--` before lines to temporarily disable items while testing
5. **Copy Examples**: The included example file has working consumables you can copy
6. **Invalid Icons**: Don't worry about typos in icon paths - question marks appear automatically
7. **Category Assignment**: Put all items you're unsure about in `category = "other"`

---

### Common Configuration Mistakes

❌ **Wrong buff name:**
```lua
buffName = "supreme power"  -- Wrong: lowercase
buffName = "Supreme Power"  -- Correct: exact match
```

❌ **Missing double backslashes in icon path:**
```lua
iconPath = "Interface\Icons\INV_Potion_41"   -- Wrong: single backslash
iconPath = "Interface\\Icons\\INV_Potion_41" -- Correct: double backslash
```

❌ **Instant effect item with buffName:**
```lua
-- Major Healing Potion has no buff, don't add buffName
buffName = "Healing"  -- Wrong: healing potions don't give buffs
-- Just omit buffName completely for instant items
```

❌ **Category doesn't exist:**
```lua
category = "myCategory"  -- Wrong: not defined in Categories section
category = "category1"   -- Correct: matches a defined category
```

## Advanced Customization

For advanced users who want to modify colors, fonts, window dimensions, or other technical settings, edit `RaidConsumableChecker_Constants.lua`. This file contains detailed comments for each setting.

**Common advanced customizations:**
- Border colors for different buff states
- Text colors for inventory counts
- Font sizes and types
- Window padding and spacing
- Buff scan interval
- Warning threshold (when orange border appears)

**Warning:** Only edit `RaidConsumableChecker_Constants.lua` if you're comfortable with Lua - all settings have inline documentation.

## File Structure
```
RaidConsumableChecker/
├── RaidConsumableChecker.toc              # Addon manifest
├── RaidConsumableChecker_Constants.lua    # Advanced settings (colors, fonts, etc.)
├── RaidConsumableChecker_Data.lua         # USER CONFIG: Your consumables and categories
└── Core/                                  # Core addon files (don't modify)
    ├── RaidConsumableChecker_Core.lua     # Main initialization and events
    ├── RaidConsumableChecker_UI.lua       # Window and interface creation
    └── RaidConsumableChecker_Buffs.lua    # Buff tracking and consumable usage
```

**Files You Should Edit:**
- ✅ `RaidConsumableChecker_Data.lua` - Your consumable list and categories

**Files You Shouldn't Need to Edit:**
- ❌ `Core/` folder - Core addon functionality
- ⚠️ `RaidConsumableChecker_Constants.lua` - Only for advanced customization

## Troubleshooting

**The window doesn't appear:**
- Check if the addon is enabled in the AddOns menu at character selection
- Try `/reload` to refresh the UI
- Verify folder structure: `Interface/AddOns/RaidConsumableChecker/`
- Check for Lua errors (install an error display addon like `!ImprovedErrorFrame`)

**Items show question mark icons:**
- This is normal for invalid or missing icon paths
- Double-check your `iconPath` entries use double backslashes: `Interface\\Icons\\...`
- Verify icon names on Wowhead
- Question marks are intentional fallbacks - the addon still works

**Buff tracking not working:**
- Verify `buffName` matches exactly as shown in-game (hover over buff to check)
- Case-sensitive: "Supreme Power" ≠ "supreme power"
- For weapon enchants, use `buffName = "EQUIPPED_WEAPON"`
- Make sure the window is open (buffs only scan when window is visible)

**Item counter shows wrong amount:**
- Verify `itemName` matches exactly as shown in your bags
- Try closing/opening bags to trigger a bag update
- Use `/reload` to force a refresh

**Click to use doesn't work:**
- Items without `buffName` can't be clicked (by design)
- Verify the item exists in your bags
- Check for Lua errors that might be blocking the click handler

**Window position resets:**
- Position is saved in `SavedVariables`
- Exit game properly (don't Alt+F4) to ensure settings save
- `/reload` preserves your saved position

**Borders are always black:**
- This is correct for items without `buffName` (instant effect items)
- If you expect buff tracking, verify `buffName` is specified and correct

**Confirmation dialog appears when it shouldn't:**
- This is intentional - prevents accidental buff overwrites
- Click "Yes" to use the item anyway
- Click "No" to cancel

## Requirements

- **Game Version**: World of Warcraft 1.12.x (Vanilla)
- **Dependencies**: None (standalone addon)

## Known Limitations

- Only works with WoW Vanilla 1.12.x
- Buff names must match exactly as they appear in-game
- Weapon enchant tracking only supports main hand
- Window must be open for buff scanning to work (performance optimization)
- No support for multiple stacks of the same buff

<br>

---

## Changelog

### v1.1.0
- Implemented buff tracking support
- Optional `requiredCount` for buff tracking without inventory requirements
- Multi-buff support using table syntax for `buffName`
- Optional `displayName` field for custom UI labels
- Support for buff-only entries without associated `itemName`
- Hierarchical display name priority: `displayName` > `itemName` > `buffName`
- Automated hiding of inventory counters for items without `requiredCount`
- Multi-buff variant listing in tooltips

### v1.0.0
- Initial release
- Visual consumable tracking with color-coded buff status
- Real-time inventory counts
- Buff time remaining display
- Click to use consumables
- Smart confirmation when buff is already active
- Organized categories
- Dynamic window sizing
- Weapon enchant tracking support
- Fallback icons for invalid paths
- Three customizable slash commands

<br>

---

## :heart: Donations
**Donations are always greatly appreciated. Thank you for your support!**

<a href="https://www.buymeacoffee.com/devilquest" target="_blank"><img src="https://i.imgur.com/RHHFQWs.png" alt="Buy Me A Dinosaur"></a>
