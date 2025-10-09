------------------------------------------------------------------------------------------------------
-- Necrosis LdC
--
-- Original creator (US): Infernal (http://www.revolvus.com/games/interface/necrosis/)
-- Base implementation (FR): Tilienna Thorondor
-- Project continuation: Lomig & Nyx of Larmes de Cenarius, Kael'Thas
--
-- French skins and voices: Eliah, Ner'zhul
-- German version: Arne Meier and Halisstra, Lothar
-- Special thanks to Sadyre (JoL)
-- Version 05.09.2006-1
------------------------------------------------------------------------------------------------------

-- Default configuration
-- Loaded when no configuration is found or when the version changes
Default_NecrosisConfig = {
	Version = NecrosisData.Version,
	SoulshardContainer = 4,
	SoulshardSort = false,
	SoulshardDestroy = false,
	ShadowTranceAlert = true,
	ShowSpellTimers = true,
	AntiFearAlert = true,
	NecrosisLockServ = true,
	NecrosisAngle = 180,
	StonePosition = { true, true, true, true, true, true, true, true },
	NecrosisToolTip = true,
	NoDragAll = false,
	PetMenuPos = 34,
	BuffMenuPos = 34,
	CurseMenuPos = 34,
	StoneMenuPos = 34,
	ChatMsg = true,
	ChatType = true,
	NecrosisLanguage = GetLocale(),
	ShowCount = true,
	CountType = 1,
	ShadowTranceScale = 100,
	NecrosisButtonScale = 90,
	NecrosisColor = "Rose",
	Sound = true,
	SpellTimerPos = 1,
	SpellTimerJust = "LEFT",
	Circle = 1,
	Graphical = true,
	Yellow = true,
	SensListe = 1,
	PetName = {
		[1] = " ",
		[2] = " ",
		[3] = " ",
		[4] = " ",
	},
	DominationUp = false,
	AmplifyUp = false,
	SM = false, -- short messages
	SteedSummon = false,
	DemonSummon = true,
	RitualMessage = true,
	BanishScale = 100,
}

NecrosisConfig = {}
local Debug = false
local Loaded = false

-- Detect mod initialization
local NecrosisRL = true

-- Initialize variables used by Necrosis to manage spell casts
local SpellCastName = nil
local SpellCastRank = nil
local SpellTargetName = nil
local SpellCastTime = 0

local TIMER_TYPE = NECROSIS_TIMER_TYPE

-- Clears contents but preserves subtable objects
local function clear_tables(t)
	for k, v in pairs(t) do
		if type(v) == "table" then
			-- recurse: empty the subtable
			clear_tables(v)
		else
			-- remove only non-table values
			t[k] = nil
		end
	end
end

-- Clear array contents without releasing the table; used by per-frame buffers
local function wipe_array(t)
	for index = table.getn(t), 1, -1 do
		t[index] = nil
	end
end

-- Reusable buffers for graphical timers (avoid per-frame allocations)
local TextTimerSegments = {}
local GraphicalTimer = {
	activeCount = 0,
	names = {},
	expiryTimes = {},
	initialDurations = {},
	displayLines = {},
	slotIds = {},
}

local TimerTable = {}
for i = 1, 50, 1 do
	TimerTable[i] = false
end

local ICON_BASE_PATH = "Interface\\AddOns\\Necrosis\\UI\\"
local ACCENT_RING_TEXTURE = ICON_BASE_PATH .. "AccentRing"

local ICON_ACCENT_COLORS = {
	Agony = { 0.4656, 0.4655, 0.4655 },
	Amplify = { 0.2623, 0.2623, 0.2623 },
	Aqua = { 0.4678, 0.4678, 0.4678 },
	ArmureDemo = { 0.2955, 0.2952, 0.2953 },
	Banish = { 0.4772, 0.4775, 0.4783 },
	Domination = { 0.3429, 0.3429, 0.3429 },
	Doom = { 0.2978, 0.2977, 0.2977 },
	Doomguard = { 0.3490, 0.3490, 0.3490 },
	Elements = { 0.3217, 0.3216, 0.3216 },
	Enslave = { 0.3878, 0.3878, 0.3881 },
	Exhaust = { 0.3205, 0.3205, 0.3205 },
	Felhunter = { 0.2852, 0.2825, 0.2816 },
	Felstone = { 0.3590, 0.5627, 0.2030 },
	FirestoneButton = { 0.8148, 0.3459, 0.5506 },
	HealthstoneButton = { 0.2921, 0.7151, 0.2921 },
	Imp = { 0.3634, 0.3649, 0.3521 },
	Infernal = { 0.4980, 0.4980, 0.4980 },
	Invisible = { 0.5955, 0.5955, 0.5955 },
	Kilrogg = { 0.3402, 0.3402, 0.3402 },
	Lien = { 0.4047, 0.4047, 0.4047 },
	MountButton = { 0.3368, 0.3336, 0.3327 },
	Radar = { 0.3104, 0.3104, 0.3104 },
	Reckless = { 0.3942, 0.3941, 0.3941 },
	Sacrifice = { 0.3967, 0.3967, 0.3967 },
	Shadow = { 0.4189, 0.4188, 0.4188 },
	["ShadowTrance-Icon"] = { 0.4173, 0.2913, 0.4487 },
	ShadowWard = { 0.2620, 0.2620, 0.2620 },
	SoulstoneButton = { 0.5463, 0.2720, 0.5324 },
	SpellstoneButton = { 0.2844, 0.4891, 0.8284 },
	Succubus = { 0.3056, 0.3053, 0.3055 },
	Tongues = { 0.3034, 0.3034, 0.3034 },
	Voidstone = { 0.2820, 0.1570, 0.5112 },
	Voidwalker = { 0.1769, 0.1775, 0.1825 },
	Weakness = { 0.3441, 0.3440, 0.3440 },
	Wrathstone = { 0.5331, 0.1212, 0.1892 },
}

local HANDLED_ICON_BASES = {}
for name in pairs(ICON_ACCENT_COLORS) do
	HANDLED_ICON_BASES[name] = true
end

local function Necrosis_AttachRing(button)
	if button.NecrosisAccentRing then
		return button.NecrosisAccentRing
	end
	local ring = button:CreateTexture(nil, "OVERLAY")
	ring:SetTexture(ACCENT_RING_TEXTURE)
	ring:SetAllPoints(button)
	ring:SetVertexColor(0.66, 0.66, 0.66)
	button.NecrosisAccentRing = ring
	return ring
end

local function Necrosis_SetButtonTexture(button, base, variant)
	if not button or not base then
		return
	end
	local numberVariant = tonumber(variant) or variant or 2
	if not HANDLED_ICON_BASES[base] then
		button:SetNormalTexture(ICON_BASE_PATH .. base .. "-0" .. numberVariant)
		return
	end
	local texturePath = ICON_BASE_PATH .. base .. ".tga"
	button:SetNormalTexture(texturePath)
	local icon = button:GetNormalTexture()
	button.NecrosisIconBase = base
	icon:SetVertexColor(1, 1, 1)
	local ring = Necrosis_AttachRing(button)
	if numberVariant == 1 then
		icon:SetVertexColor(0.35, 0.35, 0.35)
		ring:SetVertexColor(0.35, 0.35, 0.35)
	elseif numberVariant == 3 then
		ring:SetVertexColor(unpack(ICON_ACCENT_COLORS[base] or { 0.66, 0.66, 0.66 }))
	else
		ring:SetVertexColor(0.66, 0.66, 0.66)
	end
end

local MENU_BUTTON_COUNT = 9

local function Necrosis_SetMenuAlpha(prefix, alpha)
	for index = 1, MENU_BUTTON_COUNT, 1 do
		local frame = getglobal(prefix .. index)
		if frame then
			frame:SetAlpha(alpha)
		end
	end
end

local function Necrosis_OnBagUpdate()
	if NecrosisConfig.SoulshardSort then
		Necrosis_SoulshardSwitch("CHECK")
	else
		Necrosis_BagExplore()
	end
end

local function Necrosis_OnSpellcastStart(spellName)
	Necrosis_DebugPrint("SPELLCAST_START", spellName or "nil")
	SpellCastName = spellName
	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end

	local function refreshSelfBuffTimer(spellIndex)
		local data = NECROSIS_SPELL_TABLE[spellIndex]
		if not data or not data.Name then
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("Buff timer", "no spell data", spellIndex)
			end
			return false
		end
		if spellName ~= data.Name then
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("Buff timer", "spell mismatch", spellName or "nil", "!=", data.Name)
			end
			return false
		end
		local playerName = UnitName("player") or ""
		local duration = data.Length or 0
		local expiry = floor(GetTime() + duration)
		local updated = false
		if type(Necrosis_UpdateTimerEntry) == "function" then
			updated, SpellTimer =
				Necrosis_UpdateTimerEntry(SpellTimer, data.Name, playerName, duration, expiry, data.Type, duration)
		end
		if not updated then
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("Buff timer", data.Name, "no existing entry; inserting")
			end
			SpellTimer, TimerTable = Necrosis_RemoveTimerByName(data.Name, SpellTimer, TimerTable)
		end
		LastRefreshedBuffName = data.Name
		LastRefreshedBuffTime = GetTime()
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("Buff timer", data.Name, updated and "updated" or "created", "(cast)")
		end
		return true
	end

	if not refreshSelfBuffTimer(31) then
		refreshSelfBuffTimer(36)
	end
end

local function Necrosis_ClearSpellcastContext()
	SpellCastName = nil
	SpellCastRank = nil
	SpellTargetName = nil
end

local function Necrosis_SetTradeRequest(active)
	NecrosisTradeRequest = active
end

local function Necrosis_OnTargetChanged()
	if NecrosisConfig.AntiFearAlert and AFCurrentTargetImmune then
		AFCurrentTargetImmune = false
	end
end

local function Necrosis_HandleSelfFearDamage(message)
	if not NecrosisConfig.AntiFearAlert or not message then
		return
	end
	for spell, creatureName in string.gfind(message, NECROSIS_ANTI_FEAR_SRCH) do
		if spell == NECROSIS_SPELL_TABLE[13].Name or spell == NECROSIS_SPELL_TABLE[19].Name then
			AFCurrentTargetImmune = true
			break
		end
	end
end

local function Necrosis_OnSpellLearned()
	Necrosis_SpellSetup()
	Necrosis_CreateMenu()
	Necrosis_ButtonSetup()
end

local function Necrosis_OnCombatEnd()
	PlayerCombat = false
	SpellTimer, TimerTable = Necrosis_RemoveCombatTimers(SpellTimer, TimerTable)
end

local function Necrosis_OnSpellcastStartEvent(_, spellName)
	Necrosis_OnSpellcastStart(spellName)
end

local function Necrosis_OnSpellcastStopEvent()
	if type(Necrosis_SpellManagement) == "function" then
		Necrosis_SpellManagement()
	end
end

local function Necrosis_OnTradeRequestEvent()
	Necrosis_SetTradeRequest(true)
end

local function Necrosis_OnTradeCancelledEvent()
	Necrosis_SetTradeRequest(false)
end

local function Necrosis_OnSelfDamageEvent(_, message)
	Necrosis_HandleSelfFearDamage(message)
end

local function Necrosis_OnUnitPetEvent(_, unitId)
	if unitId == "player" then
		Necrosis_ChangeDemon()
	end
end

local function Necrosis_FindPlayerBuff(buffName, options)
	if not buffName and type(options) ~= "table" then
		return nil, 0
	end
	options = options or {}
	local tooltipPattern = options.tooltipPattern
	local plainSearch = options.plain ~= false
	local matcher = options.matcher
	local index = 0
	while true do
		local buffId = GetPlayerBuff(index, "HELPFUL")
		if not buffId or buffId == -1 then
			return nil, 0
		end
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetPlayerBuff(buffId)
		local tooltipName = NecrosisTooltipTextLeft1 and NecrosisTooltipTextLeft1:GetText()
		local matched = false
		if matcher and tooltipName then
			matched = matcher(tooltipName)
		elseif tooltipName then
			if buffName and tooltipName == buffName then
				matched = true
			elseif tooltipPattern then
				if plainSearch then
					matched = string.find(tooltipName, tooltipPattern, 1, true) ~= nil
				else
					matched = string.find(tooltipName, tooltipPattern) ~= nil
				end
			end
		end
		if matched then
			local timeLeft = GetPlayerBuffTimeLeft(buffId) or 0
			return buffId, timeLeft, tooltipName
		end
		index = index + 1
	end
end

local function Necrosis_OnBuffEvent()
	Necrosis_SelfEffect("BUFF")
end

local function Necrosis_OnDebuffEvent()
	Necrosis_SelfEffect("DEBUFF")
end

local STONE_BUFF_KEYS = { "Firestone", "Felstone", "Wrathstone", "Voidstone" }

local function Necrosis_CreateStoneBuffConfig(itemKey)
	local stoneName = itemKey
	if NECROSIS_ITEM and NECROSIS_ITEM[itemKey] then
		stoneName = NECROSIS_ITEM[itemKey]
	end
	return {
		timerName = stoneName,
		buffName = stoneName,
		timerType = NECROSIS_TIMER_TYPE.SELF_BUFF,
		tooltipPattern = stoneName,
	}
end

local function Necrosis_BuildDefaultTrackedBuffs()
	local buffs = {
		{ spellIndex = 31 },
		{ spellIndex = 36 },
		{ spellIndex = 11 },
	}
	for index = 1, table.getn(STONE_BUFF_KEYS) do
		local stoneKey = STONE_BUFF_KEYS[index]
		local config = Necrosis_CreateStoneBuffConfig(stoneKey)
		table.insert(buffs, config)
	end
	return buffs
end

local DEFAULT_TRACKED_SELF_BUFFS = Necrosis_BuildDefaultTrackedBuffs()

local TRACKED_SELF_BUFFS = DEFAULT_TRACKED_SELF_BUFFS
local TRACKED_SELF_BUFF_COUNT = table.getn(TRACKED_SELF_BUFFS)

local function Necrosis_GetStoredBuffDuration(timerName)
	if not timerName then
		return nil
	end
	if type(NecrosisConfig) ~= "table" then
		return nil
	end
	local durations = NecrosisConfig.TrackedBuffDurations
	if type(durations) == "table" then
		return durations[timerName]
	end
	return nil
end

local function Necrosis_SetStoredBuffDuration(timerName, duration)
	if not timerName or not duration or duration <= 0 then
		return
	end
	if type(NecrosisConfig) ~= "table" then
		return
	end
	NecrosisConfig.TrackedBuffDurations = NecrosisConfig.TrackedBuffDurations or {}
	local durations = NecrosisConfig.TrackedBuffDurations
	if not durations[timerName] or duration > durations[timerName] then
		durations[timerName] = duration
	end
end

local function Necrosis_GetTrackedBuffTimerName(buffConfig)
	if not buffConfig then
		return nil
	end
	if buffConfig.timerName then
		return buffConfig.timerName
	end
	if buffConfig.spellIndex then
		local data = NECROSIS_SPELL_TABLE[buffConfig.spellIndex]
		if data and data.Name then
			return data.Name
		end
	end
	return buffConfig.buffName
end

local function Necrosis_FindTrackedBuffConfigByName(searchText)
	if not searchText then
		return nil
	end
	if type(TRACKED_SELF_BUFFS) ~= "table" then
		return nil
	end
	local count = TRACKED_SELF_BUFF_COUNT or table.getn(TRACKED_SELF_BUFFS)
	for index = 1, count do
		local config = TRACKED_SELF_BUFFS[index]
		if config then
			local timerName = Necrosis_GetTrackedBuffTimerName(config)
			if timerName and string.find(searchText, timerName, 1, true) then
				return config
			end
			if config.buffName and string.find(searchText, config.buffName, 1, true) then
				return config
			end
			if config.spellIndex then
				local data = NECROSIS_SPELL_TABLE[config.spellIndex]
				if data and data.Name and string.find(searchText, data.Name, 1, true) then
					return config
				end
			end
			local pattern = config.tooltipPattern
			if pattern then
				local plain = config.plain ~= false
				if plain then
					if string.find(searchText, pattern, 1, true) then
						return config
					end
				elseif string.find(searchText, pattern) then
					return config
				end
			end
		end
	end
	return nil
end

local function Necrosis_FindTrackedBuffTimerName(searchText)
	local config = Necrosis_FindTrackedBuffConfigByName(searchText)
	if not config then
		return nil
	end
	return Necrosis_GetTrackedBuffTimerName(config)
end

local function Necrosis_RemoveTrackedBuffTimerForMessage(message)
	if not message then
		return false
	end
	local timerName = Necrosis_FindTrackedBuffTimerName(message)
	if not timerName then
		return false
	end
	SpellTimer, TimerTable = Necrosis_RemoveTimerByName(timerName, SpellTimer, TimerTable)
	return true
end

local function Necrosis_RefreshSelfBuffTimer(buffConfig, playerName, currentTime)
	buffConfig = buffConfig or {}
	local spellIndex = buffConfig.spellIndex
	local data = nil
	if spellIndex then
		data = NECROSIS_SPELL_TABLE[spellIndex]
		if not data or not data.Name then
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("UNIT_AURA", "no spell data", spellIndex)
			end
			return false, Necrosis_GetTrackedBuffTimerName(buffConfig)
		end
	end
	local timerName = Necrosis_GetTrackedBuffTimerName(buffConfig)
	local searchName = buffConfig.buffName or (data and data.Name)
	if not timerName then
		timerName = searchName
	end
	local buffId, timeLeft = Necrosis_FindPlayerBuff(searchName, buffConfig)
	if not buffId or timeLeft <= 0 then
		return false, timerName
	end
	local durationSeconds = floor(timeLeft)
	local expiry = floor(currentTime + durationSeconds)
	local timerType = buffConfig.timerType or (data and data.Type) or NECROSIS_TIMER_TYPE.SELF_BUFF
	local baseDuration = buffConfig.baseDuration
	if data and data.Length and data.Length > 0 then
		if not baseDuration or data.Length > baseDuration then
			baseDuration = data.Length
		end
	end
	local storedDuration = Necrosis_GetStoredBuffDuration(timerName)
	if storedDuration and storedDuration > 0 then
		if not baseDuration or storedDuration > baseDuration then
			baseDuration = storedDuration
		end
	end
	if buffConfig.expectedDuration and buffConfig.expectedDuration > 0 then
		if not baseDuration or buffConfig.expectedDuration > baseDuration then
			baseDuration = buffConfig.expectedDuration
		end
	end
	if not baseDuration or baseDuration <= 0 then
		baseDuration = durationSeconds
	end
	if durationSeconds > baseDuration then
		baseDuration = durationSeconds
	end
	buffConfig.baseDuration = baseDuration
	Necrosis_SetStoredBuffDuration(timerName, baseDuration)
	if spellIndex then
		SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(
			spellIndex,
			playerName,
			durationSeconds,
			timerType,
			baseDuration,
			expiry,
			SpellTimer,
			TimerTable
		)
	else
		SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
			timerName,
			durationSeconds,
			timerType,
			playerName,
			baseDuration,
			expiry,
			SpellTimer,
			TimerTable
		)
	end
	if DEBUG_TIMER_EVENTS then
		Necrosis_DebugPrint("UNIT_AURA", timerName, "ensure timer", "timeLeft=", durationSeconds or 0)
	end
	LastRefreshedBuffName = timerName
	LastRefreshedBuffTime = currentTime
	return true, timerName
end

local function Necrosis_OnPlayerAuraEvent(_, unitId)
	if unitId ~= "player" then
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("UNIT_AURA", "ignored unit", unitId or "nil")
		end
		return
	end
	if DEBUG_TIMER_EVENTS then
		Necrosis_DebugPrint("UNIT_AURA", "player aura update")
	end

	local playerName = UnitName("player") or ""
	local currentTime = GetTime()
	if type(TRACKED_SELF_BUFFS) ~= "table" then
		TRACKED_SELF_BUFFS = DEFAULT_TRACKED_SELF_BUFFS
		TRACKED_SELF_BUFF_COUNT = table.getn(TRACKED_SELF_BUFFS)
	end
	for index = 1, TRACKED_SELF_BUFF_COUNT do
		local buffConfig = TRACKED_SELF_BUFFS[index]
		local handled, timerName = Necrosis_RefreshSelfBuffTimer(buffConfig, playerName, currentTime)
		if not handled then
			timerName = timerName or Necrosis_GetTrackedBuffTimerName(buffConfig)
			if timerName and Necrosis_TimerExists and Necrosis_TimerExists(timerName) then
				SpellTimer, TimerTable = Necrosis_RemoveTimerByName(timerName, SpellTimer, TimerTable)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("UNIT_AURA", timerName, "buff missing; removed timer")
				end
			end
		end
	end
end

local function Necrosis_OnCombatStartEvent()
	PlayerCombat = true
end

local NECROSIS_EVENT_HANDLERS = {
	BAG_UPDATE = Necrosis_OnBagUpdate,
	SPELLCAST_START = Necrosis_OnSpellcastStartEvent,
	SPELLCAST_STOP = Necrosis_OnSpellcastStopEvent,
	SPELLCAST_FAILED = Necrosis_ClearSpellcastContext,
	SPELLCAST_INTERRUPTED = Necrosis_ClearSpellcastContext,
	TRADE_REQUEST = Necrosis_OnTradeRequestEvent,
	TRADE_SHOW = Necrosis_OnTradeRequestEvent,
	TRADE_REQUEST_CANCEL = Necrosis_OnTradeCancelledEvent,
	TRADE_CLOSED = Necrosis_OnTradeCancelledEvent,
	PLAYER_TARGET_CHANGED = Necrosis_OnTargetChanged,
	CHAT_MSG_SPELL_SELF_DAMAGE = Necrosis_OnSelfDamageEvent,
	CHAT_MSG_SPELL_SELF_BUFF = Necrosis_OnBuffEvent,
	LEARNED_SPELL_IN_TAB = Necrosis_OnSpellLearned,
	PLAYER_REGEN_ENABLED = Necrosis_OnCombatEnd,
	PLAYER_REGEN_DISABLED = Necrosis_OnCombatStartEvent,
	UNIT_PET = Necrosis_OnUnitPetEvent,
	CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = Necrosis_OnBuffEvent,
	CHAT_MSG_SPELL_AURA_GONE_SELF = Necrosis_OnDebuffEvent,
	CHAT_MSG_SPELL_BREAK_AURA = Necrosis_OnDebuffEvent,
	UNIT_AURA = Necrosis_OnPlayerAuraEvent,
}

local function Necrosis_RegisterSpecialFrame(frameName)
	if not UISpecialFrames then
		UISpecialFrames = {}
	end
	for index = 1, table.getn(UISpecialFrames), 1 do
		if UISpecialFrames[index] == frameName then
			return
		end
	end
	table.insert(UISpecialFrames, frameName)
end

local MenuState = {
	Pet = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Buff = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Curse = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Stone = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
}

local LastCast = {
	Demon = 0,
	Buff = 0,
	Curse = { id = 0, click = "LeftButton" },
	Stone = { id = 0, click = "LeftButton" },
}

local LastRefreshedBuffName = nil
local LastRefreshedBuffTime = 0

local AuraScanAccumulator = 0

local function Necrosis_GetBuffSpellIndexByName(buffName)
	if not buffName then
		return nil
	end
	if NECROSIS_SPELL_TABLE[31] and buffName == NECROSIS_SPELL_TABLE[31].Name then
		return 31
	end
	if NECROSIS_SPELL_TABLE[36] and buffName == NECROSIS_SPELL_TABLE[36].Name then
		return 36
	end
	return nil
end

local function Necrosis_WasBuffRecentlyRefreshed(buffName)
	if not buffName or not LastRefreshedBuffName then
		return false
	end
	if LastRefreshedBuffName ~= buffName then
		return false
	end
	return (GetTime() - LastRefreshedBuffTime) <= 1
end

local function Necrosis_SetMenuFramesAlpha(menuState, alpha)
	local frames = menuState.frames
	if not frames then
		return
	end
	for index = 1, table.getn(frames) do
		local frame = frames[index]
		if frame then
			frame:SetAlpha(alpha)
		end
	end
end

local function Necrosis_AddMenuFrame(menuState, frameName, anchorButton, menuPos)
	local frame = getglobal(frameName)
	if not frame then
		return nil
	end
	frame:ClearAllPoints()
	local previousIndex = table.getn(menuState.frames)
	local previous = nil
	if previousIndex > 0 then
		previous = menuState.frames[previousIndex]
	end
	if previous then
		local spacing = 0
		if menuPos and menuPos ~= 0 then
			spacing = (36 / menuPos) * 31
		end
		frame:SetPoint("CENTER", previous, "CENTER", spacing, 0)
	else
		frame:SetPoint("CENTER", anchorButton, "CENTER", 3000, 3000)
	end
	frame:Hide()
	table.insert(menuState.frames, frame)
	return frame
end

local function Necrosis_HideMenuFrames(prefix, count)
	for index = 1, count, 1 do
		local frame = getglobal(prefix .. index)
		if frame then
			frame:Hide()
		end
	end
end

local function Necrosis_ShowMenuFrames(menuState)
	for index = 1, table.getn(menuState.frames), 1 do
		ShowUIPanel(menuState.frames[index])
	end
end

local function Necrosis_HasSpell(spellIndex)
	return spellIndex and NECROSIS_SPELL_TABLE[spellIndex] and NECROSIS_SPELL_TABLE[spellIndex].ID
end

local function Necrosis_ShouldAddMenuEntry(entry)
	if entry.condition then
		return entry.condition()
	end
	if entry.spell then
		return Necrosis_HasSpell(entry.spell)
	end
	if entry.spells then
		local requireAll = entry.check == "all"
		if requireAll then
			for index = 1, table.getn(entry.spells), 1 do
				if not Necrosis_HasSpell(entry.spells[index]) then
					return false
				end
			end
			return true
		end
		for index = 1, table.getn(entry.spells), 1 do
			if Necrosis_HasSpell(entry.spells[index]) then
				return true
			end
		end
		return false
	end
	return false
end

local function Necrosis_BuildMenu(definition)
	if not definition then
		return
	end
	local menuState = definition.state
	if not menuState then
		return
	end
	Necrosis_HideMenuFrames(definition.prefix, definition.count)
	local anchor = getglobal(definition.anchor)
	if not anchor then
		return
	end
	local menuPos = NecrosisConfig[definition.configKey] or 0
	for index = 1, table.getn(definition.entries), 1 do
		local entry = definition.entries[index]
		if Necrosis_ShouldAddMenuEntry(entry) then
			local frame = Necrosis_AddMenuFrame(menuState, entry.frame, anchor, menuPos)
			if frame then
				if entry.texture then
					Necrosis_SetButtonTexture(frame, entry.texture[1], entry.texture[2])
				end
				if entry.onAdd then
					entry.onAdd(frame)
				end
			end
		end
	end
	Necrosis_ShowMenuFrames(menuState)
end

local function Necrosis_ToggleMenu(state, button, options)
	state.open = not state.open
	if not state.open then
		state.fading = false
		state.sticky = false
		button:SetNormalTexture(options.closedTexture)
		if state.frames[1] then
			state.frames[1]:ClearAllPoints()
			state.frames[1]:SetPoint("CENTER", button, "CENTER", 3000, 3000)
		end
		if options.resetAlpha then
			Necrosis_SetMenuFramesAlpha(state, options.resetAlpha)
		end
		state.alpha = 1
		if options.onClose then
			options.onClose()
		end
		return false
	end

	state.fading = true
	button:SetNormalTexture(options.openTexture)
	if options.rightSticky and options.rightSticky() then
		state.sticky = true
	end
	if options.setAlpha then
		Necrosis_SetMenuFramesAlpha(state, options.setAlpha)
	end
	if options.onOpen then
		options.onOpen()
	end
	return true
end

-- Variables used to manage mounts
local MountAvailable = false
local NecrosisMounted = false
local NecrosisTellMounted = true
local PlayerCombat = false

-- Variables used to manage Shadow Trance
local ShadowTrance = false
local AntiFearInUse = false
local ShadowTranceID = -1

-- Variables used to manage soul shards
local SoulshardState = {
	count = 0,
	container = 4,
	slots = {},
	nextSlotIndex = 1,
	pendingMoves = 0,
	tidyAccumulator = 0,
}

-- Variables used to manage summoning components
-- (primarily counting)
local InfernalStone = 0
local DemoniacStone = 0

-- Variables used to manage stone summon and usage buttons
local StoneIDInSpellTable = { 0, 0, 0, 0, 0, 0, 0 }
-- Indices used for NecrosisConfig.StonePosition
StonePos = {
	Healthstone = 1,
	Spellstone = 2,
	Soulstone = 3,
	BuffMenu = 4,
	Mount = 5,
	PetMenu = 6,
	CurseMenu = 7,
	StoneMenu = 8,
}
local SoulstoneUsedOnTarget = false
local StoneInventory = {
	Soulstone = { onHand = false, location = { nil, nil }, mode = 1 },
	Healthstone = { onHand = false, location = { nil, nil }, mode = 1 },
	Firestone = { onHand = false, location = { nil, nil } },
	Spellstone = { onHand = false, location = { nil, nil }, mode = 1 },
	Felstone = { onHand = false, location = { nil, nil } },
	Wrathstone = { onHand = false, location = { nil, nil } },
	Voidstone = { onHand = false, location = { nil, nil } },
	Hearthstone = { onHand = false, location = { nil, nil } },
	Itemswitch = { onHand = false, location = { nil, nil } },
}

local STONE_ITEM_KEYS = {
	"Soulstone",
	"Healthstone",
	"Spellstone",
	"Firestone",
	"Felstone",
	"Wrathstone",
	"Voidstone",
	"Hearthstone",
}

local function Necrosis_RecordStoneInventory(stoneKey, container, slot)
	local data = StoneInventory[stoneKey]
	if not data then
		return
	end
	data.onHand = true
	data.location = { container, slot }
end

-- Variables controlling whether a resurrection timer can be used
local SoulstoneWaiting = false
local SoulstoneCooldown = false
local SoulstoneAdvice = false
local SoulstoneTarget = ""

-- Variables used for demon management
local DemonType = nil
local DemonEnslaved = false

-- Variables used for anti-fear handling
local AFblink1, AFBlink2 = 0
local AFImageType = { "", "Immu", "Prot" } -- Fear warning button filename variations
local AFCurrentTargetImmune = false

-- Variables used for trading stones with players
local NecrosisTradeRequest = false
local Trading = false
local TradingNow = 0

-- Manage soul shard bags
local BagIsSoulPouch = { nil, nil, nil, nil, nil }

-- Store the last summon messages
local PetMess = 0
local SteedMess = 0
local RezMess = 0
local TPMess = 0

-- Manages tooltips in Necrosis (excluding the coin frame)
local lOriginal_GameTooltip_ClearMoney

local Necrosis_In = true

local DEBUG_TIMER_EVENTS = false

function Necrosis_DebugPrint(...)
	if not DEBUG_TIMER_EVENTS or not DEFAULT_CHAT_FRAME then
		return
	end
	local message = "|cffff66ffNecrosis Debug:|r "
	local count = arg and table.getn(arg) or 0
	if count == 0 then
		DEFAULT_CHAT_FRAME:AddMessage(message)
		return
	end
	for index = 1, count, 1 do
		message = message .. tostring(arg[index])
		if index < count then
			message = message .. " "
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(message)
end

function Necrosis_Debug(state)
	if state == nil then
		DEBUG_TIMER_EVENTS = not DEBUG_TIMER_EVENTS
	else
		DEBUG_TIMER_EVENTS = not not state
	end
	Necrosis_DebugPrint("Timer debug", DEBUG_TIMER_EVENTS and "enabled" or "disabled")
end

------------------------------------------------------------------------------------------------------
-- NECROSIS FUNCTIONS APPLIED WHEN ENTERING THE GAME
------------------------------------------------------------------------------------------------------

-- Function executed during load
function Necrosis_OnLoad()
	-- Allows tracking which spells are cast
	Necrosis_Hook("UseAction", "Necrosis_UseAction", "before")
	Necrosis_Hook("CastSpell", "Necrosis_CastSpell", "before")
	Necrosis_Hook("CastSpellByName", "Necrosis_CastSpellByName", "before")

	-- Register the events intercepted by Necrosis
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("PLAYER_LEAVING_WORLD")

	for eventName in pairs(NECROSIS_EVENT_HANDLERS) do
		NecrosisButton:RegisterEvent(eventName)
	end

	Necrosis_RegisterSpecialFrame("NecrosisGeneralFrame")

	-- Register graphical components
	NecrosisButton:RegisterForDrag("LeftButton")
	NecrosisButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	NecrosisButton:SetFrameLevel(1)

	-- Enregistrement de la commande console
	SlashCmdList["NecrosisCommand"] = Necrosis_SlashHandler
	SLASH_NecrosisCommand1 = "/necro"
end

-- Function executed after addon variables are loaded
function Necrosis_LoadVariables()
	if Loaded or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	Necrosis_Initialize()
	Loaded = true

	-- Detect the demon type when logging in
	DemonType = UnitCreatureFamily("pet")
end

------------------------------------------------------------------------------------------------------
-- NECROSIS FUNCTIONS
------------------------------------------------------------------------------------------------------

local textTimersDisplay = ""
local coloredTextTimersDisplay = ""
local TextTimersNeedRefresh = true
local LastTextTimerBuildTime = 0

function Necrosis_MarkTextTimersDirty()
	TextTimersNeedRefresh = true
end

local function Necrosis_UpdateSoulShardSorting(elapsed)
	SoulshardState.tidyAccumulator = (SoulshardState.tidyAccumulator or 0) + elapsed
	if SoulshardState.tidyAccumulator >= 1 then
		local tidyOvershoot = floor(SoulshardState.tidyAccumulator)
		SoulshardState.tidyAccumulator = SoulshardState.tidyAccumulator - tidyOvershoot
		if SoulshardState.pendingMoves > 0 then
			Necrosis_SoulshardSwitch("MOVE")
		end
	end
end

local function Necrosis_UpdateTrackedBuffTimers(elapsed, curTime)
	AuraScanAccumulator = AuraScanAccumulator + elapsed
	if AuraScanAccumulator < 1 then
		return
	end

	local auraOvershoot = floor(AuraScanAccumulator)
	AuraScanAccumulator = AuraScanAccumulator - auraOvershoot

	local playerName = UnitName("player") or ""
	local tracked = TRACKED_SELF_BUFFS or DEFAULT_TRACKED_SELF_BUFFS
	local trackedCount = TRACKED_SELF_BUFF_COUNT or table.getn(tracked)
	for index = 1, trackedCount do
		local buffConfig = tracked[index]
		local handled, timerName = Necrosis_RefreshSelfBuffTimer(buffConfig, playerName, curTime)
		if not handled then
			timerName = timerName or Necrosis_GetTrackedBuffTimerName(buffConfig)
			if timerName and Necrosis_TimerExists and Necrosis_TimerExists(timerName) then
				SpellTimer, TimerTable = Necrosis_RemoveTimerByName(timerName, SpellTimer, TimerTable)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("BUFF fallback", timerName, "removed (buff missing)")
				end
			end
		end
	end
end

local function Necrosis_UpdateMenuState(menu, frameName, toggleFunc, curTime)
	if not menu or not menu.fading then
		return
	end

	if curTime >= menu.fadeAt and menu.alpha > 0 and not menu.sticky then
		menu.fadeAt = curTime + 0.1
		Necrosis_SetMenuAlpha(frameName, menu.alpha)
		menu.alpha = menu.alpha - 0.1
	end

	if menu.alpha <= 0 then
		toggleFunc()
	end
end

local function Necrosis_UpdateMenus(curTime)
	Necrosis_UpdateMenuState(MenuState.Pet, "NecrosisPetMenu", Necrosis_PetMenu, curTime)
	Necrosis_UpdateMenuState(MenuState.Buff, "NecrosisBuffMenu", Necrosis_BuffMenu, curTime)
	Necrosis_UpdateMenuState(MenuState.Curse, "NecrosisCurseMenu", Necrosis_CurseMenu, curTime)
	Necrosis_UpdateMenuState(MenuState.Stone, "NecrosisStoneMenu", Necrosis_StoneMenu, curTime)
end

local function Necrosis_UpdateShadowTrance(curTime)
	if not NecrosisConfig.ShadowTranceAlert then
		return
	end

	local Actif = false
	local TimeLeft = 0
	Necrosis_UnitHasTrance()
	if ShadowTranceID ~= -1 then
		Actif = true
	end
	if Actif and not ShadowTrance then
		ShadowTrance = true
		Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.Message, "USER")
		if NecrosisConfig.Sound then
			PlaySoundFile(NECROSIS_SOUND.ShadowTrance)
		end
		local ShadowTranceIndex, cancel = GetPlayerBuff(ShadowTranceID, "HELPFUL|HARMFUL|PASSIVE")
		TimeLeft = floor(GetPlayerBuffTimeLeft(ShadowTranceIndex))
		NecrosisShadowTranceTimer:SetText(TimeLeft)
		ShowUIPanel(NecrosisShadowTranceButton)
	end
	if not Actif and ShadowTrance then
		HideUIPanel(NecrosisShadowTranceButton)
		ShadowTrance = false
	end
	if Actif and ShadowTrance then
		local ShadowTranceIndex, cancel = GetPlayerBuff(ShadowTranceID, "HELPFUL|HARMFUL|PASSIVE")
		TimeLeft = floor(GetPlayerBuffTimeLeft(ShadowTranceIndex))
		NecrosisShadowTranceTimer:SetText(TimeLeft)
	end
end

local function Necrosis_UpdateAntiFear(curTime)
	if not NecrosisConfig.AntiFearAlert then
		return
	end

	local Actif = false
	if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
		if not UnitIsPlayer("target") then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_UNIT), 1 do
				if UnitCreatureType("target") == NECROSIS_ANTI_FEAR_UNIT[index] then
					Actif = 2
					break
				end
			end
		end
		if not Actif then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Buff), 1 do
				if Necrosis_UnitHasBuff("target", NECROSIS_ANTI_FEAR_SPELL.Buff[index]) then
					Actif = 3
					break
				end
			end
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Debuff), 1 do
				if Necrosis_UnitHasEffect("target", NECROSIS_ANTI_FEAR_SPELL.Debuff[index]) then
					Actif = 3
					break
				end
			end
		end
		if AFCurrentTargetImmune and not Actif then
			Actif = 1
		end
	end

	if Actif then
		if not AntiFearInUse then
			AntiFearInUse = true
			Necrosis_Msg(NECROSIS_MESSAGE.Information.FearProtect, "USER")
			NecrosisAntiFearButton:SetNormalTexture(
				"Interface\\AddOns\\Necrosis\\UI\\AntiFear" .. AFImageType[Actif] .. "-02"
			)
			if NecrosisConfig.Sound then
				PlaySoundFile(NECROSIS_SOUND.Fear)
			end
			ShowUIPanel(NecrosisAntiFearButton)
			AFBlink1 = curTime + 0.6
			AFBlink2 = 2
		elseif curTime >= AFBlink1 then
			if AFBlink2 == 1 then
				AFBlink2 = 2
			else
				AFBlink2 = 1
			end
			AFBlink1 = curTime + 0.4
			NecrosisAntiFearButton:SetNormalTexture(
				"Interface\\AddOns\\Necrosis\\UI\\AntiFear" .. AFImageType[Actif] .. "-0" .. AFBlink2
			)
		end
	elseif AntiFearInUse then
		AntiFearInUse = false
		HideUIPanel(NecrosisAntiFearButton)
	end
end

local function Necrosis_HandleShardCount()
	if NecrosisConfig.CountType == 3 then
		NecrosisShardCount:SetText("")
	end
end

local function Necrosis_ShouldUpdateSpellState(curTime)
	if (curTime - SpellCastTime) < 1 then
		return false
	end
	SpellCastTime = curTime
	return true
end

local function Necrosis_HandleTradingAndIcons(shouldUpdate)
	if not shouldUpdate then
		return
	end

	if Trading then
		TradingNow = TradingNow - 1
		if TradingNow == 0 then
			AcceptTrade()
			Trading = false
		end
	end

	Necrosis_UpdateIcons()
end

local function Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	if not SpellTimer then
		return
	end

	if not shouldUpdate then
		return
	end

	wipe_array(TextTimerSegments)
	local textBuffer = TextTimerSegments
	local graphCount = 0
	local previousActive = GraphicalTimer.activeCount or 0
	local curTimeFloor = floor(curTime)
	local targetName = UnitName("target")
	local textVisible = NecrosisConfig.ShowSpellTimers
		and not NecrosisConfig.Graphical
		and NecrosisSpellTimerButton:IsVisible()
	local buildText = textVisible and (TextTimersNeedRefresh or curTimeFloor ~= LastTextTimerBuildTime)

	for index = table.getn(SpellTimer), 1, -1 do
		local timer = SpellTimer[index]
		if timer then
			local name = timer.Name
			local timeMax = timer.TimeMax or 0

			if curTime >= (timeMax - 0.5) and timeMax ~= -1 then
				if name == NECROSIS_SPELL_TABLE[11].Name then
					Necrosis_Msg(NECROSIS_MESSAGE.Information.SoulstoneEnd, "USER")
					timer.Target = ""
					timer.TimeMax = -1
					if NecrosisConfig.Sound then
						PlaySoundFile(NECROSIS_SOUND.SoulstoneEnd)
					end
					if timer.Gtimer then
						TimerTable = Necrosis_RemoveTimerFrame(timer.Gtimer, TimerTable)
					end
					Necrosis_UpdateIcons()
				elseif name ~= NECROSIS_SPELL_TABLE[10].Name then
					SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
				end
			else
				if name == NECROSIS_SPELL_TABLE[17].Name and not Necrosis_UnitHasEffect("player", name) then
					SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
				elseif
					(timer.Type == TIMER_TYPE.CURSE or timer.Type == TIMER_TYPE.COMBAT)
					and timer.Target == targetName
					and curTime >= ((timer.TimeMax - timer.Time) + 1.5)
				then
					if not Necrosis_UnitHasEffect("target", name or timer.Name) then
						SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
					end
				end
			end
		end
	end

	if TimerTable then
		for slot = 1, table.getn(TimerTable), 1 do
			if TimerTable[slot] then
				TimerTable = Necrosis_RemoveTimerFrame(slot, TimerTable)
			else
				TimerTable[slot] = false
			end
		end
	end

	for i = 1, table.getn(SpellTimer), 1 do
		local timer = SpellTimer[i]
		if timer then
			timer.Gtimer = nil
		end
	end

	for index = 1, table.getn(SpellTimer), 1 do
		local timer = SpellTimer[index]
		if timer and curTime <= (timer.TimeMax or 0) then
			TimerTable, graphCount = Necrosis_DisplayTimer(
				textBuffer,
				index,
				SpellTimer,
				GraphicalTimer,
				TimerTable,
				graphCount,
				curTimeFloor,
				buildText
			)
		end
	end
	if previousActive > graphCount then
		for slotIndex = graphCount + 1, previousActive, 1 do
			GraphicalTimer.names[slotIndex] = nil
			GraphicalTimer.expiryTimes[slotIndex] = nil
			GraphicalTimer.initialDurations[slotIndex] = nil
			GraphicalTimer.displayLines[slotIndex] = nil
			GraphicalTimer.slotIds[slotIndex] = nil
		end
	end
	GraphicalTimer.activeCount = graphCount
	if buildText then
		textTimersDisplay = table.concat(textBuffer)
		coloredTextTimersDisplay = Necrosis_MsgAddColor(textTimersDisplay)
		LastTextTimerBuildTime = curTimeFloor
		TextTimersNeedRefresh = false
	end
end

local function Necrosis_UpdateTimerDisplay()
	if NecrosisConfig.ShowSpellTimers or NecrosisConfig.Graphical then
		if not NecrosisSpellTimerButton:IsVisible() then
			ShowUIPanel(NecrosisSpellTimerButton)
			if NecrosisConfig.ShowSpellTimers then
				TextTimersNeedRefresh = true
			end
		end
		if NecrosisConfig.ShowSpellTimers and not NecrosisConfig.Graphical then
			NecrosisListSpells:SetText(coloredTextTimersDisplay)
		else
			NecrosisListSpells:SetText("")
		end
	elseif NecrosisSpellTimerButton:IsVisible() then
		NecrosisListSpells:SetText("")
		HideUIPanel(NecrosisSpellTimerButton)
		TextTimersNeedRefresh = true
	end
end

-- Function executed on UI updates (roughly every 0.1 seconds)
function Necrosis_OnUpdate(self, elapsed)
	if (not Loaded) and UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	elapsed = elapsed or 0
	local curTime = GetTime()

	Necrosis_UpdateSoulShardSorting(elapsed)
	Necrosis_UpdateTrackedBuffTimers(elapsed, curTime)
	Necrosis_UpdateMenus(curTime)
	Necrosis_UpdateShadowTrance(curTime)
	Necrosis_UpdateAntiFear(curTime)
	Necrosis_HandleShardCount()

	local shouldUpdate = Necrosis_ShouldUpdateSpellState(curTime)
	Necrosis_HandleTradingAndIcons(shouldUpdate)
	Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	Necrosis_UpdateTimerDisplay()
end

-- Function triggered for each intercepted event
function Necrosis_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		Necrosis_In = true
		return
	elseif event == "PLAYER_LEAVING_WORLD" then
		Necrosis_In = false
		return
	end

	if (not Loaded) or not Necrosis_In or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	local handler = NECROSIS_EVENT_HANDLERS[event]
	if handler then
		handler(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	end
end

------------------------------------------------------------------------------------------------------
-- NECROSIS FUNCTIONS "ON EVENT"
------------------------------------------------------------------------------------------------------

function Necrosis_ChangeDemon()
	-- If the new demon is enslaved, start a five-minute timer
	if Necrosis_UnitHasEffect("pet", NECROSIS_SPELL_TABLE[10].Name) then
		if not DemonEnslaved then
			DemonEnslaved = true
			SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(10, nil, nil, nil, nil, nil, SpellTimer, TimerTable)
		end
	else
		-- When the enslaved demon breaks free, remove the timer and warn the Warlock
		if DemonEnslaved then
			DemonEnslaved = false
			SpellTimer, TimerTable = Necrosis_RemoveTimerByName(NECROSIS_SPELL_TABLE[10].Name, SpellTimer, TimerTable)
			if NecrosisConfig.Sound then
				PlaySoundFile(NECROSIS_SOUND.EnslaveEnd)
			end
			Necrosis_Msg(NECROSIS_MESSAGE.Information.EnslaveBreak, "USER")
		end
	end

	-- If the demon is not enslaved, assign its title and update its name in Necrosis
	DemonType = UnitCreatureFamily("pet")
	for i = 1, 4, 1 do
		if
			DemonType == NECROSIS_PET_LOCAL_NAME[i]
			and NecrosisConfig.PetName[i] == " "
			and UnitName("pet") ~= UNKNOWNOBJECT
		then
			NecrosisConfig.PetName[i] = UnitName("pet")
			NecrosisLocalization()
			break
		end
	end

	return
end

-- events: CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS, CHAT_MSG_SPELL_AURA_GONE_SELF, and CHAT_MSG_SPELL_BREAK_AURA
-- Handles buffs and debuffs appearing on the Warlock
-- Based on the combat log
function Necrosis_SelfEffect(action)
	Necrosis_DebugPrint("SelfEffect", action, arg1 or "nil")
	if action == "BUFF" then
		-- Insert a timer when the Warlock gains Demon Sacrifice
		if arg1 == NECROSIS_TRANSLATION.SacrificeGain then
			SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(17, nil, nil, nil, nil, nil, SpellTimer, TimerTable)
		end
		-- Update the mount button when the Warlock mounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			NecrosisMounted = true
			if
				NecrosisConfig.SteedSummon
				and NecrosisTellMounted
				and NecrosisConfig.ChatMsg
				and NECROSIS_PET_MESSAGE[6]
				and not NecrosisConfig.SM
			then
				local mountMessages = NECROSIS_PET_MESSAGE[6]
				local messageCount = table.getn(mountMessages)
				if messageCount > 0 then
					local tempnum = random(1, messageCount)
					if messageCount >= 2 then
						while tempnum == SteedMess do
							tempnum = random(1, messageCount)
						end
					end
					SteedMess = tempnum
					local lines = mountMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY")
					end
					NecrosisTellMounted = false
				end
			end
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 2)
		end
		-- Update the Corrupted Domination button when active and start the cooldown timer
		if string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = true
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 2)
		end
		-- Update the Amplify Curse button when active and start the cooldown timer
		if string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = true
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 2)
		end
		-- Track Demon Armor/Skin on the player
		local playerName = UnitName("player") or ""
		if NECROSIS_SPELL_TABLE[31].Name and string.find(arg1, NECROSIS_SPELL_TABLE[31].Name) then
			local skip = Necrosis_WasBuffRecentlyRefreshed(NECROSIS_SPELL_TABLE[31].Name)
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("SelfEffect", "Demon Armor aura", "skip=", skip)
			end
			if not skip then
				SpellTimer, TimerTable =
					Necrosis_EnsureSpellIndexTimer(31, playerName, nil, nil, nil, nil, SpellTimer, TimerTable)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Armor timer (log)")
				end
			end
			LastRefreshedBuffName = nil
		elseif NECROSIS_SPELL_TABLE[36].Name and string.find(arg1, NECROSIS_SPELL_TABLE[36].Name) then
			local skip = Necrosis_WasBuffRecentlyRefreshed(NECROSIS_SPELL_TABLE[36].Name)
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("SelfEffect", "Demon Skin aura", "skip=", skip)
			end
			if not skip then
				SpellTimer, TimerTable =
					Necrosis_EnsureSpellIndexTimer(36, playerName, nil, nil, nil, nil, SpellTimer, TimerTable)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Skin timer (log)")
				end
			end
			LastRefreshedBuffName = nil
		else
			local trackedConfig = Necrosis_FindTrackedBuffConfigByName(arg1)
			if trackedConfig and not trackedConfig.spellIndex then
				Necrosis_RefreshSelfBuffTimer(trackedConfig, playerName, GetTime())
				LastRefreshedBuffName = nil
			end
		end
	else
		-- Update the mount button when the Warlock dismounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			NecrosisMounted = false
			NecrosisTellMounted = true
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
		end
		-- Change the Domination button when the Warlock is no longer under its effect
		if string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = false
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
		-- Change the Amplify Curse button when the Warlock leaves its effect
		if string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = false
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
		end
		-- Remove tracked buff timers when they fade
		if not Necrosis_RemoveTrackedBuffTimerForMessage(arg1) then
			if NECROSIS_SPELL_TABLE[31].Name and string.find(arg1, NECROSIS_SPELL_TABLE[31].Name) then
				SpellTimer, TimerTable =
					Necrosis_RemoveTimerByName(NECROSIS_SPELL_TABLE[31].Name, SpellTimer, TimerTable)
			elseif NECROSIS_SPELL_TABLE[36].Name and string.find(arg1, NECROSIS_SPELL_TABLE[36].Name) then
				SpellTimer, TimerTable =
					Necrosis_RemoveTimerByName(NECROSIS_SPELL_TABLE[36].Name, SpellTimer, TimerTable)
			end
		end
	end
	return
end

-- event : SPELLCAST_STOP
-- Handles everything related to spells after they finish casting
function Necrosis_SpellManagement()
	local SortActif = false
	Necrosis_DebugPrint(
		"Necrosis_SpellManagement",
		"SpellCastName=",
		SpellCastName or "nil",
		"Target=",
		SpellTargetName or "nil"
	)
	if SpellCastName then
		-- If the spell was Soulstone Resurrection, start its timer
		if SpellCastName == NECROSIS_SPELL_TABLE[11].Name then
			if SpellTargetName == UnitName("player") then
				SpellTargetName = ""
			end
			-- If messaging is enabled and the stone is used on the targeted player, broadcast the alert!
			if (NecrosisConfig.ChatMsg or NecrosisConfig.SM) and SoulstoneUsedOnTarget then
				SoulstoneTarget = SpellTargetName
				SoulstoneAdvice = true
			end
			SpellTimer, TimerTable =
				Necrosis_EnsureSpellIndexTimer(11, SpellTargetName, nil, nil, nil, nil, SpellTimer, TimerTable)
		-- If the spell was Ritual of Summoning, send an informational message to players
		elseif
			(SpellCastName == NECROSIS_TRANSLATION.SummoningRitual)
			and (NecrosisConfig.ChatMsg or NecrosisConfig.SM)
			and NecrosisConfig.RitualMessage
			and NECROSIS_INVOCATION_MESSAGES
		then
			local ritualMessages = NECROSIS_INVOCATION_MESSAGES
			local ritualCount = table.getn(ritualMessages)
			if ritualCount > 0 then
				local tempnum = random(1, ritualCount)
				if ritualCount >= 2 then
					while tempnum == TPMess do
						tempnum = random(1, ritualCount)
					end
				end
				TPMess = tempnum
				local lines = ritualMessages[tempnum]
				local lineCount = table.getn(lines)
				for i = 1, lineCount, 1 do
					Necrosis_Msg(Necrosis_MsgReplace(lines[i], SpellTargetName), "WORLD")
				end
			end
		elseif StoneIDInSpellTable[5] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Name then -- Create Felstone
			LastCast.Stone.id = 1
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[6] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Name then -- Create Wrathstone
			LastCast.Stone.id = 2
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[7] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Name then -- Create Voidstone
			LastCast.Stone.id = 3
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[4] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Name then -- Create Firestone
			LastCast.Stone.id = 4
			LastCast.Stone.click = "LeftButton"
		-- For other spells, attempt to create a timer if applicable
		elseif SpellCastName == NECROSIS_SPELL_TABLE[31].Name or SpellCastName == NECROSIS_SPELL_TABLE[36].Name then
			local playerName = UnitName("player") or ""
			local spellIndex = SpellCastName == NECROSIS_SPELL_TABLE[31].Name and 31 or 36
			local duration = NECROSIS_SPELL_TABLE[spellIndex].Length or 0
			local expiry = floor(GetTime() + duration)
			local updated = false
			if type(Necrosis_UpdateTimerEntry) == "function" then
				updated, SpellTimer = Necrosis_UpdateTimerEntry(
					SpellTimer,
					SpellCastName,
					playerName,
					duration,
					expiry,
					NECROSIS_SPELL_TABLE[spellIndex].Type
				)
			end
			if not updated then
				SpellTimer, TimerTable =
					Necrosis_EnsureSpellIndexTimer(spellIndex, playerName, nil, nil, nil, nil, SpellTimer, TimerTable)
			elseif DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("Timer refreshed", SpellCastName, duration)
			end
		else
			for spell = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if SpellCastName == NECROSIS_SPELL_TABLE[spell].Name and not (spell == 10) then
					-- If the timer already exists on the target, refresh it
					for thisspell = 1, table.getn(SpellTimer), 1 do
						if
							SpellTimer[thisspell].Name == SpellCastName
							and SpellTimer[thisspell].Target == SpellTargetName
							and NECROSIS_SPELL_TABLE[spell].Type ~= 4
							and spell ~= 16
						then
							-- If the spell is already active on the mob, reset its timer
							if spell ~= 9 or (spell == 9 and not Necrosis_UnitHasEffect("target", SpellCastName)) then
								SpellTimer[thisspell].Time = NECROSIS_SPELL_TABLE[spell].Length
								SpellTimer[thisspell].TimeMax = floor(GetTime() + NECROSIS_SPELL_TABLE[spell].Length)
								if spell == 9 and SpellCastRank == 1 then
									SpellTimer[thisspell].Time = 20
									SpellTimer[thisspell].TimeMax = floor(GetTime() + 20)
								end
							end
							SortActif = true
							break
						end
						-- If Banish hits a new target, remove the previous timer
						if
							SpellTimer[thisspell].Name == SpellCastName
							and spell == 9
							and (SpellTimer[thisspell].Target ~= SpellTargetName)
						then
							SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(thisspell, SpellTimer, TimerTable)
							SortActif = false
							break
						end

						-- If it is a fear, remove the previous fear timer
						if SpellTimer[thisspell].Name == SpellCastName and spell == 13 then
							SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(thisspell, SpellTimer, TimerTable)
							SortActif = false
							break
						end
						if SortActif then
							break
						end
					end
					-- If the timer is for a curse, remove the previous curse timer on the target
					if (NECROSIS_SPELL_TABLE[spell].Type == 4) or (spell == 16) then
						for thisspell = 1, table.getn(SpellTimer), 1 do
							-- But keep the Curse of Doom cooldown
							if SpellTimer[thisspell].Name == NECROSIS_SPELL_TABLE[16].Name then
								SpellTimer[thisspell].Target = ""
							end
							if SpellTimer[thisspell].Type == 4 and SpellTimer[thisspell].Target == SpellTargetName then
								SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(thisspell, SpellTimer, TimerTable)
								break
							end
						end
						SortActif = false
					end
					if not SortActif and NECROSIS_SPELL_TABLE[spell].Type ~= 0 and spell ~= 10 then
						if spell == 9 then
							if SpellCastRank == 1 then
								NECROSIS_SPELL_TABLE[spell].Length = 20
							else
								NECROSIS_SPELL_TABLE[spell].Length = 30
							end
						end

						SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(
							spell,
							SpellTargetName,
							nil,
							nil,
							nil,
							nil,
							SpellTimer,
							TimerTable
						)
						break
					end
				end
			end
		end
	end
	SpellCastName = nil
	SpellCastRank = nil
	return
end

------------------------------------------------------------------------------------------------------
-- INTERFACE FUNCTIONS -- XML LINKS
------------------------------------------------------------------------------------------------------

-- Right-clicking Necrosis toggles both configuration panels
function Necrosis_Toggle(button)
	if button == "LeftButton" then
		if NECROSIS_SPELL_TABLE[41].ID then
			CastSpell(NECROSIS_SPELL_TABLE[41].ID, "spell")
		end
		return
	elseif NecrosisGeneralFrame:IsVisible() then
		HideUIPanel(NecrosisGeneralFrame)
		return
	else
		if NecrosisConfig.SM then
			Necrosis_Msg("!!! Short Messages : <brightGreen>On", "USER")
		end
		ShowUIPanel(NecrosisGeneralFrame)
		NecrosisGeneralTab_OnClick(1)
		return
	end
end

-- Function that lets Necrosis elements be moved on screen
function Necrosis_OnDragStart(button)
	if button == "NecrosisIcon" then
		GameTooltip:Hide()
	end
	button:StartMoving()
end

-- Function that stops moving Necrosis elements on screen
function Necrosis_OnDragStop(button)
	if button == "NecrosisIcon" then
		Necrosis_BuildTooltip("OVERALL")
	end
	button:StopMovingOrSizing()
end

-- Function that toggles between graphical and text timers
function Necrosis_HideGraphTimer()
	for i = 1, 50, 1 do
		local elements = { "Text", "Bar", "Texture", "OutText" }
		if NecrosisConfig.Graphical then
			if TimerTable[i] then
				for j = 1, 4, 1 do
					frameName = "NecrosisTimer" .. i .. elements[j]
					frameItem = getglobal(frameName)
					frameItem:Show()
				end
			end
		else
			for j = 1, 4, 1 do
				frameName = "NecrosisTimer" .. i .. elements[j]
				frameItem = getglobal(frameName)
				frameItem:Hide()
			end
		end
	end
end

-- Function that manages tooltips
function Necrosis_BuildTooltip(button, type, anchor)
	-- If tooltips are disabled, exit immediately!
	if not NecrosisConfig.NecrosisToolTip then
		return
	end

	-- Check whether Fel Domination, Shadow Ward, or Curse Amplification are active (for tooltips)
	local start, duration, start2, duration2, start3, duration3
	if NECROSIS_SPELL_TABLE[15].ID then
		start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, BOOKTYPE_SPELL)
	else
		start = 1
		duration = 1
	end
	if NECROSIS_SPELL_TABLE[43].ID then
		start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, BOOKTYPE_SPELL)
	else
		start2 = 1
		duration2 = 1
	end
	if NECROSIS_SPELL_TABLE[42].ID then
		start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, BOOKTYPE_SPELL)
	else
		start3 = 1
		duration3 = 1
	end

	-- Create the tooltips....
	GameTooltip:SetOwner(button, anchor)
	GameTooltip:SetText(NecrosisTooltipData[type].Label)
	-- ..... for the main button
	if type == "Main" then
		GameTooltip:AddLine(NecrosisTooltipData.Main.Soulshard .. SoulshardState.count)
		GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone .. InfernalStone)
		GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone .. DemoniacStone)
		GameTooltip:AddLine(
			NecrosisTooltipData.Main.Soulstone .. NecrosisTooltipData[type].Stone[StoneInventory.Soulstone.onHand]
		)
		GameTooltip:AddLine(
			NecrosisTooltipData.Main.Healthstone .. NecrosisTooltipData[type].Stone[StoneInventory.Healthstone.onHand]
		)
		-- Display the demon's name, show if it is enslaved, or "None" when no demon is present
		if DemonType then
			GameTooltip:AddLine(NecrosisTooltipData.Main.CurrentDemon .. DemonType)
		elseif DemonEnslaved then
			GameTooltip:AddLine(NecrosisTooltipData.Main.EnslavedDemon)
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.NoCurrentDemon)
		end
	-- ..... for the stone buttons
	elseif string.find(type, "stone") then
		-- Soulstone
		if type == "Soulstone" then
			-- On affiche le nom de la pierre et l'action que produira le clic sur le bouton
			-- Also grab the cooldown
			if StoneInventory.Soulstone.mode == 1 or StoneInventory.Soulstone.mode == 3 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText())
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Soulstone.mode])
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		-- Pierre de vie
		elseif type == "Spellstone" then
			-- Idem
			if StoneInventory.Spellstone.mode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Spellstone.mode])
			local itemName = tostring(NecrosisTooltipTextLeft7:GetText())
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		elseif type == "Healthstone" then
			-- Idem
			if StoneInventory.Healthstone.mode == 1 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText())
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Healthstone.mode])
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		-- Pierre de feu
		elseif type == "Firestone" then
			local stoneMode = StoneInventory.Firestone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[4] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Firestone.onHand and StoneInventory.Firestone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Firestone.location[1], StoneInventory.Firestone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Felstone" then
			local stoneMode = StoneInventory.Felstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[5] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Felstone.onHand and StoneInventory.Felstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Felstone.location[1], StoneInventory.Felstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Wrathstone" then
			local stoneMode = StoneInventory.Wrathstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[6] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Wrathstone.onHand and StoneInventory.Wrathstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Wrathstone.location[1], StoneInventory.Wrathstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Voidstone" then
			local stoneMode = StoneInventory.Voidstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[7] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Voidstone.onHand and StoneInventory.Voidstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Voidstone.location[1], StoneInventory.Voidstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		end
	-- ..... for the timer button
	elseif type == "SpellTimer" then
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetBagItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		local itemName = tostring(NecrosisTooltipTextLeft5:GetText())
		GameTooltip:AddLine(NecrosisTooltipData[type].Text)
		if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
			GameTooltip:AddLine(NECROSIS_TRANSLATION.Hearth .. " - " .. itemName)
		else
			GameTooltip:AddLine(NecrosisTooltipData[type].Right .. GetBindLocation())
		end

	-- ..... for the Shadow Trance button
	elseif type == "ShadowTrance" then
		local rank = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "Rank")
		GameTooltip:SetText(NecrosisTooltipData[type].Label .. "          |CFF808080Rank " .. rank .. "|r")
	-- ..... for the other buffs and demons, the mana cost...
	elseif type == "Enslave" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[35].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		end
	elseif type == "Mount" then
		if NECROSIS_SPELL_TABLE[2].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[2].Mana .. " Mana")
		elseif NECROSIS_SPELL_TABLE[1].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[1].Mana .. " Mana")
		end
	elseif type == "Armor" then
		if NECROSIS_SPELL_TABLE[31].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[31].Mana .. " Mana")
		else
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[36].Mana .. " Mana")
		end
	elseif type == "Invisible" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[33].Mana .. " Mana")
	elseif type == "Aqua" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[32].Mana .. " Mana")
	elseif type == "Kilrogg" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[34].Mana .. " Mana")
	elseif type == "Banish" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[9].Mana .. " Mana")
	elseif type == "Weakness" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[23].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Agony" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[22].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Reckless" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[24].Mana .. " Mana")
	elseif type == "Tongues" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[25].Mana .. " Mana")
	elseif type == "Exhaust" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[40].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Elements" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[26].Mana .. " Mana")
	elseif type == "Shadow" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[27].Mana .. " Mana")
	elseif type == "Doom" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[16].Mana .. " Mana")
	elseif type == "Amplify" then
		if start3 > 0 and duration3 > 0 then
			local seconde = duration3 - (GetTime() - start3)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)) .. " sec"
			else
				minute = tostring(floor(seconde / 60))
				seconde = mod(seconde, 60)
				if seconde <= 9 then
					time = "0" .. tostring(floor(seconde))
				else
					time = tostring(floor(seconde))
				end
				affiche = minute .. ":" .. time
			end
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "TP" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[37].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		end
	elseif type == "SoulLink" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[38].Mana .. " Mana")
	elseif type == "ShadowProtection" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[43].Mana .. " Mana")
		if start2 > 0 and duration2 > 0 then
			local seconde = duration2 - (GetTime() - start2)
			local affiche
			affiche = tostring(floor(seconde)) .. " sec"
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "Domination" then
		if start > 0 and duration > 0 then
			local seconde = duration - (GetTime() - start)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)) .. " sec"
			else
				minute = tostring(floor(seconde / 60))
				seconde = mod(seconde, 60)
				if seconde <= 9 then
					time = "0" .. tostring(floor(seconde))
				else
					time = tostring(floor(seconde))
				end
				affiche = minute .. ":" .. time
			end
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "Imp" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[3].Mana .. " Mana")
		if not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Void" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[4].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Succubus" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[5].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Fel" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[6].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Infernal" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[8].Mana .. " Mana")
		if InfernalStone == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.InfernalStone .. InfernalStone .. "|r")
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone .. InfernalStone)
		end
	elseif type == "Doomguard" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[30].Mana .. " Mana")
		if DemoniacStone == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.DemoniacStone .. DemoniacStone .. "|r")
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone .. DemoniacStone)
		end
	elseif (type == "Buff") and LastCast.Buff ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_SPELL_TABLE[LastCast.Buff].Name)
	elseif (type == "Curse") and LastCast.Curse.id ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_SPELL_TABLE[LastCast.Curse.id].Name)
	elseif (type == "Pet") and LastCast.Demon ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_PET_LOCAL_NAME[(LastCast.Demon - 2)])
	elseif (type == "Stone") and LastCast.Stone.id ~= 0 then
		local stoneName = ""
		local stoneOnHand = false
		if LastCast.Stone.id == 1 and StoneInventory.Felstone.onHand then
			stoneName = NECROSIS_ITEM.Felstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 2 and StoneInventory.Wrathstone.onHand then
			stoneName = NECROSIS_ITEM.Wrathstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 3 and StoneInventory.Voidstone.onHand then
			stoneName = NECROSIS_ITEM.Voidstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 4 and StoneInventory.Firestone.onHand then
			stoneName = NECROSIS_ITEM.Firestone
			stoneOnHand = true
		end
		if stoneOnHand then
			GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. stoneName)
		end
	end
	-- And tada, show it!
	GameTooltip:Show()
end

-- Function that refreshes Necrosis buttons and reports Soulstone button state
function Necrosis_UpdateIcons()
	local mana = UnitMana("player")

	if LastCast.Stone.id == 0 then
		if StoneInventory.Felstone.onHand then
			LastCast.Stone.id = 1
		elseif StoneInventory.Wrathstone.onHand then
			LastCast.Stone.id = 2
		elseif StoneInventory.Voidstone.onHand then
			LastCast.Stone.id = 3
		elseif StoneInventory.Firestone.onHand then
			LastCast.Stone.id = 4
		end
	end

	if LastCast.Stone.id == 1 and StoneInventory.Felstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Felstone", 2)
	elseif LastCast.Stone.id == 2 and StoneInventory.Wrathstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Wrathstone", 2)
	elseif LastCast.Stone.id == 3 and StoneInventory.Voidstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Voidstone", 2)
	elseif LastCast.Stone.id == 4 and StoneInventory.Firestone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "FirestoneButton", 2)
	else
		NecrosisStoneMenuButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-01")
	end

	-- Soulstone
	-----------------------------------------------

	-- Determine whether a Soulstone was used by checking timers
	local SoulstoneInUse = false
	if SpellTimer then
		for index = 1, table.getn(SpellTimer), 1 do
			if (SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name) and SpellTimer[index].TimeMax > 0 then
				SoulstoneInUse = true
				break
			end
		end
	end

	-- If the stone was not used and none are in the inventory -> mode 1
	if not (StoneInventory.Soulstone.onHand or SoulstoneInUse) then
		StoneInventory.Soulstone.mode = 1
		SoulstoneWaiting = false
		SoulstoneCooldown = false
	end

	-- If the stone was not used and one is in the inventory
	if StoneInventory.Soulstone.onHand and not SoulstoneInUse then
		-- If the stone in the inventory still has a timer and we just relogged --> mode 4
		local start, duration =
			GetContainerItemCooldown(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
		if NecrosisRL and start > 0 and duration > 0 then
			local timeRemaining = floor(duration - GetTime() + start)
			if timeRemaining > 0 then
				local expiry = floor(start + duration)
				SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(
					11,
					"???",
					timeRemaining,
					NECROSIS_SPELL_TABLE[11].Type,
					timeRemaining,
					expiry,
					SpellTimer,
					TimerTable
				)
			end
			StoneInventory.Soulstone.mode = 4
			NecrosisRL = false
			SoulstoneWaiting = false
			SoulstoneCooldown = true
		-- If the stone has no timer or we didn't just relog --> mode 2
		else
			StoneInventory.Soulstone.mode = 2
			NecrosisRL = false
			SoulstoneWaiting = false
			SoulstoneCooldown = false
		end
	end

	-- If the stone was consumed and none remain in the inventory --> mode 3
	if (not StoneInventory.Soulstone.onHand) and SoulstoneInUse then
		StoneInventory.Soulstone.mode = 3
		SoulstoneWaiting = true
		-- If the stone was just applied, announce it to the raid
		if SoulstoneAdvice and NECROSIS_SOULSTONE_ALERT_MESSAGE then
			local alertMessages = NECROSIS_SOULSTONE_ALERT_MESSAGE
			local alertCount = table.getn(alertMessages)
			if alertCount > 0 then
				local tempnum = random(1, alertCount)
				if alertCount >= 2 then
					while tempnum == RezMess do
						tempnum = random(1, alertCount)
					end
				end
				RezMess = tempnum
				local lines = alertMessages[tempnum]
				local lineCount = table.getn(lines)
				for i = 1, lineCount, 1 do
					Necrosis_Msg(Necrosis_MsgReplace(lines[i], SoulstoneTarget), "WORLD")
				end
				SoulstoneAdvice = false
			end
		end
	end

	-- If the stone was consumed but another is in the inventory
	if StoneInventory.Soulstone.onHand and SoulstoneInUse then
		SoulstoneAdvice = false
		if not (SoulstoneWaiting or SoulstoneCooldown) then
			SpellTimer, TimerTable = Necrosis_RemoveTimerByName(NECROSIS_SPELL_TABLE[11].Name, SpellTimer, TimerTable)
			StoneInventory.Soulstone.mode = 2
		else
			SoulstoneWaiting = false
			SoulstoneCooldown = true
			StoneInventory.Soulstone.mode = 4
		end
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisSoulstoneButton, "SoulstoneButton", StoneInventory.Soulstone.mode)

	-- Pierre de sort
	-----------------------------------------------

	if StoneInventory.Spellstone.onHand then
		StoneInventory.Spellstone.mode = 2
	else
		StoneInventory.Spellstone.mode = 1
	end

	Necrosis_SetButtonTexture(NecrosisSpellstoneButton, "SpellstoneButton", StoneInventory.Spellstone.mode)

	-- Pierre de vie
	-----------------------------------------------

	-- Mode "j'en ai une" (2) / "j'en ai pas" (1)
	if StoneInventory.Healthstone.onHand then
		StoneInventory.Healthstone.mode = 2
	else
		StoneInventory.Healthstone.mode = 1
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisHealthstoneButton, "HealthstoneButton", StoneInventory.Healthstone.mode)

	-- Demon button
	-----------------------------------------------
	local ManaPet = { "3", "3", "3", "3", "3", "3" }

	-- Si cooldown de domination corrompue on grise
	if NECROSIS_SPELL_TABLE[15].ID and not DominationUp then
		local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell")
		if start > 0 and duration > 0 then
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 1)
		else
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
	end

	-- Si cooldown de gardien de l'ombre on grise
	if NECROSIS_SPELL_TABLE[43].ID then
		local start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, "spell")
		if start2 > 0 and duration2 > 0 then
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
		else
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
		end
	end

	-- Gray out the button while Amplify Curse is on cooldown
	if NECROSIS_SPELL_TABLE[42].ID and not AmplifyUp then
		local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell")
		if start3 > 0 and duration3 > 0 then
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 1)
		else
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
		end
	end

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if NECROSIS_SPELL_TABLE[3].ID then
			if NECROSIS_SPELL_TABLE[3].Mana > mana then
				for i = 1, 6, 1 do
					ManaPet[i] = "1"
				end
			elseif NECROSIS_SPELL_TABLE[4].ID then
				if NECROSIS_SPELL_TABLE[4].Mana > mana then
					for i = 2, 6, 1 do
						ManaPet[i] = "1"
					end
				elseif NECROSIS_SPELL_TABLE[8].ID then
					if NECROSIS_SPELL_TABLE[8].Mana > mana then
						for i = 5, 6, 1 do
							ManaPet[i] = "1"
						end
					elseif NECROSIS_SPELL_TABLE[30].ID then
						if NECROSIS_SPELL_TABLE[30].Mana > mana then
							ManaPet[6] = "1"
						end
					end
				end
			end
		end
	end

	-- Grey out the button when no stone is available for the summon
	if SoulshardState.count == 0 then
		for i = 2, 4, 1 do
			ManaPet[i] = "1"
		end
	end
	if InfernalStone == 0 then
		ManaPet[5] = "1"
	end
	if DemoniacStone == 0 then
		ManaPet[6] = "1"
	end

	-- Apply textures to the pet buttons
	if DemonType == NECROSIS_PET_LOCAL_NAME[1] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[2] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[3] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[4] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[5] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[6] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", 2)
	else
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	end

	-- Buff button
	-----------------------------------------------

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if MountAvailable and not NecrosisMounted then
			if NECROSIS_SPELL_TABLE[2].ID then
				if NECROSIS_SPELL_TABLE[2].Mana > mana or PlayerCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			else
				if NECROSIS_SPELL_TABLE[1].Mana > mana or PlayerCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			end
		end
		if NECROSIS_SPELL_TABLE[35].ID then
			if NECROSIS_SPELL_TABLE[35].Mana > mana or SoulshardState.count == 0 then
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 1)
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[31].ID then
			if NECROSIS_SPELL_TABLE[31].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		elseif NECROSIS_SPELL_TABLE[36].ID then
			if NECROSIS_SPELL_TABLE[36].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[32].ID then
			if NECROSIS_SPELL_TABLE[32].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[33].ID then
			if NECROSIS_SPELL_TABLE[33].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[34].ID then
			if NECROSIS_SPELL_TABLE[34].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[37].ID then
			if NECROSIS_SPELL_TABLE[37].Mana > mana or SoulshardState.count == 0 then
				NecrosisBuffMenu5:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\TPButton-05")
			else
				NecrosisBuffMenu5:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\TPButton-01")
			end
		end
		if NECROSIS_SPELL_TABLE[38].ID then
			if NECROSIS_SPELL_TABLE[38].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[43].ID then
			if NECROSIS_SPELL_TABLE[43].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[9].ID then
			if NECROSIS_SPELL_TABLE[9].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[44].ID then
			if not UnitExists("Pet") then
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 1)
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 3)
			end
		end
	end

	-- Curse button
	-----------------------------------------------

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if NECROSIS_SPELL_TABLE[23].ID then
			if NECROSIS_SPELL_TABLE[23].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[22].ID then
			if NECROSIS_SPELL_TABLE[22].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[24].ID then
			if NECROSIS_SPELL_TABLE[24].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[25].ID then
			if NECROSIS_SPELL_TABLE[25].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[40].ID then
			if NECROSIS_SPELL_TABLE[40].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[26].ID then
			if NECROSIS_SPELL_TABLE[26].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[27].ID then
			if NECROSIS_SPELL_TABLE[27].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[16].ID then
			if NECROSIS_SPELL_TABLE[16].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 3)
			end
		end
	end

	-- Timer button
	-----------------------------------------------
	if StoneInventory.Hearthstone.location[1] then
		local start, duration, enable =
			GetContainerItemCooldown(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		if duration > 20 and start > 0 then
			NecrosisSpellTimerButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Cooldown")
		else
			NecrosisSpellTimerButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Normal")
		end
	end
end

------------------------------------------------------------------------------------------------------
-- STONE AND SHARD FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Remember where you stored your belongings!
function Necrosis_SoulshardSetup()
	SoulshardState.nextSlotIndex = 1
	for key in pairs(SoulshardState.slots) do
		SoulshardState.slots[key] = nil
	end
	local slotCount = GetContainerNumSlots(NecrosisConfig.SoulshardContainer)
	for slot = 1, slotCount, 1 do
		SoulshardState.slots[slot] = nil
	end
end

-- Function that inventories demonology items: stones, shards, summoning reagents

function Necrosis_BagExplore()
	local soulshards = SoulshardState.count
	SoulshardState.count = 0
	InfernalStone = 0
	DemoniacStone = 0
	StoneInventory.Soulstone.onHand = false
	StoneInventory.Healthstone.onHand = false
	StoneInventory.Firestone.onHand = false
	StoneInventory.Spellstone.onHand = false
	StoneInventory.Felstone.onHand = false
	StoneInventory.Wrathstone.onHand = false
	StoneInventory.Voidstone.onHand = false
	StoneInventory.Hearthstone.onHand = false
	StoneInventory.Itemswitch.onHand = false
	-- Parcours des sacs
	SoulshardState.container = NecrosisConfig.SoulshardContainer
	for container = 0, 4, 1 do
		-- Parcours des emplacements des sacs
		for slot = 1, GetContainerNumSlots(container), 1 do
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(container, slot)
			local itemName = tostring(NecrosisTooltipTextLeft1:GetText())
			local itemSwitch = tostring(NecrosisTooltipTextLeft3:GetText())
			local itemSwitch2 = tostring(NecrosisTooltipTextLeft4:GetText())
			-- If this bag is marked as the shard container
			-- set the bag slot table entry to nil (no shard present)
			if container == NecrosisConfig.SoulshardContainer then
				if itemName ~= NECROSIS_ITEM.Soulshard then
					SoulshardState.slots[slot] = nil
				end
			end
			-- When the slot is not empty
			if itemName then
				-- On prend le nombre d'item en stack sur le slot
				local _, ItemCount = GetContainerItemInfo(container, slot)
				-- If it's a shard or infernal stone, add its quantity to the stone count
				if itemName == NECROSIS_ITEM.Soulshard then
					SoulshardState.count = SoulshardState.count + ItemCount
				end
				if itemName == NECROSIS_ITEM.InfernalStone then
					InfernalStone = InfernalStone + ItemCount
				end
				if itemName == NECROSIS_ITEM.DemoniacStone then
					DemoniacStone = DemoniacStone + ItemCount
				end
				for _, stoneKey in ipairs(STONE_ITEM_KEYS) do
					local pattern = NECROSIS_ITEM[stoneKey]
					-- Ranked stones include the size in their item name (e.g. "Major Healthstone"), so use a literal substring match
					if pattern and string.find(itemName, pattern, 1, true) then
						Necrosis_RecordStoneInventory(stoneKey, container, slot)
						break
					end
				end

				-- Also track whether off-hand items are present
				-- Later this will be used to automatically replace a missing stone
				if itemSwitch == NECROSIS_ITEM.Offhand or itemSwitch2 == NECROSIS_ITEM.Offhand then
					Necrosis_RecordStoneInventory("Itemswitch", container, slot)
				end
			end
		end
	end

	-- Affichage du bouton principal de Necrosis
	if NecrosisConfig.Circle == 1 then
		if SoulshardState.count <= 32 then
			NecrosisButton:SetNormalTexture(
				"Interface\\AddOns\\Necrosis\\UI\\" .. NecrosisConfig.NecrosisColor .. "\\Shard" .. SoulshardState.count
			)
		else
			NecrosisButton:SetNormalTexture(
				"Interface\\AddOns\\Necrosis\\UI\\" .. NecrosisConfig.NecrosisColor .. "\\Shard32"
			)
		end
	elseif StoneInventory.Soulstone.mode == 1 or StoneInventory.Soulstone.mode == 2 then
		if SoulshardState.count <= 32 then
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard" .. SoulshardState.count)
		else
			NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard32")
		end
	end
	if NecrosisConfig.ShowCount then
		if NecrosisConfig.CountType == 2 then
			NecrosisShardCount:SetText(InfernalStone .. " / " .. DemoniacStone)
		elseif NecrosisConfig.CountType == 1 then
			if SoulshardState.count < 10 then
				NecrosisShardCount:SetText("0" .. SoulshardState.count)
			else
				NecrosisShardCount:SetText(SoulshardState.count)
			end
		end
	else
		NecrosisShardCount:SetText("")
	end
	-- And update all of it!
	Necrosis_UpdateIcons()

	-- If the shard bag is full, display a warning
	if
		SoulshardState.count > soulshards
		and SoulshardState.count == GetContainerNumSlots(NecrosisConfig.SoulshardContainer)
	then
		if SoulshardDestroy then
			Necrosis_Msg(
				NECROSIS_MESSAGE.Bag.FullPrefix
					.. GetBagName(NecrosisConfig.SoulshardContainer)
					.. NECROSIS_MESSAGE.Bag.FullDestroySuffix
			)
		else
			Necrosis_Msg(
				NECROSIS_MESSAGE.Bag.FullPrefix
					.. GetBagName(NecrosisConfig.SoulshardContainer)
					.. NECROSIS_MESSAGE.Bag.FullSuffix
			)
		end
	end
end

-- Function that locates and tidies shards inside bags
function Necrosis_SoulshardSwitch(type)
	if type == "CHECK" then
		SoulshardState.pendingMoves = 0
		for container = 0, 4, 1 do
			for i = 1, 3, 1 do
				if GetBagName(container) == NECROSIS_ITEM.SoulPouch[i] then
					BagIsSoulPouch[container + 1] = true
					break
				else
					BagIsSoulPouch[container + 1] = false
				end
			end
		end
	end
	for container = 0, 4, 1 do
		if BagIsSoulPouch[container + 1] then
			break
		end
		if container ~= NecrosisConfig.SoulshardContainer then
			for slot = 1, GetContainerNumSlots(container), 1 do
				Necrosis_MoneyToggle()
				NecrosisTooltip:SetBagItem(container, slot)
				local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText())
				if itemInfo == NECROSIS_ITEM.Soulshard then
					if type == "CHECK" then
						SoulshardState.pendingMoves = SoulshardState.pendingMoves + 1
					elseif type == "MOVE" then
						Necrosis_FindSlot(container, slot)
						SoulshardState.pendingMoves = SoulshardState.pendingMoves - 1
					end
				end
			end
		end
	end
	if type == "MOVE" then
		SoulshardState.nextSlotIndex = 1
		for key in pairs(SoulshardState.slots) do
			SoulshardState.slots[key] = nil
		end
	end

	-- After moving everything we need to find new slots for stones and so on...
	Necrosis_BagExplore()
end

-- While moving shards, find new slots for the displaced items :)
function Necrosis_FindSlot(shardIndex, shardSlot)
	local full = true
	for slot = 1, GetContainerNumSlots(NecrosisConfig.SoulshardContainer), 1 do
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetBagItem(NecrosisConfig.SoulshardContainer, slot)
		local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(itemInfo, NECROSIS_ITEM.Soulshard) == nil then
			PickupContainerItem(shardIndex, shardSlot)
			PickupContainerItem(NecrosisConfig.SoulshardContainer, slot)
			SoulshardState.slots[SoulshardState.nextSlotIndex] = slot
			SoulshardState.nextSlotIndex = SoulshardState.nextSlotIndex + 1
			if CursorHasItem() then
				if shardIndex == 0 then
					PutItemInBackpack()
				else
					PutItemInBag(19 + shardIndex)
				end
			end
			full = false
			break
		end
	end
	-- Destroy excess shards if the option is enabled
	if full and NecrosisConfig.SoulshardDestroy then
		PickupContainerItem(shardIndex, shardSlot)
		if CursorHasItem() then
			DeleteCursorItem()
		end
	end
end

------------------------------------------------------------------------------------------------------
-- SPELL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Show or hide spell buttons each time a new spell is learned
function Necrosis_ButtonSetup()
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_NoDrag()
		Necrosis_UpdateButtonsScale()
	else
		HideUIPanel(NecrosisPetMenuButton)
		HideUIPanel(NecrosisBuffMenuButton)
		HideUIPanel(NecrosisCurseMenuButton)
		HideUIPanel(NecrosisStoneMenuButton)
		HideUIPanel(NecrosisMountButton)
		HideUIPanel(NecrosisSpellstoneButton)
		HideUIPanel(NecrosisHealthstoneButton)
		HideUIPanel(NecrosisSoulstoneButton)
		if NecrosisConfig.StonePosition[StonePos.Healthstone] and StoneIDInSpellTable[2] ~= 0 then
			ShowUIPanel(NecrosisHealthstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Spellstone] and StoneIDInSpellTable[3] ~= 0 then
			ShowUIPanel(NecrosisSpellstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Soulstone] and StoneIDInSpellTable[1] ~= 0 then
			ShowUIPanel(NecrosisSoulstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.BuffMenu] and next(MenuState.Buff.frames) then
			ShowUIPanel(NecrosisBuffMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Mount] and MountAvailable then
			ShowUIPanel(NecrosisMountButton)
		end
		if NecrosisConfig.StonePosition[StonePos.PetMenu] and next(MenuState.Pet.frames) then
			ShowUIPanel(NecrosisPetMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.CurseMenu] and next(MenuState.Curse.frames) then
			ShowUIPanel(NecrosisCurseMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.StoneMenu] and next(MenuState.Stone.frames) then
			ShowUIPanel(NecrosisStoneMenuButton)
		end
	end
end

-- My favorite function! It lists the Warlock's known spells and sorts them by rank.
-- For stones, select the highest known rank
function Necrosis_SpellSetup()
	local StoneType = {
		NECROSIS_ITEM.Soulstone,
		NECROSIS_ITEM.Healthstone,
		NECROSIS_ITEM.Spellstone,
		NECROSIS_ITEM.Firestone,
		NECROSIS_ITEM.Felstone,
		NECROSIS_ITEM.Wrathstone,
		NECROSIS_ITEM.Voidstone,
	}
	local StoneMaxRank = { 0, 0, 0, 0, 0, 0, 0 }

	local CurrentStone = {
		ID = {},
		Name = {},
		subName = {},
	}

	local CurrentSpells = {
		ID = {},
		Name = {},
		subName = {},
	}

	local spellID = 1
	local Invisible = 0
	local InvisibleID = 0

	-- Iterate through every spell the Warlock knows
	while true do
		local spellName, subSpellName = GetSpellName(spellID, BOOKTYPE_SPELL)

		if not spellName then
			do
				break
			end
		end

		-- For spells with numbered ranks, compare each rank one by one
		-- Keep the highest rank
		if string.find(subSpellName, NECROSIS_TRANSLATION.Rank) then
			local found = false
			local rank = tonumber(strsub(subSpellName, 6, strlen(subSpellName)))
			for index = 1, table.getn(CurrentSpells.Name), 1 do
				if CurrentSpells.Name[index] == spellName then
					found = true
					if CurrentSpells.subName[index] < rank then
						CurrentSpells.ID[index] = spellID
						CurrentSpells.subName[index] = rank
					end
					break
				end
			end
			-- Insert the highest ranked version of every numbered spell into the table
			if not found then
				table.insert(CurrentSpells.ID, spellID)
				table.insert(CurrentSpells.Name, spellName)
				table.insert(CurrentSpells.subName, rank)
			end
		end

		-- Test Detect Invisibility's rank
		if spellName == NECROSIS_TRANSLATION.GreaterInvisible then
			Invisible = 3
			InvisibleID = spellID
		elseif spellName == NECROSIS_TRANSLATION.Invisible and Invisible ~= 3 then
			Invisible = 2
			InvisibleID = spellID
		elseif spellName == NECROSIS_TRANSLATION.LesserInvisible and Invisible ~= 3 and Invisible ~= 2 then
			Invisible = 1
			InvisibleID = spellID
		end

		-- Stones do not have numbered ranks; the rank is part of the spell name
		-- Pour chaque type de pierre, on va donc faire....
		for stoneID = 1, table.getn(StoneType), 1 do
			-- If the spell is the summon for this stone type and we have not
			-- and we have not already assigned its maximum rank
			if
				(string.find(spellName, StoneType[stoneID]))
				and StoneMaxRank[stoneID] ~= table.getn(NECROSIS_STONE_RANK)
			then
				-- Extract the end of the stone name that encodes its rank
				local stoneSuffix = string.sub(spellName, string.len(NECROSIS_CREATE[stoneID]) + 1)
				-- Next, find which rank it corresponds to
				for rankID = 1, table.getn(NECROSIS_STONE_RANK), 1 do
					-- If the suffix matches a stone size, record the rank!
					if string.lower(stoneSuffix) == string.lower(NECROSIS_STONE_RANK[rankID]) then
						-- Once we know the stone and its rank, check whether it is the strongest
						-- and if so, record it
						if rankID > StoneMaxRank[stoneID] then
							StoneMaxRank[stoneID] = rankID
							CurrentStone.Name[stoneID] = spellName
							CurrentStone.subName[stoneID] = NECROSIS_STONE_RANK[rankID]
							CurrentStone.ID[stoneID] = spellID
						end
						break
					end
				end
			end
		end

		spellID = spellID + 1
	end

	-- Insert the stones of the highest rank into the table
	for stoneID = 1, table.getn(StoneType), 1 do
		if StoneMaxRank[stoneID] ~= 0 then
			table.insert(NECROSIS_SPELL_TABLE, {
				ID = CurrentStone.ID[stoneID],
				Name = CurrentStone.Name[stoneID],
				Rank = 0,
				CastTime = 0,
				Length = 0,
				Type = 0,
			})
			StoneIDInSpellTable[stoneID] = table.getn(NECROSIS_SPELL_TABLE)
		end
	end
	-- Refresh the spell list with the new ranks
	for spell = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		for index = 1, table.getn(CurrentSpells.Name), 1 do
			if
				(NECROSIS_SPELL_TABLE[spell].Name == CurrentSpells.Name[index])
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[1]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[2]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[3]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[4]
			then
				NECROSIS_SPELL_TABLE[spell].ID = CurrentSpells.ID[index]
				NECROSIS_SPELL_TABLE[spell].Rank = CurrentSpells.subName[index]
			end
		end
	end

	-- Update each spell duration based on its rank
	for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if index == 9 then -- si Bannish
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 10 + 10
			end
		end
		if index == 13 then -- si Fear
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 5 + 5
			end
		end
		if index == 14 then -- si Corruption
			if NECROSIS_SPELL_TABLE[index].ID ~= nil and NECROSIS_SPELL_TABLE[index].Rank <= 2 then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 3 + 9
			end
		end
	end

	for spellID = 1, MAX_SPELLS, 1 do
		local spellName, subSpellName = GetSpellName(spellID, "spell")
		if spellName then
			for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if NECROSIS_SPELL_TABLE[index].Name == spellName then
					Necrosis_MoneyToggle()
					NecrosisTooltip:SetSpell(spellID, 1)
					local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
					if not NECROSIS_SPELL_TABLE[index].ID then
						NECROSIS_SPELL_TABLE[index].ID = spellID
					end
					NECROSIS_SPELL_TABLE[index].Mana = tonumber(ManaCost)
				end
			end
		end
	end
	if NECROSIS_SPELL_TABLE[1].ID or NECROSIS_SPELL_TABLE[2].ID then
		MountAvailable = true
	else
		MountAvailable = false
	end

	-- Insert the highest known rank of Detect Invisibility
	if Invisible >= 1 then
		NECROSIS_SPELL_TABLE[33].ID = InvisibleID
		NECROSIS_SPELL_TABLE[33].Rank = 0
		NECROSIS_SPELL_TABLE[33].CastTime = 0
		NECROSIS_SPELL_TABLE[33].Length = 0
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetSpell(InvisibleID, 1)
		local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
		NECROSIS_SPELL_TABLE[33].Mana = tonumber(ManaCost)
	end
end

-- Function that extracts spell attributes
-- F(type=string, string, int) -> Spell=table
function Necrosis_FindSpellAttribute(type, attribute, array)
	for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if string.find(NECROSIS_SPELL_TABLE[index][type], attribute) then
			return NECROSIS_SPELL_TABLE[index][array]
		end
	end
	return nil
end

-- Function to cast Shadow Bolt from the Shadow Trance button
-- The shard must use the highest rank
function Necrosis_CastShadowBolt()
	local spellID = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "ID")
	if spellID then
		CastSpell(spellID, "spell")
	else
		Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.NoBoltSpell, "USER")
	end
end

------------------------------------------------------------------------------------------------------
-- MISCELLANEOUS FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Function that determines whether a unit is affected by an effect
-- F(string, string)->bool
function Necrosis_UnitHasEffect(unit, effect)
	local index = 1
	while UnitDebuff(unit, index) do
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetUnitDebuff(unit, index)
		local DebuffName = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(DebuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

-- Function to check the presence of a buff on the unit.
-- Strictly identical to UnitHasEffect, but as WoW distinguishes Buff and DeBuff, so we have to.
function Necrosis_UnitHasBuff(unit, effect)
	local index = 1
	while UnitBuff(unit, index) do
		-- Here we'll cheat a little. checking a buff or debuff return the internal spell name, and not the name we give at start
		-- So we use an API widget that will use the internal name to return the known name.
		-- For example, the "Curse of Agony" spell is internaly known as "Spell_Shadow_CurseOfSargeras". Much easier to use the first one than the internal one.
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetUnitBuff(unit, index)
		local BuffName = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(BuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

-- Detects when the player gains Nightfall / Shadow Trance
function Necrosis_UnitHasTrance()
	local ID = -1
	for buffID = 0, 24, 1 do
		local buffTexture = GetPlayerBuffTexture(buffID)
		if buffTexture == nil then
			break
		end
		if strfind(buffTexture, "Spell_Shadow_Twilight") then
			ID = buffID
			break
		end
	end
	ShadowTranceID = ID
end

-- Function handling button click actions for Necrosis
function Necrosis_UseItem(type, button)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetBagItem("player", 17)
	local rightHand = tostring(NecrosisTooltipTextLeft1:GetText())

	-- Function that uses a hearthstone from the inventory
	-- if one is in the inventory and it was a right-click
	if type == "Hearthstone" and button == "RightButton" then
		if StoneInventory.Hearthstone.onHand then
			-- use it
			UseContainerItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		-- or, if none are in the inventory, show an error message
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHearthStone, "USER")
		end
	end

	-- When clicking the Soulstone button
	-- Update the button to indicate the current mode
	if type == "Soulstone" then
		Necrosis_UpdateIcons()
		-- If mode = 2 (stone in inventory, none in use)
		-- alors on l'utilise
		if StoneInventory.Soulstone.mode == 2 then
			-- If a player is targeted, cast on them (with alert message)
			-- If no player is targeted, cast on the Warlock (without a message)
			if UnitIsPlayer("target") then
				SoulstoneUsedOnTarget = true
			else
				SoulstoneUsedOnTarget = false
				TargetUnit("player")
			end
			UseContainerItem(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
			-- Now that timers persist across the session, we no longer reset when relogging
			NecrosisRL = false
			-- And there we go, refresh the button display :)
			Necrosis_UpdateIcons()
		-- if no Soulstone is in the inventory, create the highest-rank Soulstone :)
		elseif (StoneInventory.Soulstone.mode == 1) or (StoneInventory.Soulstone.mode == 3) then
			if StoneIDInSpellTable[1] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSoulStoneSpell, "USER")
			end
		end
	-- When clicking the Healthstone button:
	elseif type == "Healthstone" then
		-- or there is one in the inventory
		if StoneInventory.Healthstone.onHand then
			-- If a friendly player is targeted, give them the stone
			-- Otherwise use it
			if NecrosisTradeRequest then
				PickupContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
				ClickTradeButton(1)
				NecrosisTradeRequest = false
				Trading = true
				TradingNow = 3
				return
			elseif
				UnitExists("target")
				and UnitIsPlayer("target")
				and (not UnitCanAttack("player", "target"))
				and UnitName("target") ~= UnitName("player")
			then
				PickupContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
				if CursorHasItem() then
					DropItemOnUnit("target")
					Trading = true
					TradingNow = 3
				end
				return
			end
			if UnitHealth("player") == UnitHealthMax("player") then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.FullHealth, "USER")
			else
				SpellStopCasting()
				UseContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])

				-- Inserts a timer for the Healthstone if not already present
				local HealthstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Healthstone) then
					HealthstoneInUse = true
				end
				if not HealthstoneInUse then
					SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
						NECROSIS_COOLDOWN.Healthstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil,
						SpellTimer,
						TimerTable
					)
				end

				-- Healthstone shares its cooldown with Spellstone, so we add both timers at the same time, but only if Spellstone is known
				local SpellstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
					SpellstoneInUse = true
				end
				if not SpellstoneInUse and StoneIDInSpellTable[3] ~= 0 then
					SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
						NECROSIS_COOLDOWN.Spellstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil,
						SpellTimer,
						TimerTable
					)
				end
			end
		-- or, if none are in the inventory, create the highest rank stone
		else
			if StoneIDInSpellTable[2] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHealthStoneSpell, "USER")
			end
		end
	-- When clicking the Spellstone button
	elseif type == "Spellstone" then
		if StoneInventory.Spellstone.onHand then
			local start, duration, enabled =
				GetContainerItemCooldown(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			if start > 0 then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.SpellStoneIsOnCooldown, "USER")
			else
				SpellStopCasting()
				UseContainerItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])

				local SpellstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
					SpellstoneInUse = true
				end
				if not SpellstoneInUse then
					SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
						NECROSIS_COOLDOWN.Spellstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil,
						SpellTimer,
						TimerTable
					)
				end

				local HealthstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Healthstone) then
					HealthstoneInUse = true
				end
				if not HealthstoneInUse and StoneIDInSpellTable[2] ~= 0 then
					SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
						NECROSIS_COOLDOWN.Healthstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil,
						SpellTimer,
						TimerTable
					)
				end
			end
		else
			if StoneIDInSpellTable[3] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSpellStoneSpell, "USER")
			end
		end

	-- When clicking the mount button
	elseif type == "Mount" then
		-- Or it is the epic mount
		if NECROSIS_SPELL_TABLE[2].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[2].ID, "spell")
			Necrosis_OnUpdate()
		-- Either it is the normal mount
		elseif NECROSIS_SPELL_TABLE[1].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[1].ID, "spell")
			Necrosis_OnUpdate()
		-- (Or it is nothing at all :) )
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Error.NoRiding, "USER")
		end
	end
end

-- Function that swaps the equipped off-hand item with one from the inventory
function Necrosis_SwitchOffHand(type)
	if type == "Spellstone" then
		if StoneInventory.Spellstone.mode == 3 then
			if StoneInventory.Itemswitch.onHand then
				Necrosis_Msg(
					"Equipe "
						.. GetContainerItemLink(
							StoneInventory.Itemswitch.location[1],
							StoneInventory.Itemswitch.location[2]
						)
						.. NECROSIS_MESSAGE.SwitchMessage
						.. GetInventoryItemLink("player", 17),
					"USER"
				)
				PickupInventoryItem(17)
				PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			end
			return
		else
			PickupContainerItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			PickupInventoryItem(17)
			if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
				SpellTimer, TimerTable =
					Necrosis_RemoveTimerByName(NECROSIS_COOLDOWN.Spellstone, SpellTimer, TimerTable)
			end
			SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
				NECROSIS_COOLDOWN.Spellstone,
				120,
				TIMER_TYPE.SELF_BUFF,
				nil,
				120,
				nil,
				SpellTimer,
				TimerTable
			)
			return
		end
	end
	if (type == "OffHand") and UnitClass("player") == NECROSIS_UNIT_WARLOCK then
		if StoneInventory.Itemswitch.location[1] ~= nil and StoneInventory.Itemswitch.location[2] ~= nil then
			PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			PickupInventoryItem(17)
		end
	end
end

function Necrosis_MoneyToggle()
	for index = 1, 10 do
		local text = getglobal("NecrosisTooltipTextLeft" .. index)
		text:SetText(nil)
		text = getglobal("NecrosisTooltipTextRight" .. index)
		text:SetText(nil)
	end
	NecrosisTooltip:Hide()
	NecrosisTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

function Necrosis_GameTooltip_ClearMoney()
	-- Intentionally empty; don't clear money while we use hidden tooltips
end

-- Function that positions the buttons around Necrosis (and scales the interface)
function Necrosis_UpdateButtonsScale()
	local NBRScale = (100 + (NecrosisConfig.NecrosisButtonScale - 85)) / 100
	if NecrosisConfig.NecrosisButtonScale <= 95 then
		NBRScale = 1.1
	end
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_ClearAllPoints()
		HideUIPanel(NecrosisPetMenuButton)
		HideUIPanel(NecrosisBuffMenuButton)
		HideUIPanel(NecrosisCurseMenuButton)
		HideUIPanel(NecrosisStoneMenuButton)
		HideUIPanel(NecrosisMountButton)
		HideUIPanel(NecrosisSpellstoneButton)
		HideUIPanel(NecrosisHealthstoneButton)
		HideUIPanel(NecrosisSoulstoneButton)
		local indexScale = -36
		for index = 1, 8, 1 do
			if NecrosisConfig.StonePosition[index] then
				if index == StonePos.Healthstone and StoneIDInSpellTable[2] ~= 0 then
					NecrosisHealthstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisHealthstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Spellstone and StoneIDInSpellTable[3] ~= 0 then
					NecrosisSpellstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisSpellstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Soulstone and StoneIDInSpellTable[1] ~= 0 then
					NecrosisSoulstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisSoulstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.BuffMenu and next(MenuState.Buff.frames) then
					NecrosisBuffMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisBuffMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Mount and MountAvailable then
					NecrosisMountButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisMountButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.PetMenu and next(MenuState.Pet.frames) then
					NecrosisPetMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisPetMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.CurseMenu and next(MenuState.Curse.frames) then
					NecrosisCurseMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisCurseMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.StoneMenu and next(MenuState.Stone.frames) then
					NecrosisStoneMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisStoneMenuButton)
					indexScale = indexScale + 36
				end
			end
		end
	end
end

-- (XML) function that restores default button anchors
function Necrosis_ClearAllPoints()
	NecrosisSpellstoneButton:ClearAllPoints()
	NecrosisHealthstoneButton:ClearAllPoints()
	NecrosisSoulstoneButton:ClearAllPoints()
	NecrosisMountButton:ClearAllPoints()
	NecrosisPetMenuButton:ClearAllPoints()
	NecrosisBuffMenuButton:ClearAllPoints()
	NecrosisCurseMenuButton:ClearAllPoints()
	NecrosisStoneMenuButton:ClearAllPoints()
end

-- (XML) function to extend the main button's NoDrag() property to every child button
function Necrosis_NoDrag()
	NecrosisSpellstoneButton:RegisterForDrag("")
	NecrosisHealthstoneButton:RegisterForDrag("")
	NecrosisSoulstoneButton:RegisterForDrag("")
	NecrosisMountButton:RegisterForDrag("")
	NecrosisPetMenuButton:RegisterForDrag("")
	NecrosisBuffMenuButton:RegisterForDrag("")
	NecrosisCurseMenuButton:RegisterForDrag("")
	NecrosisStoneMenuButton:RegisterForDrag("")
end

-- (XML) counterpart of the function above
function Necrosis_Drag()
	NecrosisSpellstoneButton:RegisterForDrag("LeftButton")
	NecrosisHealthstoneButton:RegisterForDrag("LeftButton")
	NecrosisSoulstoneButton:RegisterForDrag("LeftButton")
	NecrosisMountButton:RegisterForDrag("LeftButton")
	NecrosisPetMenuButton:RegisterForDrag("LeftButton")
	NecrosisBuffMenuButton:RegisterForDrag("LeftButton")
	NecrosisCurseMenuButton:RegisterForDrag("LeftButton")
	NecrosisStoneMenuButton:RegisterForDrag("LeftButton")
end

-- Opening the buff menu
function Necrosis_BuffMenu(button)
	if button == "MiddleButton" and LastCast.Buff ~= 0 then
		Necrosis_BuffCast(LastCast.Buff)
		return
	end
	local buffMenu = MenuState.Buff
	local opened = Necrosis_ToggleMenu(buffMenu, NecrosisBuffMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	if not buffMenu.frames[1] then
		return
	end
	buffMenu.frames[1]:ClearAllPoints()
	buffMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisBuffMenuButton",
		"CENTER",
		((36 / NecrosisConfig.BuffMenuPos) * 31),
		26
	)
	MenuState.Pet.fadeAt = GetTime() + 3
	buffMenu.fadeAt = GetTime() + 6
	MenuState.Curse.fadeAt = GetTime() + 6
end

-- Opening the curse menu
function Necrosis_CurseMenu(button)
	if button == "MiddleButton" and LastCast.Curse.id ~= 0 then
		Necrosis_CurseCast(LastCast.Curse.id, LastCast.Curse.click)
		return
	end
	-- S'il n'existe aucune curse on ne fait rien
	local curseMenu = MenuState.Curse
	if not curseMenu.frames[1] then
		return
	end
	local opened = Necrosis_ToggleMenu(curseMenu, NecrosisCurseMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	curseMenu.frames[1]:ClearAllPoints()
	curseMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisCurseMenuButton",
		"CENTER",
		((36 / NecrosisConfig.CurseMenuPos) * 31),
		-26
	)
	MenuState.Pet.fadeAt = GetTime() + 3
	MenuState.Buff.fadeAt = GetTime() + 6
	curseMenu.fadeAt = GetTime() + 6
end

-- Opening the demon menu
function Necrosis_PetMenu(button)
	if button == "MiddleButton" and LastCast.Demon ~= 0 then
		Necrosis_PetCast(LastCast.Demon)
		return
	end
	-- If no summoning spell exists, do nothing
	local petMenu = MenuState.Pet
	if not petMenu.frames[1] then
		return
	end
	local opened = Necrosis_ToggleMenu(petMenu, NecrosisPetMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	petMenu.frames[1]:ClearAllPoints()
	petMenu.frames[1]:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 26)
	petMenu.fadeAt = GetTime() + 3
end

-- Opening the stone menu
function Necrosis_StoneMenu(button)
	if button == "MiddleButton" and LastCast.Stone.id ~= 0 then
		Necrosis_StoneCast(LastCast.Stone.id, LastCast.Stone.click)
		return
	end
	-- S'il n'existe aucune stone on ne fait rien
	local stoneMenu = MenuState.Stone
	if not stoneMenu.frames[1] then
		return
	end
	local opened = Necrosis_ToggleMenu(stoneMenu, NecrosisStoneMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
		onOpen = Necrosis_UpdateIcons,
		onClose = Necrosis_UpdateIcons,
	})
	if not opened then
		return
	end
	Necrosis_SetMenuFramesAlpha(stoneMenu, 1)
	stoneMenu.frames[1]:ClearAllPoints()
	stoneMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisStoneMenuButton",
		"CENTER",
		((36 / NecrosisConfig.StoneMenuPos) * 31),
		-26
	)
	stoneMenu.fadeAt = GetTime() + 6
end

-- Each time the spellbook changes, at mod startup, or when the menu direction flips, rebuild the spell menus
function Necrosis_CreateMenu()
	MenuState.Pet.frames = {}
	MenuState.Curse.frames = {}
	MenuState.Buff.frames = {}
	MenuState.Stone.frames = {}

	local menuDefinitions = {
		{
			state = MenuState.Pet,
			prefix = "NecrosisPetMenu",
			count = 9,
			anchor = "NecrosisPetMenuButton",
			configKey = "PetMenuPos",
			entries = {
				{ frame = "NecrosisPetMenu1", spells = { 15 } },
				{ frame = "NecrosisPetMenu2", spells = { 3 } },
				{ frame = "NecrosisPetMenu3", spells = { 4 } },
				{ frame = "NecrosisPetMenu4", spells = { 5 } },
				{ frame = "NecrosisPetMenu5", spells = { 6 } },
				{ frame = "NecrosisPetMenu6", spells = { 8 } },
				{ frame = "NecrosisPetMenu7", spells = { 30 } },
				{ frame = "NecrosisPetMenu8", spells = { 35 } },
				{ frame = "NecrosisPetMenu9", spells = { 44 } },
			},
		},
		{
			state = MenuState.Buff,
			prefix = "NecrosisBuffMenu",
			count = 9,
			anchor = "NecrosisBuffMenuButton",
			configKey = "BuffMenuPos",
			entries = {
				{ frame = "NecrosisBuffMenu1", spells = { 31, 36 } },
				{ frame = "NecrosisBuffMenu2", spells = { 32 } },
				{ frame = "NecrosisBuffMenu3", spells = { 33 } },
				{ frame = "NecrosisBuffMenu4", spells = { 34 } },
				{ frame = "NecrosisBuffMenu5", spells = { 37 } },
				{ frame = "NecrosisBuffMenu6", spells = { 39 } },
				{ frame = "NecrosisBuffMenu7", spells = { 38 } },
				{ frame = "NecrosisBuffMenu8", spells = { 43 } },
				{ frame = "NecrosisBuffMenu9", spells = { 9 } },
			},
		},
		{
			state = MenuState.Curse,
			prefix = "NecrosisCurseMenu",
			count = 9,
			anchor = "NecrosisCurseMenuButton",
			configKey = "CurseMenuPos",
			entries = {
				{ frame = "NecrosisCurseMenu1", spells = { 42 } },
				{ frame = "NecrosisCurseMenu2", spells = { 23 } },
				{ frame = "NecrosisCurseMenu3", spells = { 22 } },
				{ frame = "NecrosisCurseMenu4", spells = { 24 } },
				{ frame = "NecrosisCurseMenu5", spells = { 25 } },
				{ frame = "NecrosisCurseMenu6", spells = { 40 } },
				{ frame = "NecrosisCurseMenu7", spells = { 26 } },
				{ frame = "NecrosisCurseMenu8", spells = { 27 } },
				{ frame = "NecrosisCurseMenu9", spells = { 16 } },
			},
		},
		{
			state = MenuState.Stone,
			prefix = "NecrosisStoneMenu",
			count = 4,
			anchor = "NecrosisStoneMenuButton",
			configKey = "StoneMenuPos",
			entries = {
				{ frame = "NecrosisStoneMenu1", spells = { 45 }, texture = { "Felstone", 2 } },
				{ frame = "NecrosisStoneMenu2", spells = { 46 }, texture = { "Wrathstone", 2 } },
				{ frame = "NecrosisStoneMenu3", spells = { 47 }, texture = { "Voidstone", 2 } },
				{
					frame = "NecrosisStoneMenu4",
					condition = function()
						return StoneIDInSpellTable[4] ~= 0
					end,
					texture = { "FirestoneButton", 2 },
				},
			},
		},
	}

	for index = 1, table.getn(menuDefinitions), 1 do
		local definition = menuDefinitions[index]
		Necrosis_BuildMenu(definition)
	end
end

-- Handle casts triggered from the buff menu
function Necrosis_BuffCast(type)
	local TargetEnemy = false
	if UnitCanAttack("player", "target") and type ~= 9 then
		TargetUnit("player")
		TargetEnemy = true
	end
	-- If the Warlock has Demon Skin but not Demon Armor
	if not NECROSIS_SPELL_TABLE[type].ID then
		CastSpell(NECROSIS_SPELL_TABLE[36].ID, "spell")
	else
		if (type ~= 44) or (type == 44 and UnitExists("Pet")) then
			CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
		end
	end
	LastCast.Buff = type
	if TargetEnemy then
		TargetLastTarget()
	end
	MenuState.Buff.alpha = 1
	MenuState.Buff.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the curse menu
function Necrosis_CurseCast(type, click)
	if (UnitIsFriend("player", "target")) and (not UnitCanAttack("player", "target")) then
		AssistUnit("target")
	end
	if (UnitCanAttack("player", "target")) and (UnitName("target") ~= nil) then
		if type == 23 or type == 22 or type == 40 then
			if (click == "RightButton") and (NECROSIS_SPELL_TABLE[42].ID ~= nil) then
				local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell")
				if not (start3 > 0 and duration3 > 0) then
					CastSpell(NECROSIS_SPELL_TABLE[42].ID, "spell")
					SpellStopCasting(NECROSIS_SPELL_TABLE[42].Name)
				end
			end
		end
		CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
		LastCast.Curse.id = type
		LastCast.Curse.click = click
		if (click == "MiddleButton") and (UnitExists("Pet")) then
			PetAttack()
		end
	end
	MenuState.Curse.alpha = 1
	MenuState.Curse.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the stone menu
local StoneCastDefinitions = {
	[1] = { inventoryKey = "Felstone", stoneIndex = 5 },
	[2] = { inventoryKey = "Wrathstone", stoneIndex = 6 },
	[3] = { inventoryKey = "Voidstone", stoneIndex = 7 },
	[4] = { inventoryKey = "Firestone", stoneIndex = 4 },
}

function Necrosis_StoneCast(type, click)
	local definition = StoneCastDefinitions[type]
	if not definition then
		return
	end

	local stoneData = StoneInventory[definition.inventoryKey]
	if stoneData and stoneData.onHand then
		SpellStopCasting()
		UseContainerItem(stoneData.location[1], stoneData.location[2])
		return
	end

	local stoneSpellIndex = nil
	if definition.stoneIndex then
		stoneSpellIndex = StoneIDInSpellTable[definition.stoneIndex]
	end
	local stoneSpell = nil
	if stoneSpellIndex and stoneSpellIndex ~= 0 then
		stoneSpell = NECROSIS_SPELL_TABLE[stoneSpellIndex]
	end
	if not stoneSpell or not stoneSpell.ID then
		local errorTable = NECROSIS_MESSAGE and NECROSIS_MESSAGE.Error
		if errorTable then
			local messageKey = "No" .. definition.inventoryKey .. "Spell"
			local message = errorTable[messageKey]
			if message then
				Necrosis_Msg(message, "USER")
			end
		end
	else
		if stoneSpell.Mana and stoneSpell.Mana > UnitMana("player") then
			local errorTable = NECROSIS_MESSAGE and NECROSIS_MESSAGE.Error
			if errorTable and errorTable.NoMana then
				Necrosis_Msg(errorTable.NoMana, "USER")
			end
			return
		end
		CastSpell(stoneSpell.ID, "spell")
		LastCast.Stone.id = type
		LastCast.Stone.click = click
	end

	MenuState.Stone.alpha = 1
	MenuState.Stone.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the demon menu
function Necrosis_PetCast(type, click)
	if type == 8 and InfernalStone == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.InfernalStoneNotPresent, "USER")
		return
	elseif type == 30 and DemoniacStone == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.DemoniacStoneNotPresent, "USER")
		return
	elseif type ~= 15 and type ~= 3 and type ~= 8 and type ~= 30 and SoulshardState.count == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.SoulShardNotPresent, "USER")
		return
	end
	if type == 3 or type == 4 or type == 5 or type == 6 then
		LastCast.Demon = type
		if (click == "RightButton") and (NECROSIS_SPELL_TABLE[15].ID ~= nil) then
			local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell")
			if not (start > 0 and duration > 0) then
				CastSpell(NECROSIS_SPELL_TABLE[15].ID, "spell")
				SpellStopCasting(NECROSIS_SPELL_TABLE[15].Name)
			end
		end
		if NecrosisConfig.DemonSummon and NecrosisConfig.ChatMsg and not NecrosisConfig.SM then
			if NecrosisConfig.PetName[(type - 2)] == " " and NECROSIS_PET_MESSAGE[5] then
				local genericMessages = NECROSIS_PET_MESSAGE[5]
				local genericCount = table.getn(genericMessages)
				if genericCount > 0 then
					local tempnum = random(1, genericCount)
					if genericCount >= 2 then
						while tempnum == PetMess do
							tempnum = random(1, genericCount)
						end
					end
					PetMess = tempnum
					local lines = genericMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY")
					end
				end
			elseif NECROSIS_PET_MESSAGE[(type - 2)] then
				local specificMessages = NECROSIS_PET_MESSAGE[(type - 2)]
				local specificCount = table.getn(specificMessages)
				if specificCount > 0 then
					local tempnum = random(1, specificCount)
					if specificCount >= 2 then
						while tempnum == PetMess do
							tempnum = random(1, specificCount)
						end
					end
					PetMess = tempnum
					local lines = specificMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i], nil, type - 2), "SAY")
					end
				end
			end
		end
	end
	CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
	MenuState.Pet.alpha = 1
	MenuState.Pet.fadeAt = GetTime() + 3
end

-- Function that shows the different configuration pages
local NecrosisGeneralTabs = {
	{
		button = "NecrosisGeneralTab1",
		panelName = "NecrosisShardMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu1",
	},
	{
		button = "NecrosisGeneralTab2",
		panelName = "NecrosisMessageMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu2",
	},
	{
		button = "NecrosisGeneralTab3",
		panelName = "NecrosisButtonMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu3",
	},
	{
		button = "NecrosisGeneralTab4",
		panelName = "NecrosisTimerMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu4",
	},
	{
		button = "NecrosisGeneralTab5",
		panelName = "NecrosisGraphOptionMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu5",
	},
}

function NecrosisGeneralTab_OnClick(id)
	for index = 1, table.getn(NecrosisGeneralTabs), 1 do
		local tabDefinition = NecrosisGeneralTabs[index]
		local tabButton = getglobal(tabDefinition.button)
		if tabButton then
			tabButton:SetChecked(index == id and 1 or nil)
		end
		if tabDefinition.panelName then
			local panel = getglobal(tabDefinition.panelName)
			if panel then
				HideUIPanel(panel)
			end
		end
	end

	local config = NecrosisGeneralTabs[id]
	if not config then
		return
	end

	if config.panelName then
		local panel = getglobal(config.panelName)
		if panel then
			ShowUIPanel(panel)
		end
	end

	if config.icon then
		NecrosisGeneralIcon:SetTexture(config.icon)
	end

	if config.labelKey and NECROSIS_CONFIGURATION then
		local label = NECROSIS_CONFIGURATION[config.labelKey]
		if label then
			NecrosisGeneralPageText:SetText(label)
		end
	end
end

-- To support timers on instant spells I had to take inspiration from Cosmos
-- I did not want the mod to depend on Sea, so I reimplemented its helpers
-- Apparently the stand-alone version of ShardTracker did the same :) :)
Necrosis_Hook = function(orig, new, type)
	if not type then
		type = "before"
	end
	if not Hx_Hooks then
		Hx_Hooks = {}
	end
	if not Hx_Hooks[orig] then
		Hx_Hooks[orig] = {}
		Hx_Hooks[orig].before = {}
		Hx_Hooks[orig].before.n = 0
		Hx_Hooks[orig].after = {}
		Hx_Hooks[orig].after.n = 0
		Hx_Hooks[orig].hide = {}
		Hx_Hooks[orig].hide.n = 0
		Hx_Hooks[orig].replace = {}
		Hx_Hooks[orig].replace.n = 0
		Hx_Hooks[orig].orig = getglobal(orig)
	else
		for key, value in Hx_Hooks[orig][type] do
			if value == getglobal(new) then
				return
			end
		end
	end
	Necrosis_Push(Hx_Hooks[orig][type], getglobal(new))
	setglobal(orig, function(...)
		Necrosis_HookHandler(orig, arg)
	end)
end

Necrosis_HookHandler = function(name, arg)
	local called = false
	local continue = true
	local retval
	for key, value in Hx_Hooks[name].hide do
		if type(value) == "function" then
			if not value(unpack(arg)) then
				continue = false
			end
			called = true
		end
	end
	if not continue then
		return
	end
	for key, value in Hx_Hooks[name].before do
		if type(value) == "function" then
			value(unpack(arg))
			called = true
		end
	end
	continue = false
	local replacedFunction = false
	for key, value in Hx_Hooks[name].replace do
		if type(value) == "function" then
			replacedFunction = true
			if value(unpack(arg)) then
				continue = true
			end
			called = true
		end
	end
	if continue or not replacedFunction then
		retval = Hx_Hooks[name].orig(unpack(arg))
	end
	for key, value in Hx_Hooks[name].after do
		if type(value) == "function" then
			value(unpack(arg))
			called = true
		end
	end
	if not called then
		setglobal(name, Hx_Hooks[name].orig)
		Hx_Hooks[name] = nil
	end
	return retval
end

function Necrosis_Push(table, val)
	if not table or not table.n then
		return nil
	end
	table.n = table.n + 1
	table[table.n] = val
end

function Necrosis_UseAction(id, number, onSelf)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetAction(id)
	local tip = tostring(NecrosisTooltipTextLeft1:GetText())
	if tip then
		SpellCastName = tip
		SpellTargetName = UnitName("target")
		if not SpellTargetName then
			SpellTargetName = ""
		end
	end
end

function Necrosis_CastSpell(spellId, spellbookTabNum)
	local Name, Rank = GetSpellName(spellId, spellbookTabNum)
	if Rank ~= nil then
		local _, _, Rank2 = string.find(Rank, "(%d+)")
		SpellCastRank = tonumber(Rank2)
	end
	SpellCastName = Name

	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end
end

function Necrosis_CastSpellByName(Spell)
	local _, _, Name = string.find(Spell, "(.+)%(")
	local _, _, Rank = string.find(Spell, "([%d]+)")

	if Rank ~= nil then
		local _, _, Rank2 = string.find(Rank, "(%d+)")
		SpellCastRank = tonumber(Rank2)
	end

	if not Name then
		_, _, Name = string.find(Spell, "(.+)")
	end
	SpellCastName = Name

	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end
end

function NecrosisTimer(timerName, durationSeconds)
	local targetName = UnitName("target")
	local timerType = TIMER_TYPE.CUSTOM
	if not targetName then
		targetName = ""
		timerType = TIMER_TYPE.SELF_BUFF
	end
	SpellTimer, TimerTable = Necrosis_InsertCustomTimer(
		timerName,
		durationSeconds,
		timerType,
		targetName,
		SpellTimer,
		TimerTable,
		durationSeconds
	)
end

function NecrosisSpellCast(name)
	if string.find(name, "coa") then
		SpellCastName = NECROSIS_SPELL_TABLE[22].Name
		SpellTargetName = UnitName("target")
		if not SpellTargetName then
			SpellTargetName = ""
		end
		CastSpell(NECROSIS_SPELL_TABLE[22].ID, "spell")
	end
end
