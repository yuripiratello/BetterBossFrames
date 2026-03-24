# Recent Updates - Preview Mode & Hide Blizzard Frames

This document details the new features added to Better Boss Frames.

## New Features

### 1. Preview Mode

**Problem Solved**: Boss frames only appear during boss encounters, making it impossible to customize them via Edit Mode without being in combat.

**Solution**: Preview Mode shows sample boss frames with fake data so you can customize anytime.

#### How It Works

**Automatic Preview**:
- When you open Edit Mode (`/editmode`), preview mode automatically activates
- 5 sample boss frames appear with realistic data and fake debuffs
- When you exit Edit Mode, preview automatically hides (unless manually enabled)

**Manual Preview**:
- `/bbf preview` - Toggle preview mode on/off
- `/bbf show` - Enable preview mode
- `/bbf hide` - Disable preview mode

#### Preview Data

The preview shows:
- 5 different sample bosses with varying health percentages
- Realistic boss names like "Training Dummy", "Test Boss Alpha", etc.
- Levels ranging from 80-83 and classifications (Boss, Elite, Rare)
- 2-5 fake debuffs per boss with:
  - Spell icons (rotated from a pool of 5 common spell types)
  - Cooldown spirals
  - Stack counts
  - Proper positioning based on your settings

#### Implementation Details

**Files Modified**:
- `BossFrames.lua`: Added preview functionality
  - `ShowPreview(auto)` - Enable preview mode
  - `HidePreview(auto)` - Disable preview mode
  - `TogglePreview()` - Toggle preview on/off
  - `UpdatePreviewFrame(frame, index)` - Update frame with fake data
  - `UpdatePreviewDebuffs(frame, index)` - Show fake debuffs
  - Modified `UpdateBossFrame()` to check for preview mode

- `Core.lua`: Added slash commands
  - `/bbf preview`, `/bbf show`, `/bbf hide`, `/bbf help`

**Data Structure**:
```lua
PREVIEW_BOSSES = {
  {name, health, maxHealth, level, classification},
  -- 5 sample bosses total
}
```

---

### 2. Hide Blizzard Boss Frames

**Problem Solved**: Default Blizzard boss frames overlap or conflict with the custom frames.

**Solution**: Added option to automatically hide Blizzard's default boss frames when using this addon.

#### How It Works

**Default Behavior**:
- Blizzard boss frames are hidden by default
- Happens automatically when the addon loads

**User Control**:
- Toggle in Edit Mode settings: "Hide Blizzard Boss Frames"
- Checkbox is checked by default
- Uncheck to show both Blizzard and custom frames (if desired)
- Changing the setting takes effect immediately

#### Implementation Details

**Files Modified**:
- `Core.lua`: Added `hideBlizzardFrames = true` to default settings

- `BossFrames.lua`: Added Blizzard frame management
  - `UpdateBlizzardFramesVisibility()` - Check setting and hide/show accordingly
  - `HideBlizzardBossFrames()` - Hide Boss1-5 TargetFrames
  - `ShowBlizzardBossFrames()` - Restore Blizzard frames

**Technical Approach**:
```lua
-- Hides all Blizzard boss frames
for i = 1, 5 do
  local bossFrame = _G["Boss" .. i .. "TargetFrame"]
  if bossFrame then
    bossFrame:UnregisterAllEvents()
    bossFrame:Hide()
    bossFrame:SetAlpha(0)
  end
end
```

**Edit Mode Integration**:
- New checkbox setting in Edit Mode dialog
- Labeled "Hide Blizzard Boss Frames"
- Description: "Hide the default Blizzard boss frames when using this addon"
- Default value: true
- Immediately updates visibility when toggled

---

## Code Changes Summary

### Core.lua
- **Lines Changed**: ~25 lines added
- **New Functions**: Slash command handler
- **New Settings**: `hideBlizzardFrames` default

### BossFrames.lua
- **Lines Changed**: ~170 lines added
- **New Functions**: 7 new functions
  1. `ShowPreview(auto)`
  2. `HidePreview(auto)`
  3. `TogglePreview()`
  4. `UpdatePreviewFrame(frame, index)`
  5. `UpdatePreviewDebuffs(frame, index)`
  6. `UpdateBlizzardFramesVisibility()`
  7. `HideBlizzardBossFrames()`
  8. `ShowBlizzardBossFrames()`

- **Modified Functions**:
  - `CreateContainer()` - Added Edit Mode hooks for auto-preview
  - `UpdateBossFrame()` - Check for preview mode
  - `InitializeBossFrames()` - Call Blizzard frame visibility update

- **New Variables**:
  - `BBF.previewMode` - Boolean tracking preview state
  - `BBF.autoPreview` - Boolean tracking if preview was auto-enabled
  - `PREVIEW_BOSSES` - Table with sample boss data

- **New Edit Mode Setting**: "Hide Blizzard Boss Frames" checkbox

### README.md
- Updated Features section
- Added Preview Mode section with usage instructions
- Added slash commands documentation
- Updated settings list
- Updated changelog

---

## User Benefits

### Preview Mode Benefits
1. **No Boss Required**: Customize frames anytime, anywhere
2. **Instant Feedback**: See changes immediately without waiting for a boss fight
3. **Full Visualization**: See exactly how debuffs will look with your settings
4. **Automatic**: Works seamlessly with Edit Mode - just open it and preview appears

### Hide Blizzard Frames Benefits
1. **Clean UI**: No duplicate boss frames cluttering the screen
2. **Full Replacement**: Truly replaces default frames, not just adds to them
3. **User Choice**: Can be toggled off if you want both sets of frames
4. **Automatic**: Works out of the box with no configuration needed

---

## Testing Recommendations

### Preview Mode Testing
1. Open Edit Mode and verify 5 boss frames appear
2. Test all customization options while in preview mode
3. Test manual commands: `/bbf show`, `/bbf hide`, `/bbf preview`
4. Verify preview hides when exiting Edit Mode
5. Test manual preview persists through Edit Mode sessions

### Hide Blizzard Frames Testing
1. Verify Blizzard frames are hidden on addon load
2. Enter a boss encounter and verify only custom frames show
3. Toggle the setting in Edit Mode
4. Verify Blizzard frames reappear when unchecked
5. Test persistence - setting should save between sessions

---

## Known Limitations

1. **Preview Icons**: Uses generic spell icons, not actual player debuffs
2. **Blizzard Frame Restoration**: Requires `/reload` to fully restore Blizzard frames after re-enabling (this is a WoW limitation)
3. **Preview in Combat**: Preview mode works in combat, but actual boss frames will override preview data when bosses exist

---

## Future Enhancements (Possible)

1. **Custom Preview Icons**: Allow users to specify which spell icons to show in preview
2. **Preview Health Animation**: Animate health bars in preview mode
3. **More Preview Options**: Different boss counts, different health percentages
4. **Preview Tooltips**: Show example tooltips on preview debuffs
5. **Smart Blizzard Frame Detection**: Better detection and handling of other boss frame addons
