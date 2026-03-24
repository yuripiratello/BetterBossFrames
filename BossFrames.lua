local ADDON_NAME, ns = ...
local BBF = ns.BetterBossFrames

-- LibEditMode will be retrieved when needed
local LibEditMode

-- Boss frame container
BBF.frames = {}
BBF.container = nil
BBF.previewMode = false

-- Constants
local MAX_BOSS_FRAMES = 5
local DEBUFF_UPDATE_INTERVAL = 0.1

-- Cache frequently-used globals for performance
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitHealthPercent = UnitHealthPercent
local UnitName = UnitName
local UnitExists = UnitExists
local UnitLevel = UnitLevel
local UnitClassification = UnitClassification
local InCombatLockdown = InCombatLockdown
local GetRaidTargetIndex = GetRaidTargetIndex
local CreateFrame = CreateFrame
local C_UnitAuras = C_UnitAuras
local DebuffTypeColor = DebuffTypeColor
local CopyTable = CopyTable
local wipe = wipe

-- Preview data for fake boss frames
local PREVIEW_BOSSES = {
	{name = "Training Dummy", health = 75000000, maxHealth = 100000000, level = -1, classification = "worldboss"},
	{name = "Test Boss Alpha", health = 45000000, maxHealth = 50000000, level = 83, classification = "elite"},
	{name = "Test Boss Beta", health = 15000000, maxHealth = 30000000, level = 82, classification = "elite"},
	{name = "Practice Target", health = 8000000, maxHealth = 20000000, level = 80, classification = "rare"},
	{name = "Sample Enemy", health = 12000000, maxHealth = 15000000, level = 81, classification = "elite"},
}

-- Create the main container frame
function BBF:CreateContainer()
	if self.container then return self.container end

	local container = CreateFrame("Frame", "BetterBossFramesContainer", UIParent)
	container:SetSize(300, 400)
	container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	-- Background for visibility in edit mode
	container.bg = container:CreateTexture(nil, "BACKGROUND")
	container.bg:SetAllPoints()
	container.bg:SetColorTexture(0, 0, 0, 0)

	-- Title
	container.title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	container.title:SetPoint("TOP", 0, 20)
	container.title:SetText("Better Boss Frames")
	container.title:Hide()

	-- Note: Edit Mode enter/exit hooks are now handled in IntegrateEditMode via LibEditMode callbacks

	self.container = container
	return container
end

-- Create a single boss frame
function BBF:CreateBossFrame(index)
	local container = self.container
	local frameName = "BetterBossFrame" .. index
	local frame = CreateFrame("Button", frameName, container, "SecureUnitButtonTemplate")

	-- Set unit attribute for secure functionality
	frame:SetAttribute("unit", "boss" .. index)
	frame.unit = "boss" .. index
	frame.index = index

	-- Size
	local width = self:GetSetting(nil, "width")
	local height = self:GetSetting(nil, "height")
	frame:SetSize(width, height)

	-- Background (transparent)
	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints()
	frame.bg:SetColorTexture(0, 0, 0, 0)

	-- Border (normal state)
	frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.border:SetAllPoints()
	frame.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 2,
	})
	frame.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Health bar (positioned in middle of frame)
	frame.healthBar = CreateFrame("StatusBar", nil, frame)
	frame.healthBar:SetPoint("TOPLEFT", 5, -(height * 0.25))
	frame.healthBar:SetPoint("BOTTOMRIGHT", -5, (height * 0.3))
	frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.healthBar:SetMinMaxValues(0, 100)
	frame.healthBar:SetValue(100)

	-- Health bar background
	frame.healthBar.bg = frame.healthBar:CreateTexture(nil, "BACKGROUND")
	frame.healthBar.bg:SetAllPoints()
	frame.healthBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.healthBar.bg:SetVertexColor(0.2, 0.2, 0.2, 0.5)

	-- Create health prediction calculator (WoW 12.0.0 Secret Values solution)
	frame.healthCalculator = CreateUnitHealPredictionCalculator()

	-- Create color curve for health bar (green → yellow → red based on health %)
	-- This works with secret values!
	frame.healthColorCurve = C_CurveUtil.CreateColorCurve()
	-- AddPoint(position, color) where position is 0-1
	frame.healthColorCurve:AddPoint(0, CreateColor(1, 0, 0, 1))    -- 0% = Red
	frame.healthColorCurve:AddPoint(0.5, CreateColor(1, 1, 0, 1))  -- 50% = Yellow
	frame.healthColorCurve:AddPoint(1, CreateColor(0, 1, 0, 1))    -- 100% = Green

	-- Health text
	frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.healthText:SetPoint("RIGHT", frame.healthBar, "RIGHT", -5, 0)
	frame.healthText:SetTextColor(1, 1, 1)

	-- Name text (at the very top)
	frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -3)
	frame.nameText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -3)
	frame.nameText:SetTextColor(1, 1, 1)
	frame.nameText:SetJustifyH("LEFT")
	frame.nameText:SetWordWrap(false)
	frame.nameText:SetDrawLayer("OVERLAY", 7)

	-- Level/classification text (at the bottom)
	frame.levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.levelText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7, 3)
	frame.levelText:SetTextColor(1, 0.82, 0)
	frame.levelText:SetDrawLayer("OVERLAY", 7)

	-- Raid marker icon
	frame.raidIcon = frame:CreateTexture(nil, "OVERLAY")
	frame.raidIcon:SetSize(20, 20)
	frame.raidIcon:SetPoint("LEFT", frame.nameText, "RIGHT", 5, 0)
	frame.raidIcon:Hide()

	-- Target highlight (shows when this unit is your target)
	frame.targetHighlight = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	frame.targetHighlight:SetAllPoints()
	frame.targetHighlight:SetColorTexture(1, 1, 1, 0.15)
	frame.targetHighlight:Hide()

	-- Mouseover highlight (shows when mouse is over the frame)
	frame.mouseoverHighlight = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
	frame.mouseoverHighlight:SetAllPoints()
	frame.mouseoverHighlight:SetColorTexture(1, 1, 1, 0.08)
	frame.mouseoverHighlight:Hide()

	-- Register for mouse clicks (left click = target, right click = menu)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetAttribute("type1", "target") -- Left click targets
	frame:SetAttribute("type2", "togglemenu") -- Right click opens menu

	-- Mouseover script (for mouseover macros and visual feedback)
	frame:SetScript("OnEnter", function(self)
		self.mouseoverHighlight:Show()
		-- Update border to show mouseover
		self.border:SetBackdropBorderColor(1, 1, 1, 1)
		-- Note: Don't show tooltip for boss units - causes taint with secret values
		-- The default UI already shows boss tooltips when hovering
	end)

	frame:SetScript("OnLeave", function(self)
		self.mouseoverHighlight:Hide()
		-- Restore border color
		-- Note: UnitIsUnit() may return secret boolean for boss units, use pcall
		local isTarget = false
		pcall(function() isTarget = UnitIsUnit(self.unit, "target") end)
		if isTarget then
			self.border:SetBackdropBorderColor(1, 1, 0, 1) -- Yellow for target
		else
			self.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) -- Normal
		end
		GameTooltip:Hide()
	end)

	-- Debuff container
	frame.debuffs = {}
	frame.debuffFrame = CreateFrame("Frame", nil, frame)
	frame.debuffFrame:SetSize(1, 1) -- Will be resized dynamically

	-- Buff container
	frame.buffs = {}
	frame.buffFrame = CreateFrame("Frame", nil, frame)
	frame.buffFrame:SetSize(1, 1) -- Will be resized dynamically

	-- Cast bar
	local castBarHeight = 20
	local castBarWidth = width

	-- Note: Don't use BackdropTemplate - causes taint with secret dimensions
	frame.castBarContainer = CreateFrame("Frame", nil, frame)
	frame.castBarContainer:SetSize(castBarWidth, castBarHeight)
	frame.castBarContainer:SetPoint("TOP", frame, "BOTTOM", 0, -5)

	-- Create border using textures instead of backdrop (avoids taint)
	frame.castBarContainer.bg = frame.castBarContainer:CreateTexture(nil, "BACKGROUND")
	frame.castBarContainer.bg:SetAllPoints()
	frame.castBarContainer.bg:SetColorTexture(0, 0, 0, 0.8)

	-- Start shown but invisible - never call Hide(), only use SetAlpha
	frame.castBarContainer:Show()
	frame.castBarContainer:SetAlpha(0)

	-- Cast bar StatusBar
	frame.castBar = CreateFrame("StatusBar", nil, frame.castBarContainer)
	frame.castBar:SetPoint("TOPLEFT", 1, -1)
	frame.castBar:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.castBar:SetStatusBarColor(1, 0.7, 0, 1) -- Orange
	frame.castBar:SetMinMaxValues(0, 1)
	frame.castBar:SetValue(0)

	-- Cast bar background
	frame.castBar.bg = frame.castBar:CreateTexture(nil, "BACKGROUND")
	frame.castBar.bg:SetAllPoints()
	frame.castBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.castBar.bg:SetVertexColor(0.2, 0.2, 0.2, 0.5)

	-- Not interruptible overlay
	frame.castBar.notInterruptibleOverlay = frame.castBar:CreateTexture(nil, "OVERLAY")
	frame.castBar.notInterruptibleOverlay:SetAllPoints(frame.castBar:GetStatusBarTexture())
	frame.castBar.notInterruptibleOverlay:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	frame.castBar.notInterruptibleOverlay:SetVertexColor(0.5, 0.5, 0.5, 0.7) -- Gray overlay
	frame.castBar.notInterruptibleOverlay:Hide()

	-- Cast bar icon
	frame.castBar.icon = frame.castBarContainer:CreateTexture(nil, "ARTWORK")
	frame.castBar.icon:SetSize(castBarHeight - 2, castBarHeight - 2)
	frame.castBar.icon:SetPoint("RIGHT", frame.castBarContainer, "LEFT", -2, 0)
	frame.castBar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Cast bar icon border
	frame.castBar.iconBorder = CreateFrame("Frame", nil, frame.castBarContainer, "BackdropTemplate")
	frame.castBar.iconBorder:SetPoint("TOPLEFT", frame.castBar.icon, "TOPLEFT", -1, 1)
	frame.castBar.iconBorder:SetPoint("BOTTOMRIGHT", frame.castBar.icon, "BOTTOMRIGHT", 1, -1)
	frame.castBar.iconBorder:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame.castBar.iconBorder:SetBackdropBorderColor(0, 0, 0, 1)

	-- Spell name text
	frame.castBar.text = frame.castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.castBar.text:SetPoint("LEFT", frame.castBar, "LEFT", 5, 0)
	frame.castBar.text:SetPoint("RIGHT", frame.castBar, "RIGHT", -30, 0)
	frame.castBar.text:SetJustifyH("LEFT")
	frame.castBar.text:SetWordWrap(false)
	frame.castBar.text:SetTextColor(1, 1, 1)

	-- Cast time text
	frame.castBar.time = frame.castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.castBar.time:SetPoint("RIGHT", frame.castBar, "RIGHT", -5, 0)
	frame.castBar.time:SetTextColor(1, 1, 1)

	-- Cast bar state
	frame.castBar.casting = false
	frame.castBar.channeling = false
	frame.castBar.spellID = nil

	-- Position the frame
	if index == 1 then
		frame:SetPoint("TOP", container, "TOP", 0, -30)
	else
		frame:SetPoint("TOP", self.frames[index - 1], "BOTTOM", 0, -10)
	end

	frame:Hide()

	-- Tooltip
	frame:SetScript("OnEnter", function(self)
		if UnitExists(self.unit) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetUnit(self.unit)
			GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Click actions (secure)
	frame:RegisterForClicks("AnyUp")
	frame:SetAttribute("type1", "target")
	frame:SetAttribute("type2", "togglemenu")

	return frame
end

-- Show preview mode
function BBF:ShowPreview(auto)
	if self.previewMode then
		if not auto then
			print("|cff00ff00Better Boss Frames:|r Preview mode is already active.")
		end
		return
	end

	self.previewMode = true
	self.autoPreview = auto or false

	if not auto then
		print("|cff00ff00Better Boss Frames:|r Preview mode |cff00ff00enabled|r. Type |cffffcc00/bbf hide|r to disable.")
	end

	-- Show all frames with preview data
	for i = 1, MAX_BOSS_FRAMES do
		if self.frames[i] then
			self:UpdatePreviewFrame(self.frames[i], i)
		end
	end
end

-- Hide preview mode
function BBF:HidePreview(auto)
	if not self.previewMode then
		if not auto then
			print("|cff00ff00Better Boss Frames:|r Preview mode is not active.")
		end
		return
	end

	self.previewMode = false
	self.autoPreview = false

	if not auto then
		print("|cff00ff00Better Boss Frames:|r Preview mode |cffff0000disabled|r.")
	end

	-- Hide all frames that don't have real units
	for i = 1, MAX_BOSS_FRAMES do
		if self.frames[i] and not UnitExists("boss" .. i) then
			-- Use Hide if out of combat, otherwise SetAlpha
			if InCombatLockdown() then
				self.frames[i]:SetAlpha(0)
			else
				self.frames[i]:Hide()
			end
		end
	end
end

-- Toggle preview mode
function BBF:TogglePreview()
	if self.previewMode then
		self:HidePreview()
	else
		self:ShowPreview()
	end
end

-- Update frame with preview data
function BBF:UpdatePreviewFrame(frame, index)
	local data = PREVIEW_BOSSES[index]
	if not data then return end

	-- Show frame (must call Show() out of combat to clear any previous Hide())
	if InCombatLockdown() then
		frame:SetAlpha(1)
	else
		frame:Show()
		frame:SetAlpha(1)
	end

	-- Update name
	frame.nameText:SetText(data.name)

	-- Update health
	local healthPercent = (data.health / data.maxHealth) * 100
	frame.healthBar:SetMinMaxValues(0, data.maxHealth)
	frame.healthBar:SetValue(data.health)

	-- Color health bar
	if healthPercent > 50 then
		frame.healthBar:SetStatusBarColor(0, 1, 0, 1)
	elseif healthPercent > 25 then
		frame.healthBar:SetStatusBarColor(1, 1, 0, 1)
	else
		frame.healthBar:SetStatusBarColor(1, 0, 0, 1)
	end

	-- Update health text
	if data.maxHealth > 1000000 then
		frame.healthText:SetFormattedText("%.1fM / %.1fM", data.health / 1000000, data.maxHealth / 1000000)
	elseif data.maxHealth > 1000 then
		frame.healthText:SetFormattedText("%.1fK / %.1fK", data.health / 1000, data.maxHealth / 1000)
	else
		frame.healthText:SetFormattedText("%d / %d", data.health, data.maxHealth)
	end

	-- Update level/classification
	local classificationText = ""
	if data.classification == "worldboss" then
		classificationText = "Boss"
	elseif data.classification == "rareelite" then
		classificationText = "Rare Elite"
	elseif data.classification == "elite" then
		classificationText = "Elite"
	elseif data.classification == "rare" then
		classificationText = "Rare"
	end

	if data.level == -1 then
		frame.levelText:SetText("?? " .. classificationText)
	else
		frame.levelText:SetFormattedText("%d %s", data.level, classificationText)
	end

	-- Show some preview debuffs
	self:UpdatePreviewDebuffs(frame, index)
end

-- Show preview debuffs
function BBF:UpdatePreviewDebuffs(frame, index)
	local debuffSize = self:GetSetting(nil, "debuffSize")
	local maxDebuffs = self:GetSetting(nil, "maxDebuffs")

	-- Clear existing debuffs
	for _, debuff in ipairs(frame.debuffs) do
		debuff:Hide()
	end

	-- Show some fake debuffs (2-4 depending on boss index)
	local numDebuffs = math.min(index + 1, maxDebuffs, 5)

	-- Preview icons (using common spell icons)
	local previewIcons = {
		136133, -- Holy spell icon
		136071, -- Fire spell icon
		135817, -- Frost spell icon
		136006, -- Nature spell icon
		136197, -- Shadow spell icon
	}

	for i = 1, numDebuffs do
		local debuffFrame = frame.debuffs[i]
		if not debuffFrame then
			debuffFrame = self:CreateAuraFrame(frame, i, "debuff")
			frame.debuffs[i] = debuffFrame
		end

		-- Set icon
		debuffFrame.icon:SetTexture(previewIcons[((index + i - 2) % 5) + 1])

		-- Color border red for debuffs
		debuffFrame.border:SetBackdropBorderColor(1, 0, 0, 1)

		-- Show fake cooldown
		debuffFrame.cooldown:SetCooldown(GetTime(), 30)
		debuffFrame.cooldown:Show()

		-- Show fake stack count
		if i <= 2 then
			debuffFrame.count:SetText(i * 2)
			debuffFrame.count:Show()
		else
			debuffFrame.count:Hide()
		end

		debuffFrame:Show()
	end

	-- Position debuffs
	self:PositionAuras(frame, "debuff")

	-- Show preview buffs if enabled
	if self:GetSetting(nil, "showBuffs") then
		self:UpdatePreviewBuffs(frame, index)
	else
		-- Hide all buffs if disabled
		for _, buff in ipairs(frame.buffs) do
			buff:Hide()
		end
	end
end

-- Show preview buffs
function BBF:UpdatePreviewBuffs(frame, index)
	local buffSize = self:GetSetting(nil, "buffSize")
	local maxBuffs = self:GetSetting(nil, "maxBuffs")

	-- Clear existing buffs
	for _, buff in ipairs(frame.buffs) do
		buff:Hide()
	end

	-- Show some fake buffs (1-3 depending on boss index)
	local numBuffs = math.min(index, maxBuffs, 4)

	-- Preview icons (different from debuffs)
	local previewIcons = {
		135824, -- Blessing icon
		237550, -- Shield icon
		136116, -- Haste icon
		136120, -- Power icon
	}

	for i = 1, numBuffs do
		local buffFrame = frame.buffs[i]
		if not buffFrame then
			buffFrame = self:CreateAuraFrame(frame, i, "buff")
			frame.buffs[i] = buffFrame
		end

		-- Set icon
		buffFrame.icon:SetTexture(previewIcons[((index + i - 2) % 4) + 1])

		-- Color border green for buffs
		buffFrame.border:SetBackdropBorderColor(0, 1, 0, 1)

		-- Show fake cooldown
		buffFrame.cooldown:SetCooldown(GetTime(), 45)
		buffFrame.cooldown:Show()

		-- Show fake stack count
		if i == 1 then
			buffFrame.count:SetText(5)
			buffFrame.count:Show()
		else
			buffFrame.count:Hide()
		end

		buffFrame:Show()
	end

	-- Position buffs
	self:PositionAuras(frame, "buff")
end

-- Update a boss frame
function BBF:UpdateBossFrame(frame)
	-- If in preview mode, use preview data
	if self.previewMode then
		self:UpdatePreviewFrame(frame, frame.index)
		return
	end

	local unit = frame.unit

	if not UnitExists(unit) then
		-- Can't call Hide() during combat due to taint - use SetAlpha instead
		if InCombatLockdown() then
			frame:SetAlpha(0)
		else
			frame:Hide()
		end
		return
	end

	-- Show the frame (must call Show() out of combat to clear any previous Hide())
	-- During combat, ensure frame is visible and set alpha
	if InCombatLockdown() then
		-- In combat: can't call Show(), but ensure alpha is 1
		-- If frame was hidden by preview mode, we need to show it after combat
		if not frame:IsShown() then
			-- Frame is hidden, mark it to be shown after combat
			frame.needsShow = true
		end
		frame:SetAlpha(1)
	else
		-- Out of combat: call Show() to clear any previous Hide() state
		frame:Show()
		frame:SetAlpha(1)
		frame.needsShow = nil
	end

	-- Update name
	local name = UnitName(unit)
	frame.nameText:SetText(name or "Unknown")

	-- Update health - Use 12.0.0 Secret Value-safe approach with Health Prediction Calculator
	-- This is the CORRECT way to handle secret health values in 12.0.0!

	-- Update the calculator with current unit data
	UnitGetDetailedHealPrediction(unit, 'player', frame.healthCalculator)

	-- Get health values from calculator (these work with secret values!)
	local currentHealth = frame.healthCalculator:GetCurrentHealth()
	local maxHealth = frame.healthCalculator:GetMaximumHealth()

	-- Pass to StatusBar (StatusBar accepts secret values)
	frame.healthBar:SetMinMaxValues(0, maxHealth)
	frame.healthBar:SetValue(currentHealth)

	-- Use ColorCurve to set bar color based on health percentage
	-- The calculator's EvaluateCurrentHealthPercent works with the curve and secret values!
	-- This gives us dynamic coloring (green→yellow→red) even though health is secret
	local color = frame.healthCalculator:EvaluateCurrentHealthPercent(frame.healthColorCurve)
	if color then
		frame.healthBar:SetStatusBarColor(color:GetRGBA())
	end

	-- Hide health text - still cannot display numeric health (secret values limitation)
	-- Only the StatusBar and ColorCurve can work with secret health values
	frame.healthText:SetText("")

	-- Update level/classification
	local level = UnitLevel(unit)
	local classification = UnitClassification(unit)
	local classificationText = ""

	if classification == "worldboss" then
		classificationText = "Boss"
	elseif classification == "rareelite" then
		classificationText = "Rare Elite"
	elseif classification == "elite" then
		classificationText = "Elite"
	elseif classification == "rare" then
		classificationText = "Rare"
	end

	if level == -1 then
		frame.levelText:SetText("?? " .. classificationText)
	else
		frame.levelText:SetFormattedText("%d %s", level, classificationText)
	end

	-- Update raid marker
	self:UpdateRaidMarker(frame)

	-- Update target highlight and border
	-- Note: UnitIsUnit() may return secret boolean for boss units, use pcall
	local isTarget = false
	pcall(function() isTarget = UnitIsUnit(unit, "target") end)
	if isTarget then
		frame.targetHighlight:Show()
		frame.border:SetBackdropBorderColor(1, 1, 0, 1) -- Yellow border for target
	else
		frame.targetHighlight:Hide()
		-- Don't reset border here if mouse is over (handled in OnLeave)
		local isMouseOver = false
		pcall(function() isMouseOver = frame:IsMouseOver() end)
		if not isMouseOver then
			frame.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		end
	end

	-- Update debuffs
	self:UpdateDebuffs(frame)

	-- Update buffs
	if self:GetSetting(nil, "showBuffs") then
		self:UpdateBuffs(frame)
	else
		-- Hide all buffs if disabled
		for _, buff in ipairs(frame.buffs) do
			buff:Hide()
		end
	end
end

-- Update raid marker icon
function BBF:UpdateRaidMarker(frame)
	local showMarkers = self:GetSetting(nil, "showRaidMarkers")

	if not showMarkers then
		frame.raidIcon:Hide()
		return
	end

	local index = GetRaidTargetIndex(frame.unit)
	if index then
		SetRaidTargetIconTexture(frame.raidIcon, index)
		frame.raidIcon:Show()
	else
		frame.raidIcon:Hide()
	end
end

-- Update debuffs on a boss frame
function BBF:UpdateDebuffs(frame)
	local unit = frame.unit
	local debuffSize = self:GetSetting(nil, "debuffSize")
	local maxDebuffs = self:GetSetting(nil, "maxDebuffs")
	local debuffFilter = self:GetSetting(nil, "debuffFilter")

	-- Clear existing debuffs (use SetAlpha during combat)
	for _, debuff in ipairs(frame.debuffs) do
		if InCombatLockdown() then
			debuff:SetAlpha(0)
		else
			debuff:Hide()
		end
	end

	local debuffIndex = 1
	local auraIndex = 1

	-- Check if aura should be shown based on filter
	local function ShouldShowAura(aura)
		if not aura then return false end

		-- Don't check player status here - use API filter instead
		-- Player filtering is done by adding "|PLAYER" to the GetAuraDataByIndex filter

		-- IMPORTANT: dispelName is a SECRET VALUE for boss units (always, not just in combat)
		-- Cannot check, compare, or use dispelName at all for boss units
		-- All dispel-based filtering is disabled for boss frames
		-- Players can still use the "All Debuffs" or "Player Debuffs Only" filters

		return true
	end

	-- Iterate through debuffs using AuraUtil
	local function HandleAura(aura)
		if debuffIndex > maxDebuffs then
			return true -- Stop iteration
		end

		-- No need to check isHarmful - the "HARMFUL" filter in GetAuraDataByIndex ensures we only get debuffs
		if aura and ShouldShowAura(aura) then
			local debuffFrame = frame.debuffs[debuffIndex]

			if not debuffFrame then
				debuffFrame = self:CreateAuraFrame(frame, debuffIndex, "debuff")
				frame.debuffs[debuffIndex] = debuffFrame
			end

			-- Update debuff icon
			debuffFrame.icon:SetTexture(aura.icon)

			-- Color border
			-- Note: dispelName is a secret value for boss units, cannot use for coloring
			-- All debuffs use red border
			debuffFrame.border:SetBackdropBorderColor(1, 0, 0, 1)

			-- Update cooldown
			-- WoW 12.0.0 Secret Values solution: Use C_UnitAuras.GetAuraDuration + SetCooldownFromDurationObject
			-- This is how oUF framework (used by UnhaltedUnitFrames) handles boss auras
			if aura.auraInstanceID then
				local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
				if duration then
					debuffFrame.cooldown:SetCooldownFromDurationObject(duration)
					if InCombatLockdown() then
						debuffFrame.cooldown:SetAlpha(1)
					else
						debuffFrame.cooldown:Show()
					end
				else
					if InCombatLockdown() then
						debuffFrame.cooldown:SetAlpha(0)
					else
						debuffFrame.cooldown:Hide()
					end
				end
			else
				if InCombatLockdown() then
					debuffFrame.cooldown:SetAlpha(0)
				else
					debuffFrame.cooldown:Hide()
				end
			end

			-- Update stack count
			-- Note: applications can be a secret value for boss units
			-- FontString:SetText() accepts secret values, so just check for existence
			if aura.applications then
				debuffFrame.count:SetText(aura.applications)
				if InCombatLockdown() then
					debuffFrame.count:SetAlpha(1)
				else
					debuffFrame.count:Show()
				end
			else
				if InCombatLockdown() then
					debuffFrame.count:SetAlpha(0)
				else
					debuffFrame.count:Hide()
				end
			end

			-- Set tooltip
			debuffFrame.auraInstanceID = aura.auraInstanceID

			-- Show the debuff frame (use SetAlpha during combat)
			if InCombatLockdown() then
				debuffFrame:SetAlpha(1)
			else
				debuffFrame:Show()
			end
			debuffIndex = debuffIndex + 1
		end
	end

	-- Build filter string based on settings
	-- Use API filter for player auras to avoid taint from protected fields
	local filter = "HARMFUL"
	if debuffFilter == "player" then
		filter = "HARMFUL|PLAYER"
	end

	-- Use the new C_UnitAuras API (12.0+)
	local auras
	local debugCount = 0
	repeat
		auras = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter)
		if auras then
			debugCount = debugCount + 1
			if BBF_DEBUG then
				local stacks = auras.applications or 0
				local duration = auras.duration or 0
				local shouldShow = ShouldShowAura(auras)
				local msg = string.format("Debuff %d: %s (ID: %d) - Stacks: %s, Duration: %.1fs, Show: %s",
					debugCount,
					auras.name or "Unknown",
					auras.spellId or 0,
					tostring(stacks),
					duration,
					tostring(shouldShow))
				print(msg)
				-- Save to debug log
				if not BetterBossFramesDB.debugLog then BetterBossFramesDB.debugLog = {} end
				table.insert(BetterBossFramesDB.debugLog, msg)
			end
			HandleAura(auras)
			auraIndex = auraIndex + 1
		end
	until not auras or debuffIndex > maxDebuffs

	if BBF_DEBUG then
		local msg = string.format("Total debuffs found: %d, Displayed: %d, Filter: %s, Max: %d", debugCount, debuffIndex - 1, filter, maxDebuffs)
		print(msg)
		-- Save to debug log
		if not BetterBossFramesDB.debugLog then BetterBossFramesDB.debugLog = {} end
		table.insert(BetterBossFramesDB.debugLog, msg)
		table.insert(BetterBossFramesDB.debugLog, "---")
	end

	-- Position all visible debuffs
	self:PositionAuras(frame, "debuff")
end

-- Update buffs on a boss frame
function BBF:UpdateBuffs(frame)
	local unit = frame.unit
	local buffSize = self:GetSetting(nil, "buffSize")
	local maxBuffs = self:GetSetting(nil, "maxBuffs")
	local buffFilter = self:GetSetting(nil, "buffFilter")

	-- Clear existing buffs (use SetAlpha during combat)
	for _, buff in ipairs(frame.buffs) do
		if InCombatLockdown() then
			buff:SetAlpha(0)
		else
			buff:Hide()
		end
	end

	local buffIndex = 1
	local auraIndex = 1

	-- Check if buff should be shown based on filter
	local function ShouldShowAura(aura)
		if not aura then return false end

		-- Don't check player status here - use API filter instead
		-- Player filtering is done by adding "|PLAYER" to the GetAuraDataByIndex filter

		return true
	end

	-- Iterate through buffs
	local function HandleAura(aura)
		if buffIndex > maxBuffs then
			return true -- Stop iteration
		end

		-- No need to check isHelpful - the "HELPFUL" filter in GetAuraDataByIndex ensures we only get buffs
		if aura and ShouldShowAura(aura) then
			local buffFrame = frame.buffs[buffIndex]

			if not buffFrame then
				buffFrame = self:CreateAuraFrame(frame, buffIndex, "buff")
				frame.buffs[buffIndex] = buffFrame
			end

			-- Update buff icon
			buffFrame.icon:SetTexture(aura.icon)

			-- Buff border (green for buffs)
			buffFrame.border:SetBackdropBorderColor(0, 1, 0, 1)

			-- Update cooldown
			-- WoW 12.0.0 Secret Values solution: Use C_UnitAuras.GetAuraDuration + SetCooldownFromDurationObject
			-- This is how oUF framework (used by UnhaltedUnitFrames) handles boss auras
			if aura.auraInstanceID then
				local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
				if duration then
					buffFrame.cooldown:SetCooldownFromDurationObject(duration)
					if InCombatLockdown() then
						buffFrame.cooldown:SetAlpha(1)
					else
						buffFrame.cooldown:Show()
					end
				else
					if InCombatLockdown() then
						buffFrame.cooldown:SetAlpha(0)
					else
						buffFrame.cooldown:Hide()
					end
				end
			else
				if InCombatLockdown() then
					buffFrame.cooldown:SetAlpha(0)
				else
					buffFrame.cooldown:Hide()
				end
			end

			-- Update stack count
			-- Note: applications can be a secret value for boss units
			-- FontString:SetText() accepts secret values, so just check for existence
			if aura.applications then
				buffFrame.count:SetText(aura.applications)
				if InCombatLockdown() then
					buffFrame.count:SetAlpha(1)
				else
					buffFrame.count:Show()
				end
			else
				if InCombatLockdown() then
					buffFrame.count:SetAlpha(0)
				else
					buffFrame.count:Hide()
				end
			end

			-- Set tooltip
			buffFrame.auraInstanceID = aura.auraInstanceID

			-- Show the buff frame (use SetAlpha during combat)
			if InCombatLockdown() then
				buffFrame:SetAlpha(1)
			else
				buffFrame:Show()
			end
			buffIndex = buffIndex + 1
		end
	end

	-- Build filter string based on settings
	-- Use API filter for player auras to avoid taint from protected fields
	local filter = "HELPFUL"
	if buffFilter == "player" then
		filter = "HELPFUL|PLAYER"
	end

	-- Use the new C_UnitAuras API (12.0+)
	local auras
	repeat
		auras = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter)
		if auras then
			HandleAura(auras)
			auraIndex = auraIndex + 1
		end
	until not auras or buffIndex > maxBuffs

	-- Position all visible buffs
	self:PositionAuras(frame, "buff")
end

-- Cast bar functions

-- Start casting
function BBF:CastStart(frame, unit)
	if not frame.castBar then return end
	if not self:GetSetting(nil, "showCastBar") then return end

	local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)

	if name then
		-- Regular cast
		frame.castBar.casting = true
		frame.castBar.channeling = false
		frame.castBar.spellID = spellID
		frame.castBar.notInterruptible = notInterruptible

		-- Get duration using WoW API (works with secret values)
		local duration = UnitCastingDuration(unit)

		-- Use StatusBar timer methods (handles secret values properly)
		frame.castBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Smooth, Enum.StatusBarTimerDirection.ElapsedTime)

		-- Set spell name
		if self:GetSetting(nil, "castBarShowSpellName") then
			frame.castBar.text:SetText(name)
		end

		-- Set spell icon
		if self:GetSetting(nil, "castBarShowIcon") and texture then
			frame.castBar.icon:SetTexture(texture)
			if InCombatLockdown() then
				frame.castBar.icon:SetAlpha(1)
				frame.castBar.iconBorder:SetAlpha(1)
			else
				frame.castBar.icon:Show()
				frame.castBar.iconBorder:Show()
			end
		else
			if InCombatLockdown() then
				frame.castBar.icon:SetAlpha(0)
				frame.castBar.iconBorder:SetAlpha(0)
			else
				frame.castBar.icon:Hide()
				frame.castBar.iconBorder:Hide()
			end
		end

		-- Note: notInterruptible is a secret boolean for boss units
		-- Cannot test it directly - will be handled by UNIT_SPELLCAST_INTERRUPTIBLE events
		-- Store it anyway for reference
		frame.castBar.notInterruptible = notInterruptible

		-- Default cast bar color (orange for regular casts)
		-- Will be updated by interruptible events if needed
		frame.castBar:SetStatusBarColor(1, 0.7, 0, 1)
		if InCombatLockdown() then
			frame.castBar.notInterruptibleOverlay:SetAlpha(0)
		else
			frame.castBar.notInterruptibleOverlay:Hide()
		end

		-- Hide time text (cannot display due to secret duration values)
		frame.castBar.time:SetText("")

		-- Show cast bar container (only use SetAlpha to avoid backdrop taint)
		frame.castBarContainer:SetAlpha(1)
	end
end

-- Start channeling
function BBF:CastChannel(frame, unit)
	if not frame.castBar then return end
	if not self:GetSetting(nil, "showCastBar") then return end

	local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)

	if name then
		-- Channel cast
		frame.castBar.casting = false
		frame.castBar.channeling = true
		frame.castBar.spellID = spellID
		frame.castBar.notInterruptible = notInterruptible

		-- Get duration using WoW API (works with secret values)
		local duration = UnitChannelDuration(unit)

		-- Use StatusBar timer methods (handles secret values properly)
		-- RemainingTime for channels (fills right to left)
		frame.castBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Smooth, Enum.StatusBarTimerDirection.RemainingTime)

		-- Set spell name
		if self:GetSetting(nil, "castBarShowSpellName") then
			frame.castBar.text:SetText(name)
		end

		-- Set spell icon
		if self:GetSetting(nil, "castBarShowIcon") and texture then
			frame.castBar.icon:SetTexture(texture)
			if InCombatLockdown() then
				frame.castBar.icon:SetAlpha(1)
				frame.castBar.iconBorder:SetAlpha(1)
			else
				frame.castBar.icon:Show()
				frame.castBar.iconBorder:Show()
			end
		else
			if InCombatLockdown() then
				frame.castBar.icon:SetAlpha(0)
				frame.castBar.iconBorder:SetAlpha(0)
			else
				frame.castBar.icon:Hide()
				frame.castBar.iconBorder:Hide()
			end
		end

		-- Note: notInterruptible is a secret boolean for boss units
		-- Cannot test it directly - will be handled by UNIT_SPELLCAST_INTERRUPTIBLE events
		-- Store it anyway for reference
		frame.castBar.notInterruptible = notInterruptible

		-- Default cast bar color (blue for channels)
		-- Will be updated by interruptible events if needed
		frame.castBar:SetStatusBarColor(0, 0.5, 1, 1)
		if InCombatLockdown() then
			frame.castBar.notInterruptibleOverlay:SetAlpha(0)
		else
			frame.castBar.notInterruptibleOverlay:Hide()
		end

		-- Hide time text (cannot display due to secret duration values)
		frame.castBar.time:SetText("")

		-- Show cast bar container (only use SetAlpha to avoid backdrop taint)
		frame.castBarContainer:SetAlpha(1)
	end
end

-- Stop casting
function BBF:CastStop(frame)
	if not frame.castBar then return end

	frame.castBar.casting = false
	frame.castBar.channeling = false
	frame.castBar.spellID = nil

	-- Hide cast bar container (only use SetAlpha to avoid backdrop taint)
	frame.castBarContainer:SetAlpha(0)
end

-- Cast failed/interrupted
function BBF:CastFailed(frame, event)
	if not frame.castBar then return end

	-- Show "Failed" or "Interrupted" briefly
	local text = event == "UNIT_SPELLCAST_FAILED" and "Failed" or "Interrupted"
	frame.castBar.text:SetText(text)
	frame.castBar:SetStatusBarColor(1, 0, 0, 1) -- Red

	-- Hide after a short delay
	C_Timer.After(0.5, function()
		self:CastStop(frame)
	end)
end

-- Update cast bar progress (OnUpdate)
-- Note: With StatusBar timer system, the progress bar updates automatically
-- Time remaining cannot be displayed due to Secret Values (duration is secret)
function BBF:UpdateCastBar(frame, elapsed)
	-- StatusBar:SetTimerDuration() handles everything automatically
	-- No manual updates needed
end

-- Update cast bar interruptible state
function BBF:CastInterruptible(frame, unit, event)
	if not frame.castBar then return end
	if not frame.castBar.casting and not frame.castBar.channeling then return end

	local notInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
	frame.castBar.notInterruptible = notInterruptible

	if notInterruptible then
		if InCombatLockdown() then
			frame.castBar.notInterruptibleOverlay:SetAlpha(1)
		else
			frame.castBar.notInterruptibleOverlay:Show()
		end
		frame.castBar:SetStatusBarColor(0.5, 0.5, 0.5, 1) -- Gray
	else
		if InCombatLockdown() then
			frame.castBar.notInterruptibleOverlay:SetAlpha(0)
		else
			frame.castBar.notInterruptibleOverlay:Hide()
		end
		if frame.castBar.casting then
			frame.castBar:SetStatusBarColor(1, 0.7, 0, 1) -- Orange for casts
		else
			frame.castBar:SetStatusBarColor(0, 0.5, 1, 1) -- Blue for channels
		end
	end
end

-- Create an aura frame (buff or debuff)
function BBF:CreateAuraFrame(parent, index, auraType)
	local size = auraType == "buff" and self:GetSetting(nil, "buffSize") or self:GetSetting(nil, "debuffSize")
	local containerFrame = auraType == "buff" and parent.buffFrame or parent.debuffFrame

	local aura = CreateFrame("Frame", nil, containerFrame)
	aura:SetSize(size, size)

	-- Icon
	aura.icon = aura:CreateTexture(nil, "BACKGROUND")
	aura.icon:SetAllPoints()
	aura.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Border
	aura.border = CreateFrame("Frame", nil, aura, "BackdropTemplate")
	aura.border:SetAllPoints()
	aura.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	aura.border:SetBackdropBorderColor(1, 0, 0, 1)

	-- Cooldown spiral
	aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
	aura.cooldown:SetAllPoints()
	aura.cooldown:SetDrawEdge(false)
	aura.cooldown:SetHideCountdownNumbers(false)

	-- Stack count
	aura.count = aura:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	aura.count:SetPoint("BOTTOMRIGHT", 2, 0)
	aura.count:SetTextColor(1, 1, 1)

	-- Tooltip
	aura:SetScript("OnEnter", function(self)
		if self.auraInstanceID then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetUnitAuraByAuraInstanceID(parent.unit, self.auraInstanceID)
			GameTooltip:Show()
		end
	end)

	aura:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return aura
end

-- Position auras (debuffs or buffs) based on settings
function BBF:PositionAuras(frame, auraType)
	local auraList = auraType == "buff" and frame.buffs or frame.debuffs
	local auraFrame = auraType == "buff" and frame.buffFrame or frame.debuffFrame
	local position = auraType == "buff" and self:GetSetting(nil, "buffPosition") or self:GetSetting(nil, "debuffPosition")
	local growth = auraType == "buff" and self:GetSetting(nil, "buffGrowth") or self:GetSetting(nil, "debuffGrowth")
	local size = auraType == "buff" and self:GetSetting(nil, "buffSize") or self:GetSetting(nil, "debuffSize")
	local spacing = 2

	-- Count visible auras
	local visibleAuras = 0
	for _, aura in ipairs(auraList) do
		if aura:IsShown() then
			visibleAuras = visibleAuras + 1
		end
	end

	if visibleAuras == 0 then
		return
	end

	-- Calculate aura frame size based on growth direction
	local frameWidth, frameHeight

	if growth == "right" or growth == "left" then
		frameWidth = (size + spacing) * visibleAuras
		frameHeight = size
	else -- up or down
		frameWidth = size
		frameHeight = (size + spacing) * visibleAuras
	end

	auraFrame:SetSize(frameWidth, frameHeight)

	-- Position the aura container
	-- Clear previous positioning
	auraFrame:ClearAllPoints()

	if position == "left" then
		auraFrame:SetPoint("RIGHT", frame, "LEFT", -5, 0)
	elseif position == "right" then
		auraFrame:SetPoint("LEFT", frame, "RIGHT", 5, 0)
	elseif position == "top" then
		auraFrame:SetPoint("BOTTOM", frame, "TOP", 0, 5)
	elseif position == "bottom" then
		auraFrame:SetPoint("TOP", frame, "BOTTOM", 0, -5)
	end

	-- Position individual auras
	local currentIndex = 0
	for _, aura in ipairs(auraList) do
		if aura:IsShown() then
			aura:ClearAllPoints()

			if currentIndex == 0 then
				-- First aura
				if growth == "right" then
					aura:SetPoint("LEFT", auraFrame, "LEFT", 0, 0)
				elseif growth == "left" then
					aura:SetPoint("RIGHT", auraFrame, "RIGHT", 0, 0)
				elseif growth == "up" then
					aura:SetPoint("BOTTOM", auraFrame, "BOTTOM", 0, 0)
				elseif growth == "down" then
					aura:SetPoint("TOP", auraFrame, "TOP", 0, 0)
				end
			else
				-- Subsequent auras
				local prevAura = auraList[currentIndex]

				if growth == "right" then
					aura:SetPoint("LEFT", prevAura, "RIGHT", spacing, 0)
				elseif growth == "left" then
					aura:SetPoint("RIGHT", prevAura, "LEFT", -spacing, 0)
				elseif growth == "up" then
					aura:SetPoint("BOTTOM", prevAura, "TOP", 0, spacing)
				elseif growth == "down" then
					aura:SetPoint("TOP", prevAura, "BOTTOM", 0, -spacing)
				end
			end

			currentIndex = currentIndex + 1
		end
	end
end

-- Update all boss frames
function BBF:UpdateAllFrames()
	for i = 1, MAX_BOSS_FRAMES do
		if self.frames[i] then
			self:UpdateBossFrame(self.frames[i])
		end
	end
end

-- Resize all frames
function BBF:ResizeFrames()
	local width = self:GetSetting(nil, "width")
	local height = self:GetSetting(nil, "height")

	for i = 1, MAX_BOSS_FRAMES do
		if self.frames[i] then
			local frame = self.frames[i]
			frame:SetSize(width, height)
			-- Reanchor name text to respect new width
			frame.nameText:ClearAllPoints()
			frame.nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -3)
			frame.nameText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -3)
			-- Reanchor level text
			frame.levelText:ClearAllPoints()
			frame.levelText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7, 3)
			-- Resize health bar
			frame.healthBar:ClearAllPoints()
			frame.healthBar:SetPoint("TOPLEFT", 5, -(height * 0.25))
			frame.healthBar:SetPoint("BOTTOMRIGHT", -5, (height * 0.3))
		end
	end

	-- Re-update to reposition debuffs
	self:UpdateAllFrames()
end

-- Initialize all boss frames
function BBF:InitializeBossFrames()
	self:CreateContainer()

	-- Create frames for each boss
	for i = 1, MAX_BOSS_FRAMES do
		self.frames[i] = self:CreateBossFrame(i)

		-- Cleanup: Remove backdrop from cast bar container if it exists (from old code)
		if self.frames[i].castBarContainer and self.frames[i].castBarContainer.SetBackdrop then
			pcall(function()
				self.frames[i].castBarContainer:SetBackdrop(nil)
			end)
		end
	end

	-- Register for boss frame updates
	local updateFrame = CreateFrame("Frame")
	updateFrame:SetScript("OnUpdate", function(self, elapsed)
		self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed

		if self.timeSinceLastUpdate >= DEBUFF_UPDATE_INTERVAL then
			BBF:UpdateAllFrames()
			self.timeSinceLastUpdate = 0
		end

		-- Update cast bars every frame for smooth animation
		for i = 1, MAX_BOSS_FRAMES do
			if BBF.frames[i] and BBF.frames[i].castBar then
				if BBF.frames[i].castBar.casting or BBF.frames[i].castBar.channeling then
					BBF:UpdateCastBar(BBF.frames[i], elapsed)
				end
			end
		end
	end)

	-- Register events
	-- Use RegisterUnitEvent for boss-specific events (more efficient - filters at C level)
	updateFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	updateFrame:RegisterUnitEvent("UNIT_HEALTH", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_AURA", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat

	-- Cast bar events
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "boss1", "boss2", "boss3", "boss4", "boss5")
	updateFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "boss1", "boss2", "boss3", "boss4", "boss5")

	updateFrame:SetScript("OnEvent", function(self, event, ...)
		if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
			BBF:UpdateAllFrames()
		elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
			-- RegisterUnitEvent only fires for boss1-5, no need to filter
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:UpdateBossFrame(BBF.frames[i])
					break
				end
			end
		elseif event == "UNIT_AURA" then
			-- RegisterUnitEvent only fires for boss1-5, no need to filter
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:UpdateDebuffs(BBF.frames[i])
					if BBF:GetSetting(nil, "showBuffs") then
						BBF:UpdateBuffs(BBF.frames[i])
					end
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_START" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastStart(BBF.frames[i], unit)
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_STOP" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastStop(BBF.frames[i])
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastFailed(BBF.frames[i], event)
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastChannel(BBF.frames[i], unit)
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastStop(BBF.frames[i])
					break
				end
			end
		elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
			local unit = ...
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].unit == unit then
					BBF:CastInterruptible(BBF.frames[i], unit, event)
					break
				end
			end
		elseif event == "PLAYER_TARGET_CHANGED" then
			-- Update all frames to show/hide target highlighting
			BBF:UpdateAllFrames()
		elseif event == "PLAYER_REGEN_ENABLED" then
			-- Left combat - show any frames that were hidden during combat
			for i = 1, MAX_BOSS_FRAMES do
				if BBF.frames[i] and BBF.frames[i].needsShow and UnitExists("boss" .. i) then
					BBF.frames[i]:Show()
					BBF.frames[i]:SetAlpha(1)
					BBF.frames[i].needsShow = nil
				end
			end
		end
	end)

	-- Integrate with Edit Mode (delay until PLAYER_LOGIN to ensure EditModeManagerFrame is ready)
	local loginFrame = CreateFrame("Frame")
	loginFrame:RegisterEvent("PLAYER_LOGIN")
	loginFrame:SetScript("OnEvent", function(self, event)
		-- Wait a tiny bit more to ensure Edit Mode is fully initialized
		C_Timer.After(0.5, function()
			BBF:IntegrateEditMode()
			-- Handle Blizzard boss frames after integration
			BBF:UpdateBlizzardFramesVisibility()
		end)
		self:UnregisterAllEvents()
	end)
end

-- Hide or show Blizzard boss frames
function BBF:UpdateBlizzardFramesVisibility()
	local hideBlizzard = self:GetSetting(nil, "hideBlizzardFrames")

	if hideBlizzard then
		self:HideBlizzardBossFrames()
	else
		self:ShowBlizzardBossFrames()
	end
end

-- Hide Blizzard boss frames
function BBF:HideBlizzardBossFrames()
	-- Hide the Blizzard boss frame container
	if Boss1TargetFrame then
		for i = 1, MAX_BOSS_FRAMES do
			local bossFrame = _G["Boss" .. i .. "TargetFrame"]
			if bossFrame then
				bossFrame:UnregisterAllEvents()
				bossFrame:Hide()
				bossFrame:SetAlpha(0)
			end
		end

		-- Also hide the parent container if it exists
		if BossTargetFrameContainer then
			BossTargetFrameContainer:UnregisterAllEvents()
			BossTargetFrameContainer:Hide()
			BossTargetFrameContainer:SetAlpha(0)
		end
	end
end

-- Show Blizzard boss frames
function BBF:ShowBlizzardBossFrames()
	-- Re-show the Blizzard boss frames
	if Boss1TargetFrame then
		for i = 1, MAX_BOSS_FRAMES do
			local bossFrame = _G["Boss" .. i .. "TargetFrame"]
			if bossFrame then
				bossFrame:SetAlpha(1)
				bossFrame:Show()
			end
		end

		-- Re-show the parent container if it exists
		if BossTargetFrameContainer then
			BossTargetFrameContainer:SetAlpha(1)
			BossTargetFrameContainer:Show()
		end

		-- Reload the UI to properly restore Blizzard frames
		print("|cff00ff00Better Boss Frames:|r Blizzard boss frames re-enabled. Type |cffffcc00/reload|r to fully restore them.")
	end
end

-- Integrate with Edit Mode using LibEditMode
function BBF:IntegrateEditMode()
	-- Get LibEditMode from namespace or LibStub
	LibEditMode = ns.LibEditMode or LibStub and LibStub:GetLibrary("LibEditMode", true)

	if not LibEditMode then
		print("|cffff0000Better Boss Frames:|r LibEditMode not found!")
		print("|cffffcc00Debug:|r ns.LibEditMode =", tostring(ns.LibEditMode))
		print("|cffffcc00Debug:|r LibStub =", tostring(LibStub))
		return
	end

	local container = self.container

	-- Get current layout info safely
	local layoutInfo = EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo and EditModeManagerFrame:GetActiveLayoutInfo()
	local layoutName = layoutInfo and layoutInfo.layoutName or "Layout 1"

	-- Default position
	local defaultPosition = {
		point = "CENTER",
		x = 0,
		y = 0,
	}

	-- Callback when position changes
	local function onPositionChanged(frame, layoutName, point, x, y)
		-- Position is automatically handled by LibEditMode
		-- We could save custom position data here if needed
		if ns.db and ns.db.layouts then
			if not ns.db.layouts[layoutName] then
				ns.db.layouts[layoutName] = {}
			end
			ns.db.layouts[layoutName].position = {
				point = point,
				x = x,
				y = y,
			}
		end
	end

	-- Register the container with Edit Mode
	local success, err = pcall(function()
		LibEditMode:AddFrame(container, onPositionChanged, defaultPosition, "BetterBossFrames")
	end)

	if not success then
		print("|cffff0000Better Boss Frames:|r Failed to register with Edit Mode:", err)
		return
	end

	-- Register Enter/Exit/Layout callbacks (highly advised by LibEditMode)
	if LibEditMode.RegisterCallback then
		-- On entering Edit Mode
		LibEditMode:RegisterCallback("enter", function()
			-- Show title and background
			container.title:Show()
			container.bg:SetColorTexture(0, 0, 0, 0.5)
			-- Show preview automatically
			if not BBF.previewMode then
				BBF:ShowPreview(true) -- auto mode
			end
		end)

		-- On exiting Edit Mode
		LibEditMode:RegisterCallback("exit", function()
			-- Hide title and background
			container.title:Hide()
			container.bg:SetColorTexture(0, 0, 0, 0)
			-- Hide preview if it was auto-enabled
			if BBF.previewMode and BBF.autoPreview then
				BBF:HidePreview(true) -- auto mode
			end
		end)

		-- On layout change
		LibEditMode:RegisterCallback("layout", function(layoutName)
			-- Load position for this layout
			if ns.db and ns.db.layouts and ns.db.layouts[layoutName] and ns.db.layouts[layoutName].position then
				local pos = ns.db.layouts[layoutName].position
				container:ClearAllPoints()
				container:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
			end
			-- Refresh all frames with new layout settings
			BBF:ResizeFrames()
			BBF:UpdateAllFrames()
		end)
	end

	-- Add settings
	local settings = {
		-- Width setting
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Frame Width",
			desc = "Width of each boss frame",
			default = 200,
			minValue = 100,
			maxValue = 400,
			valueStep = 10,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "width")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "width", value)
				BBF:ResizeFrames()
			end,
		},
		-- Height setting
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Frame Height",
			desc = "Height of each boss frame",
			default = 60,
			minValue = 40,
			maxValue = 120,
			valueStep = 5,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "height")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "height", value)
				BBF:ResizeFrames()
			end,
		},
		-- Debuff size
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Debuff Size",
			desc = "Size of debuff icons",
			default = 30,
			minValue = 20,
			maxValue = 50,
			valueStep = 2,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "debuffSize")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "debuffSize", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Max debuffs
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Max Debuffs",
			desc = "Maximum number of debuffs to show",
			default = 8,
			minValue = 1,
			maxValue = 20,
			valueStep = 1,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "maxDebuffs")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "maxDebuffs", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Debuff position
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Debuff Position",
			desc = "Where to show debuffs relative to boss frame",
			default = "left",
			values = {
				{value = "left", text = "Left"},
				{value = "right", text = "Right"},
				{value = "top", text = "Top"},
				{value = "bottom", text = "Bottom"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "debuffPosition")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "debuffPosition", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Debuff growth direction
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Debuff Growth",
			desc = "Direction debuffs grow when multiple are shown",
			default = "right",
			values = {
				{value = "right", text = "Right"},
				{value = "left", text = "Left"},
				{value = "up", text = "Up"},
				{value = "down", text = "Down"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "debuffGrowth")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "debuffGrowth", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Divider
		{
			kind = LibEditMode.SettingType.Divider,
		},
		-- Debuff filter type
		-- Note: Dispel-based filtering disabled due to WoW 12.0.0 Secret Values
		-- (dispelName is a secret value for boss units and cannot be checked)
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Debuff Filter",
			desc = "Filter which debuffs to show",
			default = "player",
			values = {
				{value = "all", text = "All Debuffs"},
				{value = "player", text = "Player Debuffs Only"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "debuffFilter")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "debuffFilter", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Divider
		{
			kind = LibEditMode.SettingType.Divider,
		},
		-- Show buffs
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Show Buffs",
			desc = "Show buffs on boss frames",
			default = false,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "showBuffs")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "showBuffs", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Buff size
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Buff Size",
			desc = "Size of buff icons",
			default = 30,
			minValue = 20,
			maxValue = 50,
			valueStep = 2,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "buffSize")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "buffSize", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Max buffs
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Max Buffs",
			desc = "Maximum number of buffs to show",
			default = 8,
			minValue = 1,
			maxValue = 20,
			valueStep = 1,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "maxBuffs")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "maxBuffs", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Buff position
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Buff Position",
			desc = "Where to show buffs relative to boss frame",
			default = "right",
			values = {
				{value = "left", text = "Left"},
				{value = "right", text = "Right"},
				{value = "top", text = "Top"},
				{value = "bottom", text = "Bottom"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "buffPosition")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "buffPosition", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Buff growth direction
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Buff Growth",
			desc = "Direction buffs grow when multiple are shown",
			default = "right",
			values = {
				{value = "right", text = "Right"},
				{value = "left", text = "Left"},
				{value = "up", text = "Up"},
				{value = "down", text = "Down"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "buffGrowth")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "buffGrowth", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Buff filter
		{
			kind = LibEditMode.SettingType.Dropdown,
			name = "Buff Filter",
			desc = "Filter which buffs to show",
			default = "all",
			values = {
				{value = "all", text = "All Buffs"},
				{value = "player", text = "Player Buffs Only"},
			},
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "buffFilter")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "buffFilter", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Divider
		{
			kind = LibEditMode.SettingType.Divider,
		},
		-- Show raid markers
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Show Raid Markers",
			desc = "Show raid target icons on boss frames",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "showRaidMarkers")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "showRaidMarkers", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Hide Blizzard boss frames
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Hide Blizzard Boss Frames",
			desc = "Hide the default Blizzard boss frames when using this addon",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "hideBlizzardFrames")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "hideBlizzardFrames", value)
				BBF:UpdateBlizzardFramesVisibility()
			end,
		},
		-- Divider
		{
			kind = LibEditMode.SettingType.Divider,
		},
		-- Show cast bar
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Show Cast Bars",
			desc = "Show cast bars below boss frames",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "showCastBar")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "showCastBar", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Cast bar height
		{
			kind = LibEditMode.SettingType.Slider,
			name = "Cast Bar Height",
			desc = "Height of the cast bar",
			default = 20,
			minValue = 15,
			maxValue = 30,
			valueStep = 1,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "castBarHeight")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "castBarHeight", value)
				-- Would need to recreate frames to apply this, for now just update
				BBF:UpdateAllFrames()
			end,
		},
		-- Cast bar show icon
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Cast Bar Show Icon",
			desc = "Show spell icon on cast bar",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "castBarShowIcon")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "castBarShowIcon", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Cast bar show spell name
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Cast Bar Show Spell Name",
			desc = "Show spell name on cast bar",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "castBarShowSpellName")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "castBarShowSpellName", value)
				BBF:UpdateAllFrames()
			end,
		},
		-- Cast bar show time
		{
			kind = LibEditMode.SettingType.Checkbox,
			name = "Cast Bar Show Time",
			desc = "Show remaining cast time on cast bar",
			default = true,
			get = function(layoutName)
				return BBF:GetSetting(layoutName, "castBarShowTime")
			end,
			set = function(layoutName, value)
				BBF:SetSetting(layoutName, "castBarShowTime", value)
				BBF:UpdateAllFrames()
			end,
		},
	}

	-- Add settings
	success, err = pcall(function()
		LibEditMode:AddFrameSettings(container, settings)
	end)

	if not success then
		print("|cffff0000Better Boss Frames:|r Failed to add settings:", err)
		return
	end

	print("|cff00ff00Better Boss Frames:|r Edit Mode integration complete!")
end
