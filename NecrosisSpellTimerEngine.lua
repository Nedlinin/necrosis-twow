------------------------------------------------------------------------------------------------------
-- Necrosis Spell Timer Engine
------------------------------------------------------------------------------------------------------

local floor = math.floor
local wipe_array = NecrosisUtils.WipeArray
local wipe_table = NecrosisUtils.WipeTable

TimerTable = TimerTable or {}
if table.getn(TimerTable) == 0 then
	for i = 1, 50, 1 do
		TimerTable[i] = false
	end
end

DEBUG_TIMER_EVENTS = DEBUG_TIMER_EVENTS or false

local TimerEngine = {
	textSegments = {},
	graphical = {
		activeCount = 0,
		names = {},
		expiryTimes = {},
		initialDurations = {},
		displayLines = {},
		slotIds = {},
	},
	textDisplay = "",
	coloredDisplay = "",
	textDirty = true,
	lastTextBuildTime = 0,
	timerEventsRegistered = true,
}

local TIMER_EVENT_NAMES = {
	"UNIT_AURA",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_BREAK_AURA",
}

local TIMER_TYPE = NECROSIS_TIMER_TYPE

local AuraScanAccumulator = 0
local TRACKED_BUFF_LOOKUP = {}
local DEFAULT_TRACKED_SELF_BUFFS
local TRACKED_SELF_BUFFS
local TRACKED_SELF_BUFF_COUNT

LastRefreshedBuffName = LastRefreshedBuffName
LastRefreshedBuffTime = LastRefreshedBuffTime

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

local function Necrosis_TrackStoneBuff(stoneKey, buffName, baseDuration)
	DEFAULT_TRACKED_SELF_BUFFS = DEFAULT_TRACKED_SELF_BUFFS or Necrosis_BuildDefaultTrackedBuffs()
	TRACKED_SELF_BUFFS = TRACKED_SELF_BUFFS or DEFAULT_TRACKED_SELF_BUFFS
	local config = Necrosis_CreateStoneBuffConfig(stoneKey)
	config.buffName = buffName
	config.timerName = buffName
	config.baseDuration = baseDuration
	local count = table.getn(TRACKED_SELF_BUFFS)
	for index = 1, count do
		local existing = TRACKED_SELF_BUFFS[index]
		if existing and existing.buffName == buffName then
			TRACKED_SELF_BUFFS[index] = config
			Necrosis_SetTrackedBuffs(TRACKED_SELF_BUFFS)
			return
		end
	end
	table.insert(TRACKED_SELF_BUFFS, config)
	Necrosis_SetTrackedBuffs(TRACKED_SELF_BUFFS)
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

local function Necrosis_GetStoredBuffDuration(timerName)
	if not timerName then
		return nil
	end
	if type(NecrosisConfig) ~= "table" then
		return nil
	end
	local durations = NecrosisConfig.TrackedBuffDurations
	if type(durations) ~= "table" then
		return nil
	end
	return durations[timerName]
end

local function Necrosis_RebuildTrackedBuffLookup(buffConfigs)
	wipe_table(TRACKED_BUFF_LOOKUP)
	if type(buffConfigs) ~= "table" then
		return
	end
	for index = 1, table.getn(buffConfigs) do
		local config = buffConfigs[index]
		if config then
			local timerName = config.timerName
			if timerName then
				TRACKED_BUFF_LOOKUP[timerName] = config
			end
			local buffName = config.buffName
			if buffName then
				TRACKED_BUFF_LOOKUP[buffName] = config
			end
		end
	end
end

local function Necrosis_SetTrackedBuffs(buffConfigs)
	if type(buffConfigs) ~= "table" then
		return
	end
	TRACKED_SELF_BUFFS = buffConfigs
	TRACKED_SELF_BUFF_COUNT = table.getn(buffConfigs)
	Necrosis_RebuildTrackedBuffLookup(buffConfigs)
end

DEFAULT_TRACKED_SELF_BUFFS = Necrosis_BuildDefaultTrackedBuffs()
Necrosis_SetTrackedBuffs(DEFAULT_TRACKED_SELF_BUFFS)

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
	local direct = TRACKED_BUFF_LOOKUP[searchText]
	if direct then
		return direct
	end
	local tracked = TRACKED_SELF_BUFFS
	local count = TRACKED_SELF_BUFF_COUNT or 0
	if (not tracked or count == 0) and DEFAULT_TRACKED_SELF_BUFFS then
		Necrosis_SetTrackedBuffs(DEFAULT_TRACKED_SELF_BUFFS)
		tracked = TRACKED_SELF_BUFFS
		count = TRACKED_SELF_BUFF_COUNT or 0
	end
	if not tracked or count == 0 then
		return nil
	end
	for index = 1, count do
		local config = tracked[index]
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
	local config = TRACKED_BUFF_LOOKUP[searchText]
	if not config then
		config = Necrosis_FindTrackedBuffConfigByName(searchText)
	end
	if not config then
		return nil
	end
	return Necrosis_GetTrackedBuffTimerName(config)
end

function Necrosis_RemoveTrackedBuffTimerForMessage(message)
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

function Necrosis_TouchSelfBuffTimer(
	spellIndex,
	timerName,
	playerName,
	duration,
	expiry,
	timerType,
	baseDuration,
	createIfMissing,
	currentTime
)
	createIfMissing = createIfMissing ~= false
	playerName = playerName or ""
	timerType = timerType or TIMER_TYPE.SELF_BUFF
	duration = duration or 0
	currentTime = currentTime or GetTime()

	if not timerName and spellIndex then
		local data = NECROSIS_SPELL_TABLE[spellIndex]
		if data then
			timerName = data.Name
			timerType = timerType or data.Type
			if not baseDuration or (data.Length and data.Length > baseDuration) then
				baseDuration = data.Length
			end
		end
	end

	if not timerName then
		return false
	end

	local initialDuration = baseDuration
	if not initialDuration or initialDuration <= 0 then
		initialDuration = duration
	end

	if (not expiry or expiry <= 0) and duration and duration > 0 then
		expiry = floor(currentTime + duration)
	end

	local updated
	updated, SpellTimer =
		Necrosis_UpdateTimerEntry(SpellTimer, timerName, playerName, duration, expiry, timerType, initialDuration)

	if updated then
		LastRefreshedBuffName = timerName
		LastRefreshedBuffTime = currentTime
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("Buff timer", timerName, "updated", "(touch)")
		end
		return true
	end

	if DEBUG_TIMER_EVENTS then
		Necrosis_DebugPrint("Buff timer", timerName, createIfMissing and "ensure" or "clear", "(touch)")
	end

	if not createIfMissing then
		SpellTimer, TimerTable = Necrosis_RemoveTimerByName(timerName, SpellTimer, TimerTable)
		return false
	end

	if spellIndex then
		SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(
			spellIndex,
			playerName,
			duration,
			timerType,
			initialDuration,
			expiry,
			SpellTimer,
			TimerTable
		)
	else
		SpellTimer, TimerTable = Necrosis_EnsureNamedTimer(
			timerName,
			duration,
			timerType,
			playerName,
			initialDuration,
			expiry,
			SpellTimer,
			TimerTable
		)
	end

	LastRefreshedBuffName = timerName
	LastRefreshedBuffTime = currentTime
	if DEBUG_TIMER_EVENTS then
		Necrosis_DebugPrint("Buff timer", timerName, "created", "(touch)")
	end
	return true
end

function Necrosis_RefreshSelfBuffTimer(buffConfig, playerName, currentTime)
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
	local updated = Necrosis_TouchSelfBuffTimer(
		buffConfig.spellIndex,
		timerName,
		playerName,
		durationSeconds,
		expiry,
		timerType,
		baseDuration,
		true,
		currentTime
	)
	if updated then
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("UNIT_AURA", timerName, "ensure timer", "timeLeft=", durationSeconds or 0)
		end
		return true, timerName
	end
	return false, timerName
end

local function Necrosis_GetBuffSpellIndexByNameInternal(buffName)
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

local function Necrosis_WasBuffRecentlyRefreshedInternal(buffName)
	if not buffName or not LastRefreshedBuffName then
		return false
	end
	if LastRefreshedBuffName ~= buffName then
		return false
	end
	return (GetTime() - LastRefreshedBuffTime) <= 1
end

local function Necrosis_ShouldUseSpellTimersInternal()
	return NecrosisConfig.ShowSpellTimers or NecrosisConfig.Graphical
end

function Necrosis_ShouldUseSpellTimers()
	return Necrosis_ShouldUseSpellTimersInternal()
end

function Necrosis_MarkTextTimersDirty()
	TimerEngine.textDirty = true
end

local function Necrosis_ClearExpiredTimers(curTime, targetName)
	if not SpellTimer then
		return
	end
	local soulstoneName = NECROSIS_SPELL_TABLE[11] and NECROSIS_SPELL_TABLE[11].Name
	local enslaveName = NECROSIS_SPELL_TABLE[10] and NECROSIS_SPELL_TABLE[10].Name
	local demonArmorName = NECROSIS_SPELL_TABLE[17] and NECROSIS_SPELL_TABLE[17].Name
	for index = table.getn(SpellTimer), 1, -1 do
		local timer = SpellTimer[index]
		if timer then
			local name = timer.Name
			local timeMax = timer.TimeMax or 0
			if curTime >= (timeMax - 0.5) and timeMax ~= -1 then
				if soulstoneName and name == soulstoneName then
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
				elseif not (enslaveName and name == enslaveName) then
					SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
				end
			else
				if demonArmorName and name == demonArmorName and not Necrosis_UnitHasEffect("player", name) then
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
end

local function Necrosis_ResetTimerAssignments()
	if TimerTable then
		for slot = 1, table.getn(TimerTable), 1 do
			if TimerTable[slot] then
				TimerTable = Necrosis_RemoveTimerFrame(slot, TimerTable)
			else
				TimerTable[slot] = false
			end
		end
	end
	if SpellTimer then
		for i = 1, table.getn(SpellTimer), 1 do
			local timer = SpellTimer[i]
			if timer then
				timer.Gtimer = nil
			end
		end
	end
end

local function Necrosis_RebuildTimerBuffers(engine, curTime, buildText)
	wipe_array(engine.textSegments)
	if not SpellTimer then
		return 0
	end
	local curTimeFloor = floor(curTime)
	local graphCount = 0
	for index = 1, table.getn(SpellTimer), 1 do
		local timer = SpellTimer[index]
		if timer and curTime <= (timer.TimeMax or 0) then
			TimerTable, graphCount = Necrosis_DisplayTimer(
				engine.textSegments,
				index,
				SpellTimer,
				engine.graphical,
				TimerTable,
				graphCount,
				curTimeFloor,
				buildText
			)
		end
	end
	return graphCount
end

local function Necrosis_RefreshGraphicalSlots(engine, previousActive, graphCount)
	if previousActive > graphCount then
		for slotIndex = graphCount + 1, previousActive, 1 do
			engine.graphical.names[slotIndex] = nil
			engine.graphical.expiryTimes[slotIndex] = nil
			engine.graphical.initialDurations[slotIndex] = nil
			engine.graphical.displayLines[slotIndex] = nil
			engine.graphical.slotIds[slotIndex] = nil
		end
	end
	engine.graphical.activeCount = graphCount
end

function Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	if not Necrosis_ShouldUseSpellTimersInternal() then
		return
	end
	if not SpellTimer or not shouldUpdate then
		return
	end

	local engine = TimerEngine
	local targetName = UnitName("target")
	local textVisible = NecrosisConfig.ShowSpellTimers
		and not NecrosisConfig.Graphical
		and NecrosisSpellTimerButton:IsVisible()
	local curTimeFloor = floor(curTime)
	local buildText = textVisible and (engine.textDirty or curTimeFloor ~= engine.lastTextBuildTime)

	Necrosis_ClearExpiredTimers(curTime, targetName)
	local previousActive = engine.graphical.activeCount or 0
	Necrosis_ResetTimerAssignments()
	local graphCount = Necrosis_RebuildTimerBuffers(engine, curTime, buildText)
	Necrosis_RefreshGraphicalSlots(engine, previousActive, graphCount)

	if buildText then
		engine.textDisplay = table.concat(engine.textSegments)
		engine.coloredDisplay = engine.textDisplay
		engine.lastTextBuildTime = curTimeFloor
		engine.textDirty = false
	end
end

function Necrosis_UpdateTimerDisplay()
	local engine = TimerEngine
	if NecrosisConfig.ShowSpellTimers or NecrosisConfig.Graphical then
		if not NecrosisSpellTimerButton:IsVisible() then
			ShowUIPanel(NecrosisSpellTimerButton)
			if NecrosisConfig.ShowSpellTimers then
				engine.textDirty = true
			end
		end
		if NecrosisConfig.ShowSpellTimers and not NecrosisConfig.Graphical then
			NecrosisListSpells:SetText(engine.coloredDisplay)
		else
			NecrosisListSpells:SetText("")
		end
	elseif NecrosisSpellTimerButton:IsVisible() then
		NecrosisListSpells:SetText("")
		HideUIPanel(NecrosisSpellTimerButton)
		engine.textDirty = true
	end
end

function Necrosis_UpdateTimerEventRegistration()
	if not NecrosisButton then
		return
	end
	local want = Necrosis_ShouldUseSpellTimersInternal()
	if want == TimerEngine.timerEventsRegistered then
		return
	end
	TimerEngine.timerEventsRegistered = want
	for index = 1, table.getn(TIMER_EVENT_NAMES) do
		local eventName = TIMER_EVENT_NAMES[index]
		if want then
			NecrosisButton:RegisterEvent(eventName)
		else
			NecrosisButton:UnregisterEvent(eventName)
		end
	end
end

function Necrosis_UpdateTrackedBuffTimers(elapsed, curTime)
	AuraScanAccumulator = AuraScanAccumulator + elapsed
	if AuraScanAccumulator < 1 then
		return
	end

	local auraOvershoot = floor(AuraScanAccumulator)
	AuraScanAccumulator = AuraScanAccumulator - auraOvershoot

	local playerName = UnitName("player") or ""
	local tracked = TRACKED_SELF_BUFFS
	local trackedCount = TRACKED_SELF_BUFF_COUNT or 0
	if not tracked or trackedCount == 0 then
		tracked = DEFAULT_TRACKED_SELF_BUFFS
		if tracked then
			Necrosis_SetTrackedBuffs(tracked)
			trackedCount = TRACKED_SELF_BUFF_COUNT or 0
		end
	end
	if not tracked or trackedCount == 0 then
		return
	end
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

function Necrosis_OnPlayerAuraEvent(_, unitId)
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
		local fallback = DEFAULT_TRACKED_SELF_BUFFS or Necrosis_BuildDefaultTrackedBuffs()
		Necrosis_SetTrackedBuffs(fallback)
	end
	if LastRefreshedBuffName and LastRefreshedBuffTime and (currentTime - LastRefreshedBuffTime) <= 0.2 then
		return
	end
	local tracked = TRACKED_SELF_BUFFS
	local trackedCount = TRACKED_SELF_BUFF_COUNT or 0
	if not tracked or trackedCount == 0 then
		return
	end
	for index = 1, trackedCount do
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

function Necrosis_RegisterTrackedStoneBuff(stoneKey, buffName, baseDuration)
	Necrosis_TrackStoneBuff(stoneKey, buffName, baseDuration)
end

function Necrosis_NoteBuffRefresh(buffName)
	LastRefreshedBuffName = buffName
	LastRefreshedBuffTime = GetTime()
end

function Necrosis_GetBuffSpellIndexByName(buffName)
	return Necrosis_GetBuffSpellIndexByNameInternal(buffName)
end

function Necrosis_WasBuffRecentlyRefreshed(buffName)
	return Necrosis_WasBuffRecentlyRefreshedInternal(buffName)
end

local function Necrosis_NotifyTimerDebug(status)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffNecrosis:|r Timer debug " .. status)
	else
		print("Necrosis timer debug " .. status)
	end
end

function Necrosis_SetTimerDebug(enabled)
	enabled = not not enabled
	local previous = DEBUG_TIMER_EVENTS or false
	DEBUG_TIMER_EVENTS = enabled
	if type(NecrosisConfig) == "table" then
		NecrosisConfig.DebugTimers = enabled
	end
	if type(getglobal) == "function" then
		local button = getglobal("NecrosisTimerDebug_Button")
		if button then
			button:SetChecked(enabled and 1 or 0)
		end
	end
	if previous ~= enabled then
		Necrosis_NotifyTimerDebug(enabled and "enabled" or "disabled")
	end
end
