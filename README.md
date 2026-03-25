# Better Boss Frames

A World of Warcraft addon that replaces the default boss frames with custom frames that display YOUR debuffs on each boss. Fully customizable via WoW's Edit Mode system.

## Features

- Custom boss frames for up to 5 bosses
- **Cast Bars** (NEW!):
  - Shows boss spell casts with progress bar
  - Displays spell icon, name, and remaining time
  - Orange for regular casts, blue for channeled spells
  - Gray overlay for uninterruptible casts
  - Red for failed/interrupted casts
  - Fully customizable height and visibility
- **Preview Mode**: Automatically shows sample boss frames when you open Edit Mode (or use `/bbf preview`)
- **Hide Blizzard Frames**: Option to hide default Blizzard boss frames
- **Advanced Debuff Tracking**:
  - Filter modes: All debuffs, Player debuffs only, Dispellable only
  - Filter by type: Curse, Disease, Magic, Poison
  - Color-coded borders by debuff type
  - Icons, durations, and stack counts
  - Tooltips on hover
- **Buff Tracking** (NEW!):
  - Toggle buff display on/off
  - Customizable position, size, and growth direction
  - Filter: All buffs or player buffs only
  - Perfect for friendly boss units
- **Raid Marker Icons**: Automatically shows raid target icons on marked bosses
- **Dynamic Health Coloring**: Health bars smoothly transition from green → yellow → red based on health percentage using ColorCurve
- **WoW 12.0.0 Compliant**: Properly handles Secret Values using CreateUnitHealPredictionCalculator and ColorCurve
- Fully integrated with WoW's Edit Mode for easy customization
- Customizable options:
  - Frame position (via Edit Mode drag-and-drop)
  - Frame width and height (100-400 x 40-120)
  - Debuff/Buff size (20-50)
  - Debuff/Buff position (left, right, top, or bottom)
  - Debuff/Buff growth direction (right, left, up, or down)
  - Maximum number of debuffs/buffs to display (1-20)
  - Advanced filtering options
  - Toggle to hide/show Blizzard's default boss frames
- Health bars with percentage-based coloring
- Boss name, level, and classification display
- Click to target bosses

## Requirements

- World of Warcraft: Midnight (version 12.0.0 or higher)

## Installation

### Method 1: Manual Installation

1. Download the addon folder
2. Extract to your WoW AddOns directory:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - Mac: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure the folder is named `BetterBossFrames`
4. Restart WoW or reload UI with `/reload`

### Method 2: From Source

If you're cloning from the repository, the folder structure should look like this:

```
BetterBossFrames/
├── BetterBossFrames.toc
├── Core.lua
├── BossFrames.lua
├── libs/
│   ├── LibStub/
│   │   └── LibStub.lua
│   └── LibEditMode/
│       ├── LibEditMode.lua
│       ├── namespaced.lua
│       └── embed.xml
└── README.md
```

## Usage

1. After installation, the addon will load automatically
2. You'll see a message in chat: "Better Boss Frames loaded! Type /bbf help for commands."
3. Boss frames will appear when you encounter bosses in dungeons or raids

### Preview Mode

Since boss frames only appear during boss encounters, the addon includes a **Preview Mode** to help you customize the frames without fighting bosses:

- **Automatic Preview**: When you open Edit Mode (`/editmode`), sample boss frames automatically appear
- **Manual Preview**: Use `/bbf preview` to toggle preview mode on/off
- **Commands**:
  - `/bbf show` - Show preview frames
  - `/bbf hide` - Hide preview frames
  - `/bbf preview` - Toggle preview on/off

Preview mode shows 5 sample boss frames with fake debuffs so you can see exactly how your settings will look.

### Customization via Edit Mode

1. Open Edit Mode:
   - Press `ESC` and click "Edit Mode", or
   - Type `/editmode` in chat
2. Click on the "Better Boss Frames" title (appears in Edit Mode)
3. Drag to reposition the boss frames
4. Click the settings icon to customize:
   - **Frame Width**: Adjust the width of each boss frame (100-400)
   - **Frame Height**: Adjust the height of each boss frame (40-120)
   - **Debuff Size**: Size of debuff icons (20-50)
   - **Max Debuffs**: Maximum number of debuffs to show per boss (1-20)
   - **Debuff Position**: Where debuffs appear relative to the boss frame
     - Left (default)
     - Right
     - Top
     - Bottom
   - **Debuff Growth**: Direction debuffs grow when multiple are shown
     - Right (default)
     - Left
     - Up
     - Down
   - **Only Show My Debuffs**: Toggle to show only your debuffs or all debuffs
   - **Hide Blizzard Boss Frames**: Hide the default Blizzard boss frames (enabled by default)
   - **Cast Bar Settings**:
     - **Show Cast Bars**: Toggle cast bar display on/off
     - **Cast Bar Height**: Adjust cast bar height (15-30)
     - **Show Spell Icon**: Toggle spell icon display
     - **Show Spell Name**: Toggle spell name text
     - **Show Cast Time**: Toggle remaining time display

### Layout Profiles

Better Boss Frames integrates with WoW's Edit Mode layout system. You can have different configurations for different layouts (e.g., one for dungeons, one for raids).

Each layout can have its own:
- Position
- Frame size
- Debuff configuration

Settings are automatically saved per-layout.

## Features in Detail

### Boss Frames

- Displays name, level, and classification (Boss, Elite, Rare, etc.)
- Health bar with dynamic coloring using WoW 12.0.0's ColorCurve system:
  - Green: 100% health
  - Yellow: 50% health
  - Red: 0% health
  - Smoothly transitions between colors at any health percentage
- Properly handles WoW 12.0.0 Secret Values using CreateUnitHealPredictionCalculator and ColorCurve

### Debuff Tracking

- Shows debuffs applied by you (or all debuffs if configured)
- Displays:
  - Debuff icon
  - Remaining duration (cooldown spiral)
  - Stack count (if applicable)
- Hover over debuffs to see full tooltip
- Automatically updates in real-time

### Interactions

- **Left-click**: Target the boss
- **Right-click**: Open unit menu
- **Hover**: Show tooltip with full boss information

## Commands

### Addon Commands

- `/bbf help` - Show all available commands
- `/bbf preview` - Toggle preview mode on/off
- `/bbf show` - Show preview frames
- `/bbf hide` - Hide preview frames

### WoW Commands

- `/editmode` - Open Edit Mode to customize the frames
- `/reload` - Reload the UI (useful after changing settings)

## Troubleshooting

### Boss frames not appearing

- Make sure you're in a dungeon or raid with actual bosses
- Try `/reload` to reload the UI
- Check that the addon is enabled in the AddOns menu (character select screen)

### Settings not saving

- Make sure you have write permissions to your WoW folder
- Check that `BetterBossFramesDB` is being created in your SavedVariables folder
- Try `/reload` after making changes

### LibEditMode errors

- Ensure all files in the `libs` folder are properly downloaded
- The folder structure must match exactly as shown in the Installation section

## Credits

- Created by YuriPiratello
- Uses [LibEditMode](https://github.com/p3lim-wow/LibEditMode) by p3lim for Edit Mode integration
- Uses [LibStub](https://www.wowace.com/projects/libstub) for library loading

## License

This addon is provided as-is for personal use. Feel free to modify and share!

## Support

If you encounter any issues or have suggestions, please open an issue on the GitHub repository.

## Changelog

### Version 1.3.1 (Current) - Backdrop Taint Fix
- 🐛 **CRITICAL FIX**: Fixed backdrop taint error when frames shown after combat
- 🐛 **Fixed**: Replaced BackdropTemplate with manual texture-based borders to prevent taint
- 🐛 **Fixed**: Error "attempt to perform arithmetic on local 'width' (a secret number value)"
- ✨ **Improved**: Frame borders and cast bar icon borders now use manual textures
- 🔧 **Code**: Avoids Blizzard_SharedXML/Backdrop.lua coordinate calculations on tainted dimensions

### Version 1.3.0 - Cast Bars & Proper Secret Values Handling
- ✨ **NEW**: Cast bars for boss spell casts
  - Shows spell icon, name, and remaining cast time
  - Orange bars for regular casts, blue for channeled spells
  - Gray overlay for uninterruptible casts
  - Red bars for failed/interrupted casts
  - Smooth progress bar animation updated every frame
- ✨ **NEW**: Complete Edit Mode integration for cast bars
  - Toggle cast bar visibility
  - Adjust cast bar height (15-30)
  - Toggle spell icon, spell name, and timer display
- 🎨 **PROPER FIX**: Health bars now use `CreateUnitHealPredictionCalculator()` - the official WoW 12.0.0 solution for Secret Values
- 🎨 **PROPER FIX**: Health bars now use `ColorCurve` with `EvaluateCurrentHealthPercent()` for dynamic coloring (green → yellow → red)
- 🎨 **PROPER FIX**: Cooldown spirals now use `SetCooldownFromExpirationTime()` - the new 12.0.0 API for secret values
- ✨ **NEW**: Debuff/buff cooldown spirals now display correctly on boss units (works with pandemic mechanics)
- ✨ **Improved**: Health bars smoothly transition colors based on health percentage while respecting Secret Values
- ✨ **Improved**: Removed redundant "Only Show My Debuffs" checkbox (use "Debuff Filter" dropdown instead)
- ⚡ **Performance**: Added caching for 16 frequently-used global functions
- ⚡ **Performance**: Now uses `RegisterUnitEvent()` instead of `RegisterEvent()` for better performance
- 🔧 **Fixed**: All Show()/Hide() calls now combat-aware to prevent backdrop taint errors
- 📚 **API**: Learned proper Secret Values handling from professional addons (UnhaltedUnitFrames)
- 🔧 **Code**: Complete implementation of WoW 12.0.0 best practices for Secret Values

### Version 1.2.2 - UnitHealthPercent Is Also Secret!
- 🐛 **CRITICAL FIX**: Discovered `UnitHealthPercent()` ALSO returns secret values for boss units
- 🐛 **Fixed**: Removed ALL comparisons on health-related values (all are secret for bosses)
- 🎨 **Changed**: Health bar now uses fixed green color (cannot dynamically color based on secret health)
- 🎨 **Changed**: Health text hidden (cannot display any health information for boss units)
- ⚠️ **Limitation**: WoW 12.0.0 Secret Values prevent ALL health-based logic for boss units
- 📚 **Note**: Preview mode still shows health text/colors (uses local data, not secret API values)

### Version 1.2.1 - Secret Values Compliance & Performance
- 🐛 **CRITICAL FIX**: Replaced arithmetic on secret health values with `UnitHealthPercent()`
- 🐛 **Fixed**: Health text now shows percentage instead of numeric values (avoids secret arithmetic)
- ⚡ **Performance**: Cached frequently-used global functions for better performance
- ⚡ **Performance**: Now uses `RegisterUnitEvent()` for boss-specific events (filters at C level)
- ✨ **Improved**: Fully compliant with WoW 12.0.0 Secret Values system
- 🔧 **Code**: Removed all arithmetic operations on `UnitHealth()`/`UnitHealthMax()` returns
- 🔧 **Code**: Health/maxHealth passed directly to StatusBar widgets (accepts secrets)
- 📚 **Best Practice**: Follows official WoW addon development guidelines for 12.0.0+

### Version 1.2.0 - Combat Taint Fix
- 🐛 **CRITICAL FIX**: Fixed all combat taint errors with WoW 12.0.0 "Secret Values"
- 🐛 **Fixed**: dispelName field taint during combat
- 🐛 **Fixed**: UnitHealth/UnitHealthMax taint during combat
- 🐛 **Fixed**: ADDON_ACTION_BLOCKED errors when calling Hide() during combat
- ✨ **Improved**: Uses SetAlpha() instead of Hide()/Show() during combat
- ✨ **Improved**: Skips dispel type filtering during combat to avoid taint
- ✨ **Improved**: Safer health calculations that handle nil values
- 🔧 **Code**: All Show()/Hide() calls now check InCombatLockdown()
- 📚 **Docs**: Added reference to WoW 12.0.0 Secret Values system

### Version 1.1.2
- 🐛 **CRITICAL FIX**: Fixed taint error with isFromPlayerOrPlayerPet field
- ✨ **Improved**: Now uses API filter (`HARMFUL|PLAYER`) instead of checking protected aura fields
- ✨ **Improved**: Player-only filtering now completely taint-free and more performant
- 🔧 **Code**: Removed all checks for protected fields (isFromPlayerOrPlayerPet, sourceUnit)

### Version 1.1.1
- 🐛 **CRITICAL FIX**: Fixed taint error with isHarmful/isHelpful fields causing errors in combat
- 🐛 **Fixed**: Health bar no longer overlaps with boss names
- 🐛 **Fixed**: Debuffs now display correctly (was broken by taint)
- 🐛 **Fixed**: Buffs no longer show when disabled in preview mode
- ✨ **Improved**: Name text now truncates properly instead of overlapping

### Version 1.1.0
- ✅ **Fixed**: Dropdown labels now display correctly in Edit Mode settings
- ✨ **New**: Advanced debuff filtering (all debuffs, player only, dispellable only)
- ✨ **New**: Filter debuffs by type (Curse, Disease, Magic, Poison)
- ✨ **New**: Debuff borders colored by dispel type
- ✨ **New**: Complete buff tracking system with all customization options
- ✨ **New**: Buff filtering (all buffs or player buffs only)
- ✨ **New**: Raid marker icons automatically display when bosses are marked
- 🎨 **Enhanced**: Preview mode now shows buffs when enabled
- 📝 **Improved**: Settings organized with dividers for better navigation
- 🔧 **Code**: Refactored aura handling for better performance

### Version 1.0.0
- Initial release
- Support for up to 5 boss frames
- Player debuff tracking with customizable display
- Full Edit Mode integration
- **Preview Mode**: Automatic preview when opening Edit Mode, plus manual `/bbf` commands
- **Hide Blizzard Frames**: Option to hide default Blizzard boss frames
- Customizable frame size, position, and debuff layout
- Health bars with dynamic coloring
- Click targeting and tooltips
- Per-layout configuration support
