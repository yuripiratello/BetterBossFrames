local ADDON_NAME, ns = ...

-- Initialize addon namespace
ns.BetterBossFrames = {}
local BBF = ns.BetterBossFrames

-- Get LibEditMode
ns.LibEditMode = ns.LibEditMode

-- Default settings
local defaults = {
	layouts = {}, -- Will store per-layout settings
	global = {
		width = 200,
		height = 60,
		debuffSize = 30,
		debuffPosition = "left", -- "left", "right", "top", "bottom"
		debuffGrowth = "right", -- Direction debuffs grow: "left", "right", "up", "down"
		maxDebuffs = 8,
		showOnlyPlayer = true, -- Only show player's debuffs
		hideBlizzardFrames = true, -- Hide default Blizzard boss frames

		-- Debuff filtering options
		debuffFilter = "player", -- "all", "player", "dispellable"
		showCurse = true,
		showDisease = true,
		showMagic = true,
		showPoison = true,

		-- Buff settings
		showBuffs = false,
		buffSize = 30,
		buffPosition = "right", -- "left", "right", "top", "bottom"
		buffGrowth = "right", -- Direction buffs grow: "left", "right", "up", "down"
		maxBuffs = 8,
		buffFilter = "all", -- "all", "player"

		-- Display options
		showRaidMarkers = true, -- Show raid target icons

		-- Cast bar settings
		showCastBar = true, -- Show cast bars
		castBarHeight = 20,
		castBarShowIcon = true, -- Show spell icon
		castBarShowSpellName = true, -- Show spell name
		castBarShowTime = true, -- Show cast time remaining
	}
}

-- Initialize saved variables
function BBF:InitializeDB()
	if not BetterBossFramesDB then
		BetterBossFramesDB = CopyTable(defaults)
	else
		-- Merge with defaults to ensure all fields exist
		for k, v in pairs(defaults) do
			if BetterBossFramesDB[k] == nil then
				BetterBossFramesDB[k] = v
			end
		end
		for k, v in pairs(defaults.global) do
			if BetterBossFramesDB.global[k] == nil then
				BetterBossFramesDB.global[k] = v
			end
		end
	end

	ns.db = BetterBossFramesDB
end

-- Utility function to get current layout name
function BBF:GetCurrentLayout()
	if EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo then
		local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
		return layoutInfo and layoutInfo.layoutName or "Layout 1"
	end
	return "Layout 1"
end

-- Get layout-specific setting or fall back to global
function BBF:GetSetting(layoutName, key)
	layoutName = layoutName or self:GetCurrentLayout()
	if ns.db.layouts[layoutName] and ns.db.layouts[layoutName][key] ~= nil then
		return ns.db.layouts[layoutName][key]
	end
	return ns.db.global[key]
end

-- Set layout-specific setting
function BBF:SetSetting(layoutName, key, value)
	layoutName = layoutName or self:GetCurrentLayout()
	if not ns.db.layouts[layoutName] then
		ns.db.layouts[layoutName] = {}
	end
	ns.db.layouts[layoutName][key] = value
end

-- Slash commands
SLASH_BETTERBOSSFRAMES1 = "/bbf"
SLASH_BETTERBOSSFRAMES2 = "/betterbossframes"
SlashCmdList["BETTERBOSSFRAMES"] = function(msg)
	msg = string.lower(msg)

	if msg == "preview" or msg == "toggle" then
		BBF:TogglePreview()
	elseif msg == "show" then
		BBF:ShowPreview()
	elseif msg == "hide" then
		BBF:HidePreview()
	elseif msg == "debug" then
		print("|cff00ff00Better Boss Frames Debug:|r")
		print("  Container:", BBF.container and "Created" or "Not created")
		print("  Frames created:", #BBF.frames)
		print("  LibEditMode:", ns.LibEditMode and "Loaded" or "Not loaded")
		print("  EditModeManagerFrame:", EditModeManagerFrame and "Ready" or "Not ready")
		if BBF.container then
			print("  Container visible:", BBF.container:IsVisible() and "Yes" or "No")
			print("  Container position:", BBF.container:GetPoint())
		end
	elseif msg == "debuglog" then
		if BetterBossFramesDB.debugLog and #BetterBossFramesDB.debugLog > 0 then
			print("|cff00ff00Better Boss Frames Debug Log:|r (" .. #BetterBossFramesDB.debugLog .. " entries)")
			for i, entry in ipairs(BetterBossFramesDB.debugLog) do
				print(entry)
			end
		else
			print("|cff00ff00Better Boss Frames:|r Debug log is empty. Enable debug with: /run BBF_DEBUG = true")
		end
	elseif msg == "clearlog" then
		BetterBossFramesDB.debugLog = {}
		print("|cff00ff00Better Boss Frames:|r Debug log cleared.")
	elseif msg == "help" or msg == "" then
		print("|cff00ff00Better Boss Frames Commands:|r")
		print("  |cffffcc00/bbf preview|r - Toggle preview mode")
		print("  |cffffcc00/bbf show|r - Show preview frames")
		print("  |cffffcc00/bbf hide|r - Hide preview frames")
		print("  |cffffcc00/bbf debug|r - Show debug information")
		print("  |cffffcc00/bbf debuglog|r - Show debug log (use after enabling BBF_DEBUG)")
		print("  |cffffcc00/bbf clearlog|r - Clear debug log")
		print("  |cffffcc00/bbf help|r - Show this help")
		print("  |cffffcc00/editmode|r - Open Edit Mode to customize")
	else
		print("|cffff0000Better Boss Frames:|r Unknown command. Use |cffffcc00/bbf help|r for help.")
	end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == ADDON_NAME then
		BBF:InitializeDB()
		BBF:InitializeBossFrames()
		print("|cff00ff00Better Boss Frames|r loaded! Type |cffffcc00/bbf help|r for commands.")
	end
end)
