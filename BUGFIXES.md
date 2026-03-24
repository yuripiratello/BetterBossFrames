# Bug Fixes - Better Boss Frames

This document describes critical bug fixes for issues found during testing.

## Version 1.3.0 - The Proper Solution: CreateUnitHealPredictionCalculator & Cast Bars

### Finally - The Official WoW 12.0.0 Solution for Health!

**After Three Versions of Fighting Secret Values, We Found The Right Way**:

In v1.2.0, we couldn't use health arithmetic (secret values).
In v1.2.1, we tried `UnitHealthPercent()` but it was also secret.
In v1.2.2, we gave up and used fixed green color.

**But there WAS a proper solution all along!**

By studying professional addons like UnhaltedUnitFrames, we discovered the official WoW 12.0.0 APIs designed specifically for handling Secret Values:

### The Solution: CreateUnitHealPredictionCalculator

**What It Does**:
- `CreateUnitHealPredictionCalculator()` creates a calculator object that can work with secret health values
- `UnitGetDetailedHealPrediction(unit, 'player', calculator)` updates it with current unit data
- The calculator's `GetCurrentHealth()` and `GetMaximumHealth()` methods return values that StatusBar widgets can use
- These values are still "secret" but can be passed to certain WoW widgets

**Implementation**:
```lua
-- Create calculator once per frame (in CreateBossFrame)
frame.healthCalculator = CreateUnitHealPredictionCalculator()

-- Update health (in UpdateBossFrame)
UnitGetDetailedHealPrediction(unit, 'player', frame.healthCalculator)
local currentHealth = frame.healthCalculator:GetCurrentHealth()
local maxHealth = frame.healthCalculator:GetMaximumHealth()

-- Pass to StatusBar (StatusBar accepts secret values)
frame.healthBar:SetMinMaxValues(0, maxHealth)
frame.healthBar:SetValue(currentHealth)
```

### Initial Error: Wrong Method Name

**Error in Production**:
```
attempt to call method 'AddControlPoint' (a nil value)
```

**Root Cause**:
- Used `AddControlPoint()` based on incorrect assumption about API
- Correct method is `AddPoint()` (discovered by examining UnhaltedUnitFrames source code)
- This is why it's crucial to study working addons when learning new APIs!

### The Solution: ColorCurve for Dynamic Health Coloring

**What It Does**:
- `C_CurveUtil.CreateColorCurve()` creates a curve that maps values to colors
- The curve can accept secret values and produce colors via `EvaluateCurrentHealthPercent()`
- This allows dynamic health bar coloring WITHOUT seeing the actual health values!

**The Fix (Wrong Method Name)**:
- Initial implementation used `AddControlPoint()` which doesn't exist
- Correct method is `AddPoint(position, color)` where position is 0-1
- Learned from studying UnhaltedUnitFrames source code

**Corrected Implementation**:
```lua
-- Create curve once per frame (in CreateBossFrame)
frame.healthColorCurve = C_CurveUtil.CreateColorCurve()
-- Use AddPoint (not AddControlPoint!)
frame.healthColorCurve:AddPoint(0, CreateColor(1, 0, 0, 1))    -- 0% = Red
frame.healthColorCurve:AddPoint(0.5, CreateColor(1, 1, 0, 1))  -- 50% = Yellow
frame.healthColorCurve:AddPoint(1, CreateColor(0, 1, 0, 1))    -- 100% = Green

-- In update, use the calculator's EvaluateCurrentHealthPercent method
UnitGetDetailedHealPrediction(unit, 'player', frame.healthCalculator)
local color = frame.healthCalculator:EvaluateCurrentHealthPercent(frame.healthColorCurve)
if color then
    frame.healthBar:SetStatusBarColor(color:GetRGBA())
end
```

**The Magic**:
- The addon never sees actual health numbers
- The calculator's `EvaluateCurrentHealthPercent()` evaluates the curve with secret values
- Health bars smoothly transition from green → yellow → red based on percentage
- Fully compliant with WoW 12.0.0 Secret Values!

### New Feature: Cast Bars

**What We Added**:
- Complete cast bar implementation for boss spell casts
- Shows spell icon, name, cast progress, and remaining time
- Different colors and behaviors:
  - Orange: Regular spell casts (filling left to right)
  - Blue: Channeled spells (filling right to left)
  - Gray overlay: Uninterruptible casts
  - Red: Failed or interrupted casts (brief display)
- Smooth progress bar animation (updates every frame)
- Fully customizable via Edit Mode

**Cast Bar Events Registered**:
- `UNIT_SPELLCAST_START` → Start regular cast
- `UNIT_SPELLCAST_STOP` → Cast completed
- `UNIT_SPELLCAST_FAILED` → Cast failed
- `UNIT_SPELLCAST_INTERRUPTED` → Cast interrupted
- `UNIT_SPELLCAST_CHANNEL_START` → Start channel
- `UNIT_SPELLCAST_CHANNEL_STOP` → Channel completed
- `UNIT_SPELLCAST_INTERRUPTIBLE` → Cast became interruptible
- `UNIT_SPELLCAST_NOT_INTERRUPTIBLE` → Cast became uninterruptible

**Cast Bar APIs Used**:
- `UnitCastingInfo(unit)` → Get regular cast data (name, texture, times, spellID, interruptible)
- `UnitChannelInfo(unit)` → Get channel data (name, texture, times, spellID, interruptible)
- `GetTime()` → Calculate progress and remaining time
- StatusBar widget for smooth visual progress

**Edit Mode Integration**:
- Show Cast Bars (checkbox)
- Cast Bar Height slider (15-30)
- Show Spell Icon (checkbox)
- Show Spell Name (checkbox)
- Show Cast Time (checkbox)

**Changed in**:
- `BossFrames.lua`:
  - Lines 111-120: Added CreateUnitHealPredictionCalculator and ColorCurve setup with correct `AddPoint()` method
  - Lines 156-226: Created complete cast bar UI structure
  - Lines 520-534: Updated UpdateBossFrame to use health calculator and ColorCurve with `EvaluateCurrentHealthPercent()`
  - Lines 874-1066: Added six cast bar functions (CastStart, CastChannel, CastStop, CastFailed, UpdateCastBar, CastInterruptible)
  - Lines 1260-1267: Registered all UNIT_SPELLCAST_* events with RegisterUnitEvent
  - Lines 1245-1262: Added UpdateCastBar calls in OnUpdate loop for smooth animation
  - Lines 1282-1341: Added cast bar event handlers in OnEvent
  - Lines 1848-1925: Added five cast bar settings to Edit Mode integration
- `Core.lua`: Lines 39-46: Added cast bar default settings
- `BetterBossFrames.toc`: Lines 3, 5: Updated description and version to 1.3.0
- `README.md`: Updated features, Edit Mode settings, changelog
- `BUGFIXES.md`: This section!

**Result**:
- ✅ Health bars now dynamically color from green → yellow → red using ColorCurve
- ✅ Fully compliant with WoW 12.0.0 Secret Values system
- ✅ Uses official Blizzard-provided APIs (CreateUnitHealPredictionCalculator, ColorCurve, EvaluateCurrentHealthPercent)
- ✅ Cast bars show all boss spell casts with full customization
- ✅ Smooth, performant cast bar animation
- ✅ Complete Edit Mode integration for cast bars
- ✅ No more workarounds - this is the CORRECT way to handle Secret Values!
- ✅ Fixed by studying UnhaltedUnitFrames source code to learn correct API usage

**What We Learned**:
- WoW 12.0.0 provides official APIs for Secret Values - we just had to find them!
- `CreateUnitHealPredictionCalculator` is the proper solution for health tracking
- `ColorCurve` allows dynamic coloring without seeing actual values
- Studying professional addons (like UnhaltedUnitFrames) is invaluable for learning best practices
- Sometimes the solution exists, we just need to know where to look!

**Key Lesson**:
When WoW restricts something (like Secret Values), there's usually an official API designed to handle it properly. Check the Blizzard FrameXML source and study professional addons to find the right approach!

---

## Version 1.2.2 - UnitHealthPercent Is ALSO Secret!

### The Final Boss of Secret Values

**Problem Discovered in Production**:
After implementing v1.2.1 which used `UnitHealthPercent()` to avoid arithmetic on secret values, we discovered that **even `UnitHealthPercent()` returns a secret value for boss units!**

**Error Message**:
```
BetterBossFrames/BossFrames.lua:448: attempt to compare local 'healthPercent' (a secret number value tainted by 'BetterBossFrames')
```

**The Shocking Truth**:
```lua
-- v1.2.1 approach - STILL WRONG for boss units:
local healthPercent = UnitHealthPercent(unit) or 0  -- Returns SECRET for boss units!
if healthPercent > 50 then  -- ❌ ERROR: cannot compare secret value
    -- ...
end
frame.healthText:SetFormattedText("%.0f%%", healthPercent)  -- ❌ ERROR: cannot format secret
```

**What We Learned**:

While the documentation suggests `UnitHealthPercent()` returns a non-secret percentage, this is **context-dependent**:

- ✅ For player/party/raid units: Returns normal number
- ❌ For **boss units**: Returns SECRET VALUE (same restrictions as UnitHealth)

This appears to be tied to the "SecretWhenUnitIdentityRestricted" predicate mentioned in the WoW 12.0.0 API docs - boss unit health is fully protected.

**The Only Solution (v1.2.2)**:

Since ALL health-related APIs return secret values for boss units:
- `UnitHealth(unit)` → secret
- `UnitHealthMax(unit)` → secret
- `UnitHealthPercent(unit)` → secret (for bosses!)

We cannot:
- Compare health values
- Do arithmetic on health values
- Format health values for display
- Color bars based on health thresholds
- Show ANY health information

**Final Implementation**:
```lua
-- Update health - ALL health values are SECRET for boss units
local health = UnitHealth(unit)
local maxHealth = UnitHealthMax(unit)

-- ONLY thing we can do: pass secrets directly to StatusBar
frame.healthBar:SetMinMaxValues(0, maxHealth)  -- Widget accepts secrets
frame.healthBar:SetValue(health)               -- Widget accepts secrets

// Use a fixed color - cannot dynamically color based on secret health
frame.healthBar:SetStatusBarColor(0, 0.8, 0, 1)  -- Always green

// Hide health text - cannot display ANY health information
frame.healthText:SetText("")
```

**Changed in**:
- `UpdateBossFrame()`: Lines 435-455
  - Removed all health percent comparisons
  - Removed dynamic health bar coloring (now fixed green)
  - Removed health text display entirely
  - Added explanatory comments about Secret Values

**What Still Works**:
- ✅ Health bar fills correctly (StatusBar widget accepts secret values)
- ✅ Boss names display
- ✅ Debuffs/buffs display
- ✅ Raid markers display
- ✅ **Preview mode** still shows full health info (uses local table data, not API)

**What We Lost**:
- ❌ Cannot show health numbers or percentages for boss units
- ❌ Cannot dynamically color health bar (red/yellow/green)
- ❌ Health bar is always green

**Alternative Approach (Not Implemented)**:

We COULD use `C_CurveUtil.CreateColorCurve()` to map health values to colors without seeing them:

```lua
-- One-time setup:
local colorCurve = C_CurveUtil.CreateColorCurve()
-- Configure green→red gradient for 100%→0%

-- In update:
local health = UnitHealth(unit)
local maxHealth = UnitHealthMax(unit)
-- ColorCurve can operate on secrets and set bar color
-- But this is complex and only solves coloring, not text display
```

For now, we chose simplicity: fixed color and no text.

**WoW 12.0.0 Design Philosophy**:

This restriction is intentional. From the API changes:

> "Addons should NOT provide competitive advantage in combat. Any time an addon can 'solve' encounter mechanics or calculate optimal rotations, it creates an unfair gap."

Knowing exact boss health allows:
- Burn phase timing calculations
- DPS requirement verification
- Precise execute timing

Blizzard wants players to make decisions based on the visual health bar, not addon calculations.

**Result**:
- ✅ No more secret value errors
- ✅ Addon works stably with boss units
- ⚠️ Limited boss health information (by design)
- ✅ Preview mode unchanged (still shows full info for testing)

**Key Lesson**:
**NEVER assume ANY API returns non-secret values for boss units.** Always test in actual combat. Secret Values behavior is context and unit-type dependent.

---

## Version 1.2.1 - Secret Values Arithmetic Fix & Performance

### Critical Issue: Arithmetic on Secret Health Values

**Problem Discovered During Code Review**:
While version 1.2.0 fixed the immediate taint errors, the code was still violating WoW 12.0.0 Secret Values rules by performing arithmetic operations on secret values.

**Error That Would Occur**:
```
BetterBossFrames/BossFrames.lua:426: attempt to perform arithmetic on local 'health' (a secret number value)
```

**Root Cause**:
- `UnitHealth()` and `UnitHealthMax()` return **secret values** in WoW 12.0.0
- Version 1.2.0 attempted to fix this by checking `if maxHealth and health and maxHealth > 0` before arithmetic
- However, this is STILL WRONG because:
  1. You cannot compare secret values (`maxHealth > 0` is illegal)
  2. You cannot do arithmetic on secret values (`health / maxHealth * 100` is illegal)
  3. You cannot format secret values (`health / 1000000` is illegal)

**The Correct Solution (v1.2.1)**:

According to WoW 12.0.0 Secret Values system documentation:

> "What Tainted Code CANNOT Do With Secrets:
> - **Arithmetic** (`secret + 1`, `secret * 2`): immediate Lua error.
> - **Compare** or perform **boolean tests** (`if secret then`, `secret == x`): immediate Lua error."

**Fix Implementation**:
```lua
-- ❌ WRONG (v1.2.0 approach - still violates Secret Values):
local health = UnitHealth(unit) or 0
local maxHealth = UnitHealthMax(unit) or 1
local healthPercent = health / maxHealth * 100  -- ERROR!
frame.healthText:SetFormattedText("%.1fM", health / 1000000)  -- ERROR!

-- ✅ CORRECT (v1.2.1 approach - fully compliant):
local health = UnitHealth(unit)
local maxHealth = UnitHealthMax(unit)

-- Pass secrets directly to StatusBar (widgets accept secret values)
frame.healthBar:SetMinMaxValues(0, maxHealth)
frame.healthBar:SetValue(health)

-- Use UnitHealthPercent for logic (returns non-secret percentage)
local healthPercent = UnitHealthPercent(unit) or 0
if healthPercent > 50 then
    frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
end

-- Show percentage only (no arithmetic on secrets)
frame.healthText:SetFormattedText("%.0f%%", healthPercent)
```

**Key API Used**:
- `UnitHealthPercent(unit)` - Returns health as a **non-secret** percentage (0-100)
- This API was specifically added in 12.0.0 to allow threshold checks without secret arithmetic

**Changed in**:
- `UpdateBossFrame()`: Lines 419-447 - Completely rewrote health calculation logic
  - Removed all arithmetic on health/maxHealth
  - Now uses `UnitHealthPercent()` for all logic
  - Health text displays percentage instead of numeric values
  - StatusBar receives secret values directly

**Additional Performance Improvements in v1.2.1**:

1. **Global Function Caching**:
```lua
-- Cache frequently-used globals at module top
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitHealthPercent = UnitHealthPercent
local UnitName = UnitName
local InCombatLockdown = InCombatLockdown
-- ... etc
```
- Reduces global table lookups in hot paths
- Recommended WoW addon best practice

2. **Efficient Event Registration**:
```lua
-- ❌ Old approach - fires for ALL units, filters in Lua:
updateFrame:RegisterEvent("UNIT_HEALTH")
-- Then in handler: if unit ~= "boss1" then return end

-- ✅ New approach - filters at C level (much faster):
updateFrame:RegisterUnitEvent("UNIT_HEALTH", "boss1", "boss2", "boss3", "boss4", "boss5")
-- Event only fires for boss units, no Lua filtering needed
```
- Uses `RegisterUnitEvent()` instead of `RegisterEvent()` for unit-specific events
- Filtering happens at C level instead of Lua level (significantly more efficient)
- Applied to: UNIT_HEALTH, UNIT_MAXHEALTH, UNIT_AURA

**Result**:
- ✅ Fully compliant with WoW 12.0.0 Secret Values system
- ✅ No arithmetic or comparisons on secret values
- ✅ Uses official `UnitHealthPercent()` API for logic
- ✅ Better performance with cached globals
- ✅ More efficient event handling with RegisterUnitEvent
- ✅ Health text shows percentage (can't show raw numbers due to secrets)

**Reference**:
- [WoW 12.0.0 Secret Values Documentation](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes#Secret_Values)
- WoW Addon Best Practices (internal .claude/agents/wow-addon.agent.md)

---

## Version 1.2.0 - Combat Taint & Secret Values Fix

### Multiple Combat Taint Errors (WoW 12.0.0 Secret Values)

WoW Patch 12.0.0 introduced "Secret Values" - a restriction mechanism that prevents addons from accessing certain data during combat. Even after fixing player aura filtering in v1.1.2, we encountered three more taint issues when actually fighting bosses:

#### Error 1: dispelName is a secret string value

**Error Message**:
```
BetterBossFrames/BossFrames.lua:530: attempt to compare field 'dispelName' (a secret string value tainted by 'BetterBossFrames')
```

**Root Cause**:
- The `dispelName` field becomes protected during combat
- We were checking it to filter by dispel type (Curse, Disease, Magic, Poison) and to color borders
- Any comparison with `dispelName` during combat causes taint

**The Solution**:
```lua
-- Skip dispel filtering during combat
if InCombatLockdown() then
    return true  -- Show all auras during combat
end

-- Only check dispelName outside of combat
if aura.dispelName then
    -- Safe to check here
end

-- For border coloring
if not InCombatLockdown() and aura.dispelName then
    -- Color by dispel type (only outside combat)
else
    -- Default red border during combat
end
```

#### Error 2: maxHealth is a secret number value

**Error Message**:
```
BetterBossFrames/BossFrames.lua:412: attempt to compare local 'maxHealth' (a secret number value tainted by 'BetterBossFrames')
```

**Root Cause**:
- `UnitHealthMax()` returns tainted values for boss units during combat
- Comparing tainted numbers (`maxHealth > 0`) causes errors
- Division with tainted values also spreads taint

**The Solution**:
```lua
-- Safely handle potentially tainted/nil health values
local health = UnitHealth(unit) or 0
local maxHealth = UnitHealthMax(unit) or 1

-- Safely calculate without direct comparison of possibly tainted values
local healthPercent = 0
if maxHealth and health and maxHealth > 0 then
    healthPercent = health / maxHealth * 100
end

frame.healthBar:SetMinMaxValues(0, maxHealth or 1)
frame.healthBar:SetValue(health or 0)
```

#### Error 3: ADDON_ACTION_BLOCKED - Can't call Hide() during combat

**Error Message**:
```
[ADDON_ACTION_BLOCKED] AddOn 'BetterBossFrames' tried to call the protected function 'BetterBossFrame1:Hide()'.
```

**Root Cause**:
- Once a frame or its children become tainted, you can't call protected functions like `Hide()` or `Show()` on them during combat
- Taint from accessing protected aura fields spread to the frames themselves
- Any `frame:Hide()` or `frame:Show()` call during combat triggers ADDON_ACTION_BLOCKED

**The Solution**:
```lua
-- Check combat state before calling Hide/Show
if not UnitExists(unit) then
    if InCombatLockdown() then
        frame:SetAlpha(0)  -- Use transparency instead
    else
        frame:Hide()  -- Safe outside combat
    end
    return
end

-- Same for showing frames
if InCombatLockdown() then
    frame:SetAlpha(1)
else
    frame:Show()
end
```

**Comprehensive Fix Applied to**:
- Main boss frames (Show/Hide)
- Debuff frames (Show/Hide)
- Buff frames (Show/Hide)
- Cooldown frames (Show/Hide)
- Stack count text (Show/Hide)

**Changed in**:
- `UpdateBossFrame()`: Lines 398-420 - Combat-safe Show/Hide and health calculations
- `UpdateDebuffs()`:
  - Lines 520-527 - Combat-safe clearing of debuffs
  - Lines 525-545 - Skip dispel filtering during combat
  - Lines 585-629 - Combat-safe border coloring and Show/Hide
- `UpdateBuffs()`:
  - Lines 672-679 - Combat-safe clearing of buffs
  - Lines 711-747 - Combat-safe Show/Hide for all buff elements

**Result**:
- ✅ No more dispelName taint errors during combat
- ✅ No more health calculation taint errors
- ✅ No more ADDON_ACTION_BLOCKED errors
- ✅ Frames work correctly in and out of combat
- ✅ Dispel type coloring works outside combat, defaults to red during combat
- ✅ All filtering options work as expected

**Key Lessons**:
1. **Secret Values are Everywhere**: In combat, many aura fields become "secret" (dispelName, health values, etc.)
2. **Never Call Hide/Show on Tainted Frames in Combat**: Use SetAlpha(0/1) instead
3. **Check InCombatLockdown() Before Protected Operations**: Always guard Hide/Show calls
4. **Graceful Degradation**: Disable advanced filtering during combat to keep the addon working

**Reference**: [WoW 12.0.0 API Changes - Secret Values](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)

---

## Version 1.1.2 - Critical Taint Fix

### Taint Error: "isPlayerAura is a secret boolean value"

**Error Message**:
```
BetterBossFrames/BossFrames.lua:527: attempt to perform boolean test on local 'isPlayerAura' (a secret boolean value tainted by 'BetterBossFrames')
```

**Root Cause**:
- After fixing the `isHarmful`/`isHelpful` taint, we introduced a new taint by checking `aura.isFromPlayerOrPlayerPet`
- Even when assigning this protected field to a local variable, the variable becomes tainted
- ANY boolean test on a tainted variable causes an error
- The entire aura table from certain sources is protected/tainted

**The Problem**:
```lua
-- This causes taint!
local isPlayerAura = aura.isFromPlayerOrPlayerPet
if not isPlayerAura then  -- ERROR: can't test tainted variable
    return false
end
```

**The Solution**:
- Use the API's built-in PLAYER filter instead of checking aura fields after the fact
- Combine filters using the pipe character: `"HARMFUL|PLAYER"` or `"HELPFUL|PLAYER"`
- Let the WoW API do the filtering, which is taint-free
- Remove ALL checks for protected fields like `isFromPlayerOrPlayerPet` and `sourceUnit`

**Fix Implementation**:
```lua
-- Build filter dynamically based on settings
local filter = "HARMFUL"
if debuffFilter == "player" or showOnlyPlayer then
    filter = "HARMFUL|PLAYER"  -- API filters for player auras
end

-- API only returns player auras - no need to check protected fields!
local auras = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter)
```

**Changed in**:
- `UpdateDebuffs()`:
  - Lines 513-550: Removed all `isFromPlayerOrPlayerPet` and `sourceUnit` checks from ShouldShowAura
  - Lines 602-617: Build filter string and use `"HARMFUL|PLAYER"` when needed
- `UpdateBuffs()`:
  - Lines 632-649: Removed all player aura checks from ShouldShowAura
  - Lines 686-698: Build filter string and use `"HELPFUL|PLAYER"` when needed

**Result**:
- ✅ No more taint errors from protected aura fields
- ✅ Player-only filtering works correctly via API
- ✅ Cleaner code that respects WoW's security model
- ✅ More performant (API filters instead of Lua checks)

**Key Lesson**:
Never check protected aura fields in boolean logic, even through local variables. Always use API filters instead.

---

## Version 1.1.1 - Critical Bugs Fixed

### 1. Taint Error: "isHarmful is a secret boolean value"

**Error Message**:
```
BetterBossFrames/BossFrames.lua:542: attempt to perform boolean test on field 'isHarmful' (a secret boolean value tainted by 'BetterBossFrames')
```

**Root Cause**:
- WoW protects certain aura fields like `isHarmful` and `isHelpful` to prevent addons from accessing secure combat data
- We were checking `if aura.isHarmful and ...` which caused taint

**Fix**:
- Removed checks for `aura.isHarmful` and `aura.isHelpful`
- The filter parameter in `C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL")` already ensures we only get harmful/helpful auras
- No need to double-check the aura type

**Changed in**:
- `UpdateDebuffs()`: Line 542 - Changed `if aura.isHarmful and ...` to `if aura and ...`
- `UpdateBuffs()`: Line 632 - Changed `if aura.isHelpful and ...` to `if aura and ...`

**Result**: No more taint errors! ✅

---

### 2. Health Bar Overlapping Names

**Issue**:
- Boss name text was overlapping with health percentage text
- Both texts competing for the same space on the health bar

**Root Cause**:
- Name text was set with a fixed width (`SetWidth(width - 80)`)
- If the boss name was long, it would overflow into the health text area
- No word wrapping or truncation

**Fix**:
- Changed name text to use point-based anchoring instead of fixed width
- Anchored nameText from LEFT to RIGHT with -80px margin for health text
- Added `SetWordWrap(false)` to prevent wrapping
- Text now automatically truncates with "..." if too long

**Changed in**:
- `CreateBossFrame()`: Lines 101-106 - Changed from `SetWidth()` to dual `SetPoint()` anchoring
- `ResizeFrames()`: Lines 842-844 - Updated to re-anchor name text on resize

**Result**: Names and health text no longer overlap! ✅

---

### 3. Debuffs Not Showing

**Issue**:
- Player debuffs weren't appearing on boss frames
- Only happened after the taint error

**Root Cause**:
- The taint error was stopping execution before debuffs could be displayed
- Once taint was fixed, debuffs started showing again
- Secondary issue: `sourceUnit` check wasn't reliable for all player debuffs

**Fix**:
- Fixed taint error (see #1)
- Enhanced player debuff detection to check both:
  - `aura.isFromPlayerOrPlayerPet` (more reliable)
  - `aura.sourceUnit` (fallback)
- Now catches both player and pet debuffs

**Changed in**:
- `UpdateDebuffs()` ShouldShowAura function: Lines 516-527 - Enhanced player detection

**Result**: Player debuffs now show correctly! ✅

---

### 4. Buffs Showing When Disabled

**Issue**:
- Buffs were still visible even when "Show Buffs" setting was unchecked
- Happened in preview mode

**Root Cause**:
- `UpdatePreviewFrame()` was calling `UpdatePreviewBuffs()` when showBuffs was true
- But when showBuffs was changed to false, the buffs weren't being hidden in preview mode
- The check in `UpdateBossFrame()` worked, but preview mode had no corresponding cleanup

**Fix**:
- Added else clause to `UpdatePreviewFrame()` to hide buffs when showBuffs is false
- Now both real and preview modes respect the showBuffs setting

**Changed in**:
- `UpdatePreviewFrame()`: Lines 323-329 - Added buff hiding when disabled

**Result**: Buffs only show when enabled! ✅

---

## Additional Improvements

### Enhanced Player Aura Detection

**What Changed**:
- Both `UpdateDebuffs()` and `UpdateBuffs()` now use more reliable player detection
- Checks `isFromPlayerOrPlayerPet` first (WoW 12.0+ API field)
- Falls back to `sourceUnit` check if needed
- Supports both player and pet auras

**Code**:
```lua
local isPlayerAura = false
if aura.isFromPlayerOrPlayerPet ~= nil then
    isPlayerAura = aura.isFromPlayerOrPlayerPet
elseif aura.sourceUnit then
    isPlayerAura = (aura.sourceUnit == "player" or aura.sourceUnit == "pet")
end
```

**Benefit**: More reliable detection of player/pet debuffs and buffs

---

## Testing Performed

### Before Fixes:
- ❌ Taint error spam on aura updates
- ❌ Health bar and names overlapping
- ❌ Debuffs not appearing (due to taint)
- ❌ Buffs showing when toggle was off

### After Fixes:
- ✅ No taint errors
- ✅ Names and health text clearly separated
- ✅ Debuffs display correctly
- ✅ Buffs respect the toggle setting
- ✅ Preview mode works correctly
- ✅ Player detection more reliable

---

## Version Updates

### v1.3.0 (Current)
**From**: v1.2.2
**To**: v1.3.0

Files modified:
- `BossFrames.lua` - Proper Secret Values handling + cast bars
  - Implemented CreateUnitHealPredictionCalculator for health tracking
  - Added ColorCurve for dynamic health bar coloring (green → yellow → red) using `AddPoint()` and `EvaluateCurrentHealthPercent()`
  - Fixed incorrect API usage (was using `AddControlPoint()`, correct is `AddPoint()`)
  - Created complete cast bar system (UI, events, handlers, update logic)
  - Cast bars show spell icon, name, progress, and timer
  - Registered UNIT_SPELLCAST_* events for all cast bar functionality
  - Added cast bar update to OnUpdate loop for smooth animation
  - Integrated cast bars with Edit Mode (5 new settings)
  - Added global function caching for performance
  - Now uses RegisterUnitEvent for better performance
- `Core.lua` - Added cast bar default settings
  - showCastBar, castBarHeight, castBarShowIcon, castBarShowSpellName, castBarShowTime
- `BetterBossFrames.toc` - Version bump to 1.3.0, updated description
- `README.md` - Updated features, Edit Mode settings, changelog with v1.3.0
- `BUGFIXES.md` - Added comprehensive v1.3.0 documentation

### v1.2.2
**From**: v1.2.1
**To**: v1.2.2

Files modified:
- `BossFrames.lua` - UnitHealthPercent secret value fix
  - Discovered `UnitHealthPercent()` ALSO returns secret for boss units
  - Removed ALL health comparisons (all health APIs are secret for bosses)
  - Changed to fixed green health bar color
  - Removed health text display entirely
- `BetterBossFrames.toc` - Version bump to 1.2.2
- `README.md` - Updated changelog with v1.2.2
- `BUGFIXES.md` - Added comprehensive v1.2.2 documentation

### v1.2.1
**From**: v1.2.0
**To**: v1.2.1

Files modified:
- `BossFrames.lua` - Secret Values compliance and performance improvements
  - Fixed arithmetic on secret health values (CRITICAL)
  - Attempted to use `UnitHealthPercent()` for health logic (later found to be secret too)
  - Cached frequently-used global functions at module top
  - Changed to `RegisterUnitEvent()` for boss-specific events
  - Health text displays percentage instead of numeric values
- `BetterBossFrames.toc` - Version bump to 1.2.1
- `README.md` - Updated changelog with v1.2.1
- `BUGFIXES.md` - Added comprehensive v1.2.1 documentation

### v1.2.0
**From**: v1.1.2
**To**: v1.2.0

Files modified:
- `BossFrames.lua` - Complete combat taint fix for Secret Values
  - Combat-safe Show/Hide using SetAlpha
  - Skip dispel filtering during combat
  - Safer health calculations
- `BetterBossFrames.toc` - Version bump to 1.2.0
- `README.md` - Updated changelog with v1.2.0
- `BUGFIXES.md` - Added comprehensive v1.2.0 documentation

### v1.1.2
**From**: v1.1.1
**To**: v1.1.2

Files modified:
- `BossFrames.lua` - Taint fix using API filters
- `BetterBossFrames.toc` - Version bump to 1.1.2
- `README.md` - Updated changelog
- `BUGFIXES.md` - Added v1.1.2 documentation

### v1.1.1
**From**: v1.1.0
**To**: v1.1.1

Files modified:
- `BossFrames.lua` - All bug fixes
- `BetterBossFrames.toc` - Version bump

---

## Installation

To get the fixed version:

1. Run the install script:
```bash
cd /Users/yuripiratello/projects/personal/better-boss-frames
./install.sh
```

2. In WoW:
```
/reload
```

3. Verify fixes:
```
/bbf debug
/editmode
```

---

## Technical Details

### Why Aura Fields Are Tainted

WoW protects combat-related data to prevent automation. Protected aura fields include:
- `isHarmful` / `isHelpful` - Aura type
- `isFromPlayerOrPlayerPet` - Source detection
- `isStealable` - Dispel mechanics
- `isBossAura` - Boss mechanics
- `sourceUnit` - Source unit (sometimes protected)

These are marked as "secret" when accessed during combat or from non-player units. The game engine returns tainted values that cause errors if used in conditional logic.

**Important**: Even assigning a protected field to a local variable taints that variable!

### The Complete Solution

Use `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)` with combined filters:

**Aura Type Filters:**
- `"HARMFUL"` - Returns only harmful auras (debuffs)
- `"HELPFUL"` - Returns only helpful auras (buffs)

**Source Filters (can be combined with `|`):**
- `"PLAYER"` - Returns only auras from player/pet
- `"HARMFUL|PLAYER"` - Only player debuffs (v1.1.2 fix!)
- `"HELPFUL|PLAYER"` - Only player buffs (v1.1.2 fix!)

**Examples:**
```lua
-- Get all debuffs (any source)
local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL")

-- Get only PLAYER debuffs (taint-free!)
local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL|PLAYER")

-- Get only PLAYER buffs (taint-free!)
local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL|PLAYER")
```

By using API filters, we never need to check protected fields!

### Why This Matters

Taint errors can:
1. Break addon functionality
2. Spam the error log
3. Prevent other code from executing
4. Cause UI to become unresponsive

Fixing taint is critical for a stable addon.

---

## Known Remaining Issues

None! All reported bugs have been fixed.

---

## Prevention

To avoid similar issues in the future:

1. **Never check protected fields**:
   - Use API filters instead of checking aura properties
   - Avoid `isHarmful`, `isHelpful`, `isFromPlayerOrPlayerPet`, `sourceUnit`, etc.
   - **CRITICAL**: Even storing protected fields in local variables taints those variables!

2. **Use combined API filters**:
   - Use `"HARMFUL|PLAYER"` instead of checking `isFromPlayerOrPlayerPet` after the fact
   - Use `"HELPFUL|PLAYER"` for player buffs
   - Let the WoW API do the filtering - it's taint-free and more performant

3. **Test in combat**:
   - Many taint issues only appear in combat
   - Always test with actual boss encounters
   - Check error logs during combat

4. **Use nil checks**:
   - Always check `if aura then` before accessing fields
   - Prevents nil reference errors

5. **Respect WoW's security model**:
   - Don't try to work around protected fields
   - Use the intended API patterns
   - When in doubt, use API filters instead of post-processing

---

## Related Documentation

- [WoW API: C_UnitAuras](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataByIndex)
- [Taint Documentation](https://warcraft.wiki.gg/wiki/Taint)
- [Protected Functions](https://warcraft.wiki.gg/wiki/SecureStateDriver)
