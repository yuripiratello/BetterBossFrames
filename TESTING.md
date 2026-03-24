# Testing Guide for Better Boss Frames

This guide helps you test the addon during development or after installation to ensure all features work correctly.

## Prerequisites for Testing

- World of Warcraft: Midnight installed
- Better Boss Frames addon installed
- Access to dungeons, raids, or boss encounters

## Quick Test Checklist

### 1. Basic Installation Test

- [ ] Addon appears in AddOns list at character selection
- [ ] No Lua errors when logging in
- [ ] Success message appears in chat: "Better Boss Frames loaded! Use Edit Mode to customize."

### 2. Edit Mode Integration Test

- [ ] Open Edit Mode (`/editmode`)
- [ ] "Better Boss Frames" title appears in the center of the screen
- [ ] Container can be selected by clicking
- [ ] Container can be dragged to reposition
- [ ] Settings icon appears when frame is selected
- [ ] Clicking settings opens configuration dialog

### 3. Edit Mode Settings Test

Test each setting:

#### Frame Width Slider
- [ ] Slider appears and is labeled "Frame Width"
- [ ] Range is 100-400
- [ ] Default value is 200
- [ ] Moving slider changes frame width immediately
- [ ] Value persists after exiting and re-entering Edit Mode

#### Frame Height Slider
- [ ] Slider appears and is labeled "Frame Height"
- [ ] Range is 40-120
- [ ] Default value is 60
- [ ] Moving slider changes frame height immediately
- [ ] Value persists after exiting and re-entering Edit Mode

#### Debuff Size Slider
- [ ] Slider appears and is labeled "Debuff Size"
- [ ] Range is 20-50
- [ ] Default value is 30
- [ ] Changes affect debuff icon size

#### Max Debuffs Slider
- [ ] Slider appears and is labeled "Max Debuffs"
- [ ] Range is 1-20
- [ ] Default value is 8
- [ ] Limits number of debuffs shown

#### Debuff Position Dropdown
- [ ] Dropdown appears and is labeled "Debuff Position"
- [ ] Options available: Left, Right, Top, Bottom
- [ ] Default is "Left"
- [ ] Each option positions debuffs correctly:
  - Left: Debuffs appear to the left of boss frame
  - Right: Debuffs appear to the right of boss frame
  - Top: Debuffs appear above boss frame
  - Bottom: Debuffs appear below boss frame

#### Debuff Growth Dropdown
- [ ] Dropdown appears and is labeled "Debuff Growth"
- [ ] Options available: Right, Left, Up, Down
- [ ] Default is "Right"
- [ ] Each option works correctly:
  - Right: Additional debuffs appear to the right
  - Left: Additional debuffs appear to the left
  - Up: Additional debuffs appear upward
  - Down: Additional debuffs appear downward

#### Show Only Player Debuffs Checkbox
- [ ] Checkbox appears and is labeled "Only Show My Debuffs"
- [ ] Default is checked (true)
- [ ] When checked: Only player's debuffs appear
- [ ] When unchecked: All debuffs appear

### 4. Layout System Test

- [ ] Create a new layout in Edit Mode
- [ ] Change settings for that layout
- [ ] Switch to a different layout
- [ ] Verify settings are different between layouts
- [ ] Switch back to first layout
- [ ] Verify original settings are restored

### 5. Boss Frame Appearance Test

Enter a dungeon or raid with boss encounters:

#### Boss 1 Frame
- [ ] Frame appears when boss1 exists
- [ ] Frame shows boss name
- [ ] Frame shows boss level/classification
- [ ] Health bar appears
- [ ] Health bar color changes based on health:
  - Green when > 50%
  - Yellow when 25-50%
  - Red when < 25%
- [ ] Health text shows current/max health
- [ ] Large numbers formatted (M for millions, K for thousands)

#### Multiple Bosses
- [ ] Frames appear for boss2, boss3, boss4, boss5 when they exist
- [ ] Frames are stacked vertically with proper spacing
- [ ] Each frame tracks its own boss independently
- [ ] Frames disappear when bosses die or despawn

### 6. Debuff Tracking Test

Apply debuffs to a boss (DoTs, curses, etc.):

- [ ] Debuff icons appear
- [ ] Icons show correct spell/ability icon
- [ ] Cooldown spiral shows time remaining
- [ ] Stack count appears for stackable debuffs
- [ ] Debuffs update in real-time as they expire
- [ ] New debuffs appear as they're applied
- [ ] Debuffs respect "Only Show My Debuffs" setting

### 7. Debuff Tooltip Test

- [ ] Hovering over a debuff shows tooltip
- [ ] Tooltip shows debuff name
- [ ] Tooltip shows duration
- [ ] Tooltip shows description
- [ ] Tooltip shows who applied it
- [ ] Tooltip disappears when mouse leaves

### 8. Boss Frame Interaction Test

- [ ] Hovering over boss frame shows boss tooltip
- [ ] Left-clicking boss frame targets that boss
- [ ] Right-clicking boss frame opens unit menu
- [ ] Frame highlights on mouseover (if implemented)

### 9. Performance Test

- [ ] No noticeable FPS drop with addon enabled
- [ ] Debuffs update smoothly (10 updates per second)
- [ ] No stuttering during combat
- [ ] Memory usage is reasonable (check with `/run print(GetAddOnMemoryUsage("BetterBossFrames"))`)

### 10. SavedVariables Test

- [ ] Make changes to settings
- [ ] Exit WoW completely
- [ ] Restart WoW
- [ ] Verify settings are preserved
- [ ] Check that `BetterBossFramesDB` exists in SavedVariables folder

## Testing Scenarios

### Scenario 1: Dungeon Boss

1. Enter a dungeon with a single boss
2. Verify one boss frame appears
3. Apply DoTs/debuffs to the boss
4. Verify debuffs appear and update
5. Kill the boss
6. Verify frame disappears after boss dies

### Scenario 2: Multi-Boss Encounter

1. Enter a raid or dungeon with multiple simultaneous bosses
2. Verify multiple frames appear (stacked vertically)
3. Apply debuffs to different bosses
4. Verify each frame tracks its own debuffs independently
5. Kill bosses one at a time
6. Verify frames disappear as bosses die

### Scenario 3: Rapid Debuff Changes

1. Use a class/spec with many short DoTs
2. Apply multiple debuffs rapidly
3. Verify all debuffs appear (up to max)
4. Verify debuffs disappear as they expire
5. Verify no visual glitches or flickering

### Scenario 4: Different Layouts

1. Create "Dungeon" layout with debuffs on left
2. Create "Raid" layout with debuffs on bottom
3. Switch between layouts during gameplay
4. Verify settings change appropriately

### Scenario 5: Edge Cases

- [ ] Test with max debuffs (20)
- [ ] Test with min frame size
- [ ] Test with max frame size
- [ ] Test repositioning during combat
- [ ] Test with other boss frame addons disabled/enabled
- [ ] Test with UI scale changes

## Common Issues and Fixes

### Issue: Frames not appearing

**Possible causes:**
- Not in a boss encounter
- Frames positioned off-screen
- Another addon hiding them

**Fix:**
1. Type `/editmode` to see frame position
2. Reset position in Edit Mode
3. Disable other boss frame addons

### Issue: Debuffs not showing

**Possible causes:**
- "Only Show My Debuffs" is enabled
- Max debuffs is set to 0 or 1
- Unit doesn't exist

**Fix:**
1. Check settings in Edit Mode
2. Verify you're actually applying debuffs
3. Toggle "Only Show My Debuffs" off

### Issue: Settings not saving

**Possible causes:**
- No write permissions
- WoW crashed before writing SavedVariables

**Fix:**
1. Check file permissions on WoW folder
2. Use `/reload` before exiting WoW
3. Check SavedVariables folder for BetterBossFrames.lua

## Debug Commands

Enable Lua errors to see any issues:
```
/console scriptErrors 1
```

Check addon memory usage:
```
/run print(GetAddOnMemoryUsage("BetterBossFrames"))
```

Force reload UI to test SavedVariables:
```
/reload
```

Open Edit Mode programmatically:
```
/run EditModeManagerFrame:Show()
```

## Reporting Bugs

When reporting bugs, include:

1. **WoW Version**: e.g., 12.0.0.12345
2. **Addon Version**: e.g., 1.0.0
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Lua error messages** (if any)
7. **Screenshots** (if relevant)
8. **Other addons installed**

## Success Criteria

The addon is working correctly if:

- ✅ All checklist items are completed
- ✅ No Lua errors occur during normal use
- ✅ Settings persist between sessions
- ✅ Debuffs track correctly in real encounters
- ✅ Performance is acceptable (no lag)
- ✅ Edit Mode integration works smoothly
- ✅ All customization options work as expected
