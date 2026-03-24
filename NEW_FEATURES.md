# New Features - Better Boss Frames v1.1.0

This document describes all the new features added to Better Boss Frames.

## Fixed Issues

### 1. Dropdown Labels Not Showing
**Issue**: Debuff Position and Debuff Growth dropdowns showed no text options.
**Fix**: Changed `label` to `text` in dropdown value objects to match LibEditMode's expected format.

**Before**:
```lua
{value = "left", label = "Left"}
```

**After**:
```lua
{value = "left", text = "Left"}
```

---

## New Features

### 1. Advanced Debuff Filtering

Multiple filter options to control which debuffs are displayed:

#### Debuff Filter Mode
Choose how debuffs are filtered:
- **All Debuffs**: Show all debuffs on the boss
- **Player Debuffs Only**: Show only debuffs you applied (default)
- **Dispellable Only**: Show only debuffs you can dispel

#### Debuff Type Filters
Individual toggles for each dispel type:
- **Show Curse Debuffs** (Purple border)
- **Show Disease Debuffs** (Brown border)
- **Show Magic Debuffs** (Blue border)
- **Show Poison Debuffs** (Green border)

**Color Coding**: Debuff borders are now colored by dispel type using WoW's standard DebuffTypeColor system.

**Use Case Examples**:
- **Dispel Classes**: Use "Dispellable Only" + enable only types you can dispel (e.g., Priests enable Magic, Paladins enable Poison/Disease)
- **DPS Focus**: Use "Player Debuffs Only" to track your DoTs
- **Healers**: Use "All Debuffs" to see everything affecting the boss

---

### 2. Buff Tracking System

Complete buff tracking system similar to debuffs:

#### Buff Display Options
- **Show Buffs**: Toggle buff display on/off (disabled by default)
- **Buff Size**: 20-50 pixels (default: 30)
- **Max Buffs**: 1-20 buffs (default: 8)
- **Buff Position**: Left/Right/Top/Bottom (default: Right)
- **Buff Growth**: Direction buffs stack (Right/Left/Up/Down)
- **Buff Filter**:
  - All Buffs
  - Player Buffs Only

#### Buff Appearance
- Green border (vs red for debuffs)
- Cooldown spirals
- Stack counts
- Tooltips on hover

**Use Cases**:
- **Friendly Boss Units**: Track buffs on friendly NPCs you need to protect
- **Buff Monitoring**: See important buffs affecting bosses
- **Player Buffs**: Track buffs you've applied to friendly bosses

---

### 3. Raid Marker Icons

Boss frames now display raid target icons when a boss is marked:

#### Features
- **Auto-Detection**: Automatically shows skull/cross/moon/etc. when boss is marked
- **Positioned**: Next to boss name
- **Toggleable**: Can be disabled via "Show Raid Markers" checkbox (enabled by default)

#### Raid Markers Supported
All 8 standard raid markers:
1. Star (Yellow)
2. Circle (Orange)
3. Diamond (Purple)
4. Triangle (Green)
5. Moon (White)
6. Square (Blue)
7. Cross (Red)
8. Skull (White)

**Use Cases**:
- Quick visual identification of which boss is which
- Coordinate focus targets in multi-boss encounters
- Match kill order in raid strategies

---

## Settings Organization

The Edit Mode settings dialog is now organized with dividers:

### Section 1: Frame Dimensions
- Frame Width
- Frame Height

### Section 2: Debuff Settings
- Debuff Size
- Max Debuffs
- Debuff Position
- Debuff Growth

### Section 3: Debuff Filtering
- **Debuff Filter** dropdown
- Show Curse/Disease/Magic/Poison checkboxes

### Section 4: Buff Settings
- **Show Buffs** checkbox
- Buff Size
- Max Buffs
- Buff Position
- Buff Growth
- Buff Filter

### Section 5: Display Options
- Show Raid Markers
- Hide Blizzard Boss Frames

---

## Technical Implementation

### Code Changes

**Core.lua**:
- Added 13 new default settings
- Settings for debuff filtering, buff tracking, raid markers

**BossFrames.lua**:
- New `UpdateRaidMarker()` function
- New `UpdateBuffs()` function
- Renamed `CreateDebuffFrame()` to `CreateAuraFrame()` (supports both buffs/debuffs)
- Renamed `PositionDebuffs()` to `PositionAuras()` (supports both types)
- Enhanced `UpdateDebuffs()` with advanced filtering
- New `UpdatePreviewBuffs()` for preview mode
- Added 21 new Edit Mode settings
- Added buff/debuff containers to frame creation

### API Usage

**Debuff Filtering**:
- Uses `aura.dispelName` to determine debuff type
- Uses `DebuffTypeColor` table for border coloring
- Checks `aura.sourceUnit` for player filtering

**Buff Tracking**:
- Uses `C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")`
- Similar structure to debuff tracking
- `aura.isHelpful` check

**Raid Markers**:
- Uses `GetRaidTargetIndex(unit)` to get marker index
- Uses `SetRaidTargetIconTexture(texture, index)` to display icon

---

## Preview Mode Updates

Preview mode now shows:
- **Debuffs**: 2-6 fake debuffs per boss with varied icons and cooldowns
- **Buffs**: 1-4 fake buffs per boss (when enabled)
- **Raid Markers**: Not shown in preview (only on real bosses)
- **Color Coding**: Debuffs show red borders, buffs show green borders

---

## Performance Notes

- Efficient aura iteration using C_UnitAuras API
- Early exit when max auras reached
- Only processes visible frames
- Buff tracking only active when enabled

---

## Compatibility

- **WoW Version**: 12.0.0+ (Midnight)
- **LibEditMode**: Uses Divider setting type (added in recent versions)
- **API**: Uses modern C_UnitAuras API (not legacy UnitBuff/UnitDebuff)

---

## Migration Notes

### From v1.0.0 to v1.1.0

**Automatic Migration**:
- New settings added with default values
- Existing settings preserved
- "Only Show My Debuffs" still works (sets debuffFilter to "player")

**No Action Required**:
- Settings will be merged on first load
- Default behavior unchanged (player debuffs only)

---

## Known Limitations

1. **Buff Border Colors**: All buffs use green border (no type-specific coloring since buffs don't have dispel types)
2. **Raid Markers in Preview**: Not shown in preview mode (requires real boss units)
3. **Debuff Type Filters**: Only work if debuff has a dispelName (some debuffs may not have a type)

---

## Future Enhancements (Possible)

1. **Aura Blacklist/Whitelist**: Custom lists of auras to show/hide by spell ID
2. **Aura Importance Sorting**: Priority-based ordering (player > dispellable > all)
3. **Separate Aura Containers**: Independent positioning for each debuff type
4. **Aura Tooltips Enhancement**: Show who applied the aura
5. **Boss Target Display**: Show what the boss is targeting
6. **Cast Bar**: Show boss cast bars
7. **Boss Power Bar**: Show boss mana/energy/rage

---

## Testing Checklist

- [x] Dropdown labels display correctly
- [x] Debuff filter modes work (all/player/dispellable)
- [x] Debuff type filters work (curse/disease/magic/poison)
- [x] Debuff borders colored by type
- [x] Buff display toggles on/off
- [x] Buffs show correct icons and cooldowns
- [x] Buff borders are green
- [x] Buff position/growth settings work
- [x] Raid markers display when boss is marked
- [x] Raid markers hide when setting disabled
- [x] Preview mode shows buffs when enabled
- [x] All settings save per-layout
- [x] Settings persist between sessions
- [x] No Lua errors with new features

---

## How to Use New Features

### Enable Buff Tracking
1. Open Edit Mode (`/editmode`)
2. Click on Better Boss Frames
3. Click Settings icon
4. Scroll to "Show Buffs"
5. Check the box
6. Adjust Buff Position, Size, Growth as desired

### Filter Debuffs by Type
1. Open Edit Mode settings
2. Find "Debuff Filter" dropdown
3. Select filter mode (All/Player/Dispellable)
4. Uncheck specific types to hide (Curse/Disease/Magic/Poison)

### Mark Bosses to See Icons
1. Target a boss
2. Set raid marker: `/run SetRaidTarget("target", 1)` (1-8 for different markers)
3. Or use raid marker keybinds/menu
4. Icon will appear next to boss name

---

## Command Reference

```
/bbf help      - Show all commands
/bbf preview   - Toggle preview mode
/bbf show      - Show preview frames
/bbf hide      - Hide preview frames
/bbf debug     - Show debug information
/editmode      - Open Edit Mode
```

---

## Changelog Summary

**v1.1.0** (Current)
- ✅ Fixed: Dropdown labels now display correctly
- ✨ New: Advanced debuff filtering (all/player/dispellable)
- ✨ New: Debuff type filters (curse/disease/magic/poison)
- ✨ New: Debuff border coloring by type
- ✨ New: Complete buff tracking system
- ✨ New: Buff position and growth settings
- ✨ New: Buff filtering (all/player)
- ✨ New: Raid marker icon display
- ✨ New: Settings organized with dividers
- 🎨 Enhanced: Preview mode shows buffs
- 🔧 Code: Renamed functions for clarity (CreateAuraFrame, PositionAuras)

**v1.0.0**
- Initial release
- Basic boss frames
- Player debuff tracking
- Edit Mode integration
- Preview mode
- Hide Blizzard frames option
