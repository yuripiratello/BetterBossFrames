# Bug Fixes for Edit Mode Integration

## Issues Found and Fixed

### 1. Edit Mode Not Clickable/Selectable

**Root Causes:**
- Wrong callback signature for `onPositionChanged`
- Missing LibEditMode callbacks (enter, exit, layout)
- Integration happening too early (before EditModeManagerFrame was ready)
- GetCurrentLayout() not handling nil safely

**Fixes Applied:**

#### A. Fixed Callback Signature (BossFrames.lua)
**Before:**
```lua
local function onPositionChanged(layoutName, point, x, y)
```

**After:**
```lua
local function onPositionChanged(frame, layoutName, point, x, y)
```

The first parameter MUST be the frame itself per LibEditMode requirements.

#### B. Added Required LibEditMode Callbacks (BossFrames.lua)
Added the three "highly advised" callbacks:
- `enter` - Triggers when Edit Mode activates
- `exit` - Triggers when Edit Mode deactivates
- `layout` - Triggers on layout changes

These are essential for proper Edit Mode integration.

#### C. Delayed Integration Until PLAYER_LOGIN (BossFrames.lua)
**Before:**
```lua
-- Called immediately on ADDON_LOADED
self:IntegrateEditMode()
```

**After:**
```lua
-- Wait for PLAYER_LOGIN + 0.5 seconds
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.5, function()
        BBF:IntegrateEditMode()
        BBF:UpdateBlizzardFramesVisibility()
    end)
    self:UnregisterAllEvents()
end)
```

This ensures EditModeManagerFrame is fully initialized before we try to integrate.

#### D. Safe GetCurrentLayout (Core.lua)
**Before:**
```lua
function BBF:GetCurrentLayout()
    return EditModeManagerFrame:GetActiveLayoutInfo().layoutName or "Layout 1"
end
```

**After:**
```lua
function BBF:GetCurrentLayout()
    if EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo then
        local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
        return layoutInfo and layoutInfo.layoutName or "Layout 1"
    end
    return "Layout 1"
end
```

Now safely handles cases where Edit Mode isn't ready yet.

#### E. Improved LibEditMode Loading (BossFrames.lua)
```lua
-- Get LibEditMode from namespace or LibStub
LibEditMode = ns.LibEditMode or LibStub and LibStub:GetLibrary("LibEditMode", true)
```

Tries both namespace and LibStub methods to get the library.

#### F. Added Error Handling
All LibEditMode calls now wrapped in pcall() with error reporting:
```lua
local success, err = pcall(function()
    LibEditMode:AddFrame(container, onPositionChanged, defaultPosition, "BetterBossFrames")
end)

if not success then
    print("|cffff0000Better Boss Frames:|r Failed to register with Edit Mode:", err)
    return
end
```

#### G. Added Debug Command
New `/bbf debug` command shows:
- Container creation status
- Number of frames created
- LibEditMode load status
- EditModeManagerFrame readiness
- Container visibility and position

---

## Error Message Explained

The error you saw:
```
BetterBossFrames/Core.lua:48: attempt to index a nil value
[...]:48: in function 'GetCurrentLayout'
```

This happened because:
1. `EditModeManagerFrame:GetActiveLayoutInfo()` returned `nil`
2. We tried to access `.layoutName` on `nil`
3. This occurred because Edit Mode wasn't initialized yet

The fix ensures we check for `nil` before accessing properties.

---

## How to Apply Fixes

### Option 1: Re-copy the Addon
```bash
# Remove old version
rm -rf "/Applications/World of Warcraft/_retail_/Interface/AddOns/BetterBossFrames"

# Copy new version
cp -r /Users/yuripiratello/projects/personal/better-boss-frames "/Applications/World of Warcraft/_retail_/Interface/AddOns/BetterBossFrames"
```

### Option 2: Copy Individual Files
Only these files changed:
- `Core.lua`
- `BossFrames.lua`

Copy just these two files from the project to your AddOns folder.

---

## Testing After Fix

1. **Restart WoW** (or `/reload`)
2. Check for errors: `/console scriptErrors 1`
3. Run debug: `/bbf debug`
4. Expected output:
   ```
   Better Boss Frames Debug:
     Container: Created
     Frames created: 5
     LibEditMode: Loaded
     EditModeManagerFrame: Ready
     Container visible: No
     Container position: CENTER
   ```
5. Open Edit Mode: `/editmode`
6. **You should now see:**
   - 5 preview boss frames appear
   - "Better Boss Frames" title at the top
   - Frames should be **clickable/selectable**
   - Settings icon appears when selected
7. Try dragging the frame - it should move
8. Try clicking settings - dialog should open

---

## Known Limitations

1. **First Load**: On very first addon load, there may be a brief delay (0.5s) while waiting for Edit Mode to initialize
2. **Blizzard Frame Restoration**: Requires `/reload` to fully restore Blizzard frames if re-enabled
3. **LibEditMode Dependency**: Addon will not work without proper LibEditMode installation

---

## If Problems Persist

Run these debug commands and share output:

```lua
/run print("LibEditMode:", ns.LibEditMode and "Yes" or "No")
/run print("EditModeManagerFrame:", EditModeManagerFrame and "Yes" or "No")
/run print("GetActiveLayoutInfo:", EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo and "Yes" or "No")
/bbf debug
```

Also check:
1. All files in `libs/LibEditMode/widgets/` are present
2. `embed.xml` is in `libs/LibEditMode/`
3. No other addons conflicting with Edit Mode
4. WoW version is 12.0.0 or higher
