# Raid Consumable Checker

A visual tracker addon for World of Warcraft Vanilla 1.12 that helps you monitor your raid consumables with real-time inventory counts and buff timers.

![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)
![WoW Version](https://img.shields.io/badge/wow-1.12.x-orange.svg)

## Features

- **🚀 NEW: In-Game Configuration**: Add, edit, and delete consumables and categories directly from a menu. No more manual file editing!
- **Visual Inventory Tracking**: See all your raid consumables in one organized window.
- **Real-Time Buff Monitoring**: Color-coded borders show buff status at a glance:
  - 🟢 **Green**: Buff active with more than 5 minutes remaining.
  - 🟠 **Orange**: Buff active with less than 5 minutes remaining (warning).
  - 🔴 **Red**: Buff not active.
  - ⚫ **Black**: Items without buff tracking (instant effect items like healing/mana potions).
- **Buff Time Display**: Shows remaining time for active buffs (e.g., "45m", "2h").
- **Item Counter**: Displays current/required count for each consumable (e.g., "5/10").
- **Click to Use**: Left-click any consumable to use it directly from the window.
- **Smart Confirmation**: Warns you before using a consumable when you already have the buff active.
- **Organized Categories**: Consumables grouped into customizable categories.
- **Dynamic UI**: The window and icons update instantly when you change your settings.
- **Weapon Enchant Tracking**: Special support for temporary weapon enchants (Wizard Oil, Rogue Poisons, Sharpening Stones, etc.).
- **Automatic Data Migration**: Automatically imports your old settings from `v1.x` upon first load.

## Installation

### Method 1: Direct Download (Recommended)

1. Click the green **`<> Code`** button at the top of this page.
2. Select **Download ZIP**.
3. Extract the ZIP file.
4. Rename the folder from `RaidConsumableChecker-main` to `RaidConsumableChecker` (if needed).
5. Move the `RaidConsumableChecker` folder to `World of Warcraft/Interface/AddOns/`.
6. Restart WoW or type `/reload` in-game.

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
            ├── Core/
            │   ├── RaidConsumableChecker_Buffs.lua
            │   ├── RaidConsumableChecker_Config.lua
            │   ├── RaidConsumableChecker_Core.lua
            │   └── RaidConsumableChecker_UI.lua
            ├── RaidConsumableChecker.toc
            └── RaidConsumableChecker_Constants.lua
```

**Common Issues:**
- ❌ `AddOns/RaidConsumableChecker-main/RaidConsumableChecker/` (too nested)
- ✅ `AddOns/RaidConsumableChecker/` (correct!)

## Usage

### Commands

- `/rcc` - Toggle the Raid Consumable Checker window.
- `/raidcheck` - Alternative command to toggle the window.
- `/consumables` - Another alternative command.

**Tip:** Create a macro with `/rcc` and drag it to your action bar for quick access!

### Interface Controls

**Window Interactions:**
- **Left Click on Item**: Use the consumable.
- **Hover over Item**: View tooltip with item details, buff status, and description.
- **Drag Title Bar**: Move the window.
- **Click X Button**: Close the window.
- **Config Button**: Open the settings menu.

**Visual Indicators:**
- **Item Border Colors**:
  - 🟢 Green = Buff active (>5 minutes remaining).
  - 🟠 Orange = Buff expiring soon (<5 minutes).
  - 🔴 Red = Buff not active.
  - ⚫ Black = No buff to track (instant effect items).
- **Item Counter** (bottom of icon): Current inventory / Required amount.
  - Green = You have enough.
  - Red = You need more.
- **Buff Timer** (center of icon): Time remaining on active buffs.

**Smart Features:**
- Automatically scans buffs every 2 seconds when window is open.
- Updates inventory counts when you loot or use items.
- Confirmation dialog prevents accidental buff overwrites.
- Question mark icon appears for missing/invalid item icons.

## Configuration

### 🚀 **NEW in v2.0: In-Game Menu**

You no longer need to edit Lua files to customize your addon! Simply click the **Config** button in the main window to open the management menu.

#### **What you can do in the menu:**
- **Manage Items**: Add new raid consumables, set their required counts, and link them to buffs.
- **Manage Categories**: Create groups like "Flasks", "Potions", or "Raid Buffs".
- **Reorder**: Use the **Up** and **Down** buttons to organize exactly how items and categories appear in your window. **Note**: Moving a category will move all items within it as a block.
- **Icon Preview**: See the icon as you type its name (e.g., `INV_Potion_77`).

---

### **Reference: Configuration Fields**

When adding or editing an item in the configuration menu, follow this guide for field necessity:

| Field | &nbsp;&nbsp;&nbsp;Necessity&nbsp;&nbsp;&nbsp; | Description |
|-------|-----------|-------------|
| **Type** | ✅ Essential | **Consumable** (standard item) vs **Buff** (class buff). Choosing *Buff* disables inventory-related fields. |
| **Item Name** | ✅ Essential | Exact name of the item in your bags. **Required for clickable use and inventory counts.** Disabled for *Buff* type. |
| **Display Name** | ❌ Optional | A custom label for the UI (falls back to Item Name or Buff Name if left empty). |
| **Buff Name(s)** | ✅ Essential | The name(s) of the buff to track. Can be one or more separated by commas (e.g., `Arcane Intellect, Arcane Brilliance`) or `EQUIPPED_WEAPON`*. **Required for buff tracking.** |
| **Required Count**| ❌ Optional | Target amount to carry. If empty or `0`, the counter is hidden. Disabled if *Type* is **Buff**. |
| **Item ID** | ❌ Optional | For reference only. Not used for logic. Disabled if *Type* is **Buff**. |
| **Icon Name** | ✅ Essential | The name of the icon (e.g., `INV_Potion_01`). Without this, you'll see a question mark icon. |
| **Description** | ❌ Optional | Extra text shown in tooltips. |

> **\* Special Keyword `EQUIPPED_WEAPON`:**
> Temporary enchants such as **Wizard Oils**, **Mana Oils**, **Sharpening Stones** and **Rogue Poisons** appear in WoW as buffs that share the name of your equipped weapon. When using this keyword, the addon will search for an active buff that matches the name of your currently equipped **Main Hand** weapon.
> - The border will turn **Green** if an enchant is found, and **Orange** if it has less than 5 minutes remaining.

### **Understanding Item Types**

In v2.0, you can toggle between **Consumable** and **Buff** at the top of the item configuration:

*   **Consumable (Default)**: Used for physical items you carry in your bags (Flasks, Potions, Food). All fields are available.
*   **Buff**: Used for tracking class buffs or auras (Arcane Intellect, Mark of the Wild, Power Word: Fortitude, etc.). 
    *   Fields like *Item Name*, *Required Count*, and *Item ID* are disabled (grayed out) as they don't apply to these entries.
    *   The inventory counter will be hidden automatically in the main UI.

> **Smart Auto-Correction**: If you save an item as a *Consumable* but leave the *Item Name* empty and the *Required Count* at 0, the addon will automatically convert it to a **Buff** to keep your UI clean.

> **Note**: To save an item, you **must** provide at least an **Item Name** or a **Buff Name**. It is also highly recommended to provide an **Icon Name** to avoid the default question mark.

### **Reference: Category Fields**

| Field | &nbsp;&nbsp;&nbsp;Necessity&nbsp;&nbsp;&nbsp; | Description |
|-------|-----------|-------------|
| **Category Name** | ✅ Essential | The display title for the section (e.g., "Main Elixirs"). |
| **Dashes** | ❌ Optional | Number of dashes `--` to show in the UI header line. Default is 20. |

---

### 🏷️ **Dynamic Naming Priority**

The addon automatically decides which label to show under the icon based on the fields you provide. The priority is as follows:

1. **Display Name**: If you fill this field, it will **always** be the one shown.
2. **Item Name**: If *Display Name* is empty, it will show the name of the item.
3. **Buff Name**: If both *Display Name* and *Item Name* are empty, it will show the name of the buff (useful for class buffs like Arcane Intellect or Power Word: Fortitude).
    - *Note: If you have multiple buffs listed (e.g., `Arcane Intellect, Arcane Brilliance`), the addon will always use the **first one** in the list as the label.*

---

### 💡 **Example Configurations**

Here are some common ways to set up items in your list:

#### **1. Standard Consumable (Tracks Item & Buff)**
*Example: Flask of Supreme Power*
- **Item Name**: `Flask of Supreme Power`
- **Display Name**: *(Optional)*
- **Buff Name**: `Supreme Power`
- **Required Count**: `1`
- **Item ID**: *(Optional)*
- **Icon Name**: `INV_Potion_41`
- **Result**: You'll see how many flasks you have. The border will be Green/Orange/Red based on the flask buff.

#### **2. Instant Item (Tracks Item only)**
*Example: Major Healing Potion*
- **Item Name**: `Major Healing Potion`
- **Display Name**: *(Optional)*
- **Buff Name**: *(Leave Empty)*
- **Required Count**: `10`
- **Item ID**: *(Optional)*
- **Icon Name**: `INV_Potion_54`
- **Result**: You'll see your potion count. The border will always be Black because there is no buff to track.

#### **3. Weapon Enchant (Oil/Stone/Poison)**
*Example: Wizard Oil*
- **Item Name**: `Wizard Oil`
- **Display Name**: *(Optional)*
- **Buff Name**: `EQUIPPED_WEAPON`
- **Required Count**: `5`
- **Item ID**: *(Optional)*
- **Icon Name**: `INV_Potion_104`
- **Result**: Tracks your oil count. The border monitors your main-hand weapon enchant.

#### **4. Class Buff (Tracks Buff only)**
*Example: Mage Intellect*
- **Item Name**: *(Leave Empty)*
- **Display Name**: `Mage Intellect`
- **Buff Name**: `Arcane Intellect, Arcane Brilliance`
- **Required Count**: *(Leave Empty)*
- **Item ID**: *(Leave Empty)*
- **Icon Name**: `SPELL_Holy_Magicalsentry`
- **Result**: Shows `Mage Intellect` as the label. Hides the item counter since no item is linked. Tracks if either the single or group Intellect buff is active.

---

### **Tips for Finding Information**

To get the most out of the addon, you'll need the correct names for icons and buffs:

- **Icon Names**: Look up items on [Wowhead](https://web.archive.org/web/20230524183438/https://www.wowhead.com/classic/). The icon name is usually listed on the item page. In v2.0, you only need the name (e.g., `INV_Potion_41`) rather than the full path.
- **Buff Names**: Must match **exactly** as they appear in your buff bar in-game. Hover over a buff to see its name. Some items give buffs with different names (e.g., "Troll's Blood Potion" gives "Regeneration").
- **Weapon Enchants**: Use the special keyword `EQUIPPED_WEAPON` in the **Buff Name** field to track Wizard Oil or similar temporary weapon enchants.

---

### **Common Configuration Mistakes**

Even with the in-game menu, small typos can prevent the addon from working correctly:

❌ **Incorrect Buff Name (Case Sensitive)**
*   `supreme power` (Wrong: lowercase)
*   `Supreme Power` (Correct: must match in-game tooltip exactly)

❌ **Missing Underscores in Icon Names**
*   `INV Potion 41` (Wrong: spaces)
*   `INV_Potion_41` (Correct: exact internal name)

❌ **Incorrect Item Name (Click-to-Use)**
*   `major healing potion` (Wrong: case mismatch)
*   `Major Healing Potion` (Correct: must match exactly as it appears in your bags)

❌ **Adding Buff Tracking to Instant Items**
*   Instant potions like Healing/Mana potions don't give a buff. If you add a **Buff Name** to them, the border will stay red. Leave the **Buff Name** field empty for instant items.

---

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

---

### **Data Migration**

If you are upgrading from a previous version (1.x), the addon will automatically migrate your data from `RaidConsumableChecker_Data.lua` (if it exists) to the new system during your first login.

- **Legacy Support**: This allows existing users to keep their custom lists without starting from scratch.
- **Saved Variables**: Once migrated, all your changes are saved in `WTF/Account/[AccountName]/SavedVariables/RaidConsumableChecker.lua`.


## Troubleshooting

**The window doesn't appear:**
- Check if the addon is enabled in the AddOns menu at character selection.
- Try `/reload` to refresh the UI.
- Verify folder structure: `Interface/AddOns/RaidConsumableChecker/`.

**Items show question mark icons:**
- This happens if the icon name is incorrect. Verify the icon name on Wowhead.
- Question marks are intentional fallbacks - the addon still works!

**Buff tracking not working:**
- Verify the **Buff Name** matches exactly as shown in-game (hover over your buff bar).
- Case-sensitive: "Supreme Power" ≠ "supreme power".
- For weapon enchants, use the special keyword: `EQUIPPED_WEAPON`.

**Item counter shows wrong amount:**
- Verify the **Item Name** matches exactly as shown in your bags (case sensitive).
- Try opening and closing your bags to trigger an update.
- Use `/reload` to force a full inventory refresh.

**Click to use doesn't work:**
- Make sure you have entered the **Exact Item Name** (case-sensitive) in the config.
- If you only want to track a buff (like Mage Intellect), leave the Item Name field empty.

**Window position resets:**
- Position is saved in `SavedVariables`.
- Exit game properly (don't Alt+F4) to ensure settings save.
- `/reload` preserves your saved position.

**Borders are always black:**
- This is the default for items without a **Buff Name** (instant effect items).
- If you expect buff tracking, verify that the **Buff Name** is entered correctly in the configuration menu.

**Confirmation dialog appears when it shouldn't:**
- This is intentional - prevents accidental buff overwrites.
- Click "Yes" to use the item anyway, or "No" to cancel.

## Requirements

- **Game Version**: World of Warcraft 1.12.x (Vanilla)
- **Dependencies**: None (standalone addon)

## Known Limitations

- Only works with WoW Vanilla 1.12.x.
- Buff names must match exactly as they appear in-game.
- Weapon enchant tracking only supports main hand.
- Window must be open for buff scanning to work (performance optimization).
- No support for multiple stacks of the same buff.

<br>

---

## Changelog

### v2.1.0
- Added Tab navigation to the configuration forms.
- Support for cycling focus between EditBoxes using the **Tab** key.
- Reverse navigation supported using **Shift + Tab**.
- Intelligent field skipping: Disabled or grayed-out fields are automatically skipped during navigation.

### v2.0.0
- In-game Configuration UI (Items & Categories).
- Support for adding/deleting items dynamically without reloading.
- Item reordering system via UI.
- Automated data migration from legacy files.
- Simplified icon paths (shorthand support).
- Visual "Config" button on main window.
- Improved database initialization and integrity checks.
- Refactored core logic for better performance and modularity.

### v1.1.0
- Implemented buff tracking support.
- Optional `requiredCount` for buff tracking without inventory requirements.
- Multi-buff support using table syntax for `buffName`.
- Optional `displayName` field for custom UI labels.
- Support for buff-only entries without associated `itemName`.
- Hierarchical display name priority: `displayName` > `itemName` > `buffName`.
- Automated hiding of inventory counters for items without `requiredCount`.
- Multi-buff variant listing in tooltips.

### v1.0.0
- Initial release.
- Visual consumable tracking with color-coded buff status.
- Real-time inventory counts.
- Buff time remaining display.
- Click to use consumables.
- Smart confirmation when buff is already active.
- Organized categories.
- Dynamic window sizing.
- Weapon enchant tracking support.
- Fallback icons for invalid paths.
- Three customizable slash commands.

<br>

---

## :heart: Donations
**Donations are always greatly appreciated. Thank you for your support!**

<a href="https://www.buymeacoffee.com/devilquest" target="_blank"><img src="https://i.imgur.com/RHHFQWs.png" alt="Buy Me A Dinosaur"></a>
