------------------------------------------------------------------------------------------------------
-- Necrosis Spell Timer Engine
------------------------------------------------------------------------------------------------------

local floor = math.floor
local GetTime = GetTime
local wipe_array = NecrosisUtils.WipeArray
local wipe_table = NecrosisUtils.WipeTable
local Spells = Necrosis.Spells
local SpellIndex = Spells and Spells.Index or {}

-- Cache timer service reference to avoid repeated lookups
local timerServiceCache = nil

local function getTimerService()
	if not timerServiceCache then
		timerServiceCache = NecrosisTimerService
	end
	return timerServiceCache
end

function Necrosis_InvalidateTimerServiceCache()
	timerServiceCache = nil
end

DEBUG_TIMER_EVENTS = DEBUG_TIMER_EVENTS or false

local TimerEngine = {
	timerEventsRegistered = true,
}

local TIMER_EVENT_NAMES = {
	"UNIT_AURA",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_BREAK_AURA",
}

local TIMER_TYPE = NECROSIS_TIMER_TYPE

local TRACKED_BUFF_LOOKUP = {}
local DEFAULT_TRACKED_SELF_BUFFS
local TRACKED_SELF_BUFFS
local TRACKED_SELF_BUFF_COUNT

LastRefreshedBuffName = LastRefreshedBuffName
LastRefreshedBuffTime = LastRefreshedBuffTime

local TRACKED_BUFFS_DIRTY = true
local TRACKED_BUFF_LAST_SIGNAL = 0
local TRACKED_BUFF_LAST_SCAN = 0
local TRACKED_BUFF_WATCHDOG_SECONDS = 1
local TRACKED_BUFF_MIN_DELAY = 0.1
local TRACKED_BUFF_ACTIVE_IDS = {}
local TRACKED_BUFF_ACTIVE_NAMES = {}
local TRACKED_BUFF_DEBUG_STATUS = {}

local function markTrackedBuffsDirty(signalTime)
	TRACKED_BUFFS_DIRTY = true
	TRACKED_BUFF_LAST_SIGNAL = signalTime or GetTime()
end

function Necrosis_MarkTrackedBuffsDirty(eventTime)
	markTrackedBuffsDirty(eventTime)
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

local function safeGetSpellTexture(identifier)
	if not identifier or identifier == "" then
		return nil
	end
	local ok, texture = pcall(GetSpellTexture, identifier)
	if ok then
		return texture
	end
	return nil
end

local function assignBuffTextures(config)
	if not config then
		return
	end
	if config.buffTextureSet then
		return
	end
	local textures = {}
	local function addTexture(texture)
		if texture and texture ~= "" then
			textures[texture] = true
		end
	end
	if config.spellIndex then
		local spellData = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[config.spellIndex]
		if spellData then
			addTexture(safeGetSpellTexture(spellData.ID))
			addTexture(safeGetSpellTexture(spellData.Name))
		end
	end
	addTexture(safeGetSpellTexture(config.buffName))
	if config.timerName and config.timerName ~= config.buffName then
		addTexture(safeGetSpellTexture(config.timerName))
	end
	if config.buffTexture then
		addTexture(config.buffTexture)
	end
	if next(textures) then
		config.buffTextureSet = textures
	end
end

local function Necrosis_BuildDefaultTrackedBuffs()
	local buffs = {}
	local added = {}

	local function addSpell(index)
		if not index then
			return
		end
		local data = Spells and Spells:Get(index)
		if not data or not data.Name then
			return
		end
		local timerType = data.Type
		if timerType ~= TIMER_TYPE.SELF_BUFF and timerType ~= TIMER_TYPE.COOLDOWN then
			return
		end
		local name = data.Name
		if added[name] then
			return
		end
		local config = {
			spellIndex = index,
			timerType = timerType,
			buffName = name,
			timerName = name,
			expectedDuration = Spells:GetLength(index, 0),
		}
		table.insert(buffs, config)
		added[name] = true
	end

	if Spells and Spells.Iterate then
		Spells:Iterate(function(data, index)
			addSpell(index)
		end)
	else
		addSpell(SpellIndex and SpellIndex.DEMON_ARMOR or 31)
		addSpell(SpellIndex and SpellIndex.DEMON_SKIN or 36)
		addSpell(SpellIndex and SpellIndex.SOULSTONE_RESURRECTION or 11)
	end

	for index = 1, table.getn(STONE_BUFF_KEYS) do
		local stoneKey = STONE_BUFF_KEYS[index]
		local config = Necrosis_CreateStoneBuffConfig(stoneKey)
		table.insert(buffs, config)
	end

	return buffs
end

function Necrosis_RebuildDefaultTrackedBuffs()
	local newDefaults = Necrosis_BuildDefaultTrackedBuffs()
	DEFAULT_TRACKED_SELF_BUFFS = newDefaults
	if type(TRACKED_SELF_BUFFS) ~= "table" then
		TRACKED_SELF_BUFFS = newDefaults
	end
	TRACKED_SELF_BUFF_COUNT = table.getn(TRACKED_SELF_BUFFS)

	-- Rebuild lookup table (inline logic since function is local)
	wipe_table(TRACKED_BUFF_LOOKUP)
	for index = 1, TRACKED_SELF_BUFF_COUNT do
		local config = TRACKED_SELF_BUFFS[index]
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

	wipe_table(TRACKED_BUFF_ACTIVE_IDS)
	wipe_table(TRACKED_BUFF_ACTIVE_NAMES)
	markTrackedBuffsDirty()
	for index = 1, TRACKED_SELF_BUFF_COUNT do
		assignBuffTextures(TRACKED_SELF_BUFFS[index])
	end

	-- Clear stored durations so they get recalculated with updated spell data
	if type(NecrosisConfig) == "table" and type(NecrosisConfig.TrackedBuffDurations) == "table" then
		wipe_table(NecrosisConfig.TrackedBuffDurations)
	end
end

local function Necrosis_TrackStoneBuff(stoneKey, buffName, baseDuration)
	DEFAULT_TRACKED_SELF_BUFFS = DEFAULT_TRACKED_SELF_BUFFS or Necrosis_BuildDefaultTrackedBuffs()
	TRACKED_SELF_BUFFS = TRACKED_SELF_BUFFS or DEFAULT_TRACKED_SELF_BUFFS
	local config = Necrosis_CreateStoneBuffConfig(stoneKey)
	config.buffName = buffName
	config.timerName = buffName
	config.baseDuration = baseDuration
	assignBuffTextures(config)
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
	local previous = durations[timerName]
	if not previous or math.abs(previous - duration) > 5 then
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
	wipe_table(TRACKED_BUFF_ACTIVE_IDS)
	wipe_table(TRACKED_BUFF_ACTIVE_NAMES)
	markTrackedBuffsDirty()
	for index = 1, TRACKED_SELF_BUFF_COUNT do
		assignBuffTextures(buffConfigs[index])
	end
end

DEFAULT_TRACKED_SELF_BUFFS = Necrosis_BuildDefaultTrackedBuffs()
Necrosis_SetTrackedBuffs(DEFAULT_TRACKED_SELF_BUFFS)

local function Necrosis_FindPlayerBuff(buffName, options)
	options = options or {}
	local cachedId = options.cachedId
	if cachedId then
		local cachedTimeLeft = GetPlayerBuffTimeLeft(cachedId) or 0
		if cachedTimeLeft > 0 then
			return cachedId, cachedTimeLeft, options.buffName or options.timerName or buffName
		end
	end
	local textureSet = options.buffTextureSet
	if textureSet then
		local index = 0
		while true do
			local buffId = GetPlayerBuff(index, "HELPFUL")
			if not buffId or buffId == -1 then
				break
			end
			local texture = GetPlayerBuffTexture(buffId)
			if texture and textureSet[texture] then
				local timeLeft = GetPlayerBuffTimeLeft(buffId) or 0
				return buffId, timeLeft, options.buffName or options.timerName or buffName
			end
			index = index + 1
		end
	end
	local tooltipPattern = options.tooltipPattern
	local matcher = options.matcher
	if not buffName and not tooltipPattern and not matcher then
		return nil, 0
	end
	local plainSearch = options.plain ~= false
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

function Necrosis_FindTrackedBuffConfigByName(searchText)
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
	TRACKED_BUFF_ACTIVE_IDS[timerName] = nil
	markTrackedBuffsDirty()
	local service = getTimerService()
	if service then
		service:RemoveTimerByName(timerName)
	end
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
	local service = getTimerService()
	if not service then
		return false
	end

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

	local updated = service:UpdateTimerEntry(timerName, playerName, duration, expiry, timerType, initialDuration)

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
		service:RemoveTimerByName(timerName)
		return false
	end

	if spellIndex then
		service:EnsureSpellIndexTimer(spellIndex, playerName, duration, timerType, initialDuration, expiry)
	else
		service:EnsureNamedTimer(timerName, duration, timerType, playerName, initialDuration, expiry)
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
	local cachedId = timerName and TRACKED_BUFF_ACTIVE_IDS[timerName]
	if cachedId then
		buffConfig.cachedId = cachedId
	end
	local buffId, timeLeft = Necrosis_FindPlayerBuff(searchName, buffConfig)
	if cachedId then
		buffConfig.cachedId = nil
	end
	if not buffId or timeLeft <= 0 then
		if timerName then
			TRACKED_BUFF_ACTIVE_IDS[timerName] = nil
			TRACKED_BUFF_ACTIVE_NAMES[timerName] = nil
		end
		return false, timerName
	end
	if timerName then
		TRACKED_BUFF_ACTIVE_IDS[timerName] = buffId
		TRACKED_BUFF_ACTIVE_NAMES[timerName] = timerName
		local textureSet = buffConfig.buffTextureSet
		if not textureSet then
			textureSet = {}
			buffConfig.buffTextureSet = textureSet
		end
		local activeTexture = GetPlayerBuffTexture(buffId)
		if activeTexture and activeTexture ~= "" then
			textureSet[activeTexture] = true
		end
	end
	local durationSeconds = floor(timeLeft)
	local expiry = floor(currentTime + durationSeconds)
	local timerType = buffConfig.timerType or (data and data.Type) or TIMER_TYPE.SELF_BUFF
	if timerType == TIMER_TYPE.COOLDOWN then
		timerType = TIMER_TYPE.SELF_BUFF
	end
	local expectedDuration = buffConfig.expectedDuration
	if data and data.Length and data.Length > 0 then
		if not expectedDuration or data.Length > expectedDuration then
			expectedDuration = data.Length
		end
	end
	local baseDuration = buffConfig.baseDuration or 0
	if expectedDuration and expectedDuration > 0 then
		if baseDuration <= 0 or baseDuration > (expectedDuration + 5) then
			baseDuration = expectedDuration
		end
	end
	local storedDuration = Necrosis_GetStoredBuffDuration(timerName)
	if storedDuration and storedDuration > 0 then
		if baseDuration <= 0 then
			baseDuration = storedDuration
		elseif storedDuration > baseDuration + 5 then
			baseDuration = storedDuration
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
	if NecrosisSpellTimersEnabled == false then
		return false
	end
	if NecrosisConfig.ShowSpellTimers or NecrosisConfig.Graphical then
		return true
	end
	return false
end

function Necrosis_ShouldUseSpellTimers()
	return Necrosis_ShouldUseSpellTimersInternal()
end

function Necrosis_MarkTextTimersDirty()
	local service = getTimerService()
	if service then
		service:MarkTextDirty()
	end
end

local function Necrosis_ClearExpiredTimers(curTime, targetName)
	local service = getTimerService()
	if service then
		service:ClearExpiredTimers(curTime, targetName)
	end
end

local function Necrosis_ResetTimerAssignments()
	local service = getTimerService()
	if service then
		service:ResetTimerAssignments()
	end
end

local function Necrosis_RebuildTimerBuffers(_, curTime, buildText)
	local service = getTimerService()
	if not service then
		return 0
	end
	return service:BuildDisplayData(curTime, buildText)
end

local function Necrosis_RefreshGraphicalSlots()
	-- managed by timer service
end

function Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	if not Necrosis_ShouldUseSpellTimersInternal() then
		return
	end
	if not shouldUpdate then
		return
	end

	local service = getTimerService()
	if not service then
		return
	end

	curTime = curTime or GetTime()

	local targetName = UnitName("target")
	local textVisible = NecrosisConfig.ShowSpellTimers
		and not NecrosisConfig.Graphical
		and NecrosisSpellTimerButton:IsVisible()
	local curTimeFloor = floor(curTime)
	local buildText = textVisible and (service:IsTextDirty() or curTimeFloor ~= service:GetLastTextBuildTime())

	Necrosis_ClearExpiredTimers(curTime, targetName)
	Necrosis_ResetTimerAssignments()
	service:BuildDisplayData(curTime, buildText)

	if NecrosisConfig.Graphical then
		local graphData = service:GetGraphicalData()
		Necrosis_DisplayTimerFrames(graphData, service.timerSlots)
	end
end

function Necrosis_UpdateTimerDisplay()
	local service = getTimerService()
	local shouldDisplay = Necrosis_ShouldUseSpellTimersInternal()
	if shouldDisplay then
		if not NecrosisSpellTimerButton:IsVisible() then
			ShowUIPanel(NecrosisSpellTimerButton)
			if NecrosisConfig.ShowSpellTimers and service then
				service:MarkTextDirty()
			end
		end
		if NecrosisConfig.ShowSpellTimers and not NecrosisConfig.Graphical then
			NecrosisListSpells:SetText(service and service:GetColoredDisplay() or "")
		else
			NecrosisListSpells:SetText("")
		end
	elseif NecrosisSpellTimerButton:IsVisible() then
		NecrosisListSpells:SetText("")
		HideUIPanel(NecrosisSpellTimerButton)
		if service then
			service:MarkTextDirty()
		end
	end
end

function Necrosis_UpdateTimerEventRegistration()
	NecrosisTimerEventsDirty = false
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

function Necrosis_UpdateTrackedBuffTimers(_, curTime)
	if not Necrosis_ShouldUseSpellTimersInternal() then
		return
	end

	local service = getTimerService()
	if not service then
		return
	end

	curTime = curTime or GetTime()

	if TRACKED_BUFFS_DIRTY then
		if TRACKED_BUFF_LAST_SIGNAL > 0 and (curTime - TRACKED_BUFF_LAST_SIGNAL) < TRACKED_BUFF_MIN_DELAY then
			return
		end
	elseif TRACKED_BUFF_LAST_SCAN > 0 and (curTime - TRACKED_BUFF_LAST_SCAN) < TRACKED_BUFF_WATCHDOG_SECONDS then
		return
	end

	TRACKED_BUFF_LAST_SCAN = curTime
	TRACKED_BUFFS_DIRTY = false

	local playerName = UnitName("player") or ""
	local tracked = TRACKED_SELF_BUFFS
	local trackedCount = TRACKED_SELF_BUFF_COUNT or 0
	if not tracked or trackedCount == 0 then
		tracked = DEFAULT_TRACKED_SELF_BUFFS
		if tracked then
			Necrosis_SetTrackedBuffs(tracked)
			tracked = TRACKED_SELF_BUFFS
			trackedCount = TRACKED_SELF_BUFF_COUNT or 0
		end
	end
	if not tracked or trackedCount == 0 then
		return
	end

	for index = 1, trackedCount do
		local buffConfig = tracked[index]
		if buffConfig then
			local timerName = Necrosis_GetTrackedBuffTimerName(buffConfig)
			local cachedId = timerName and TRACKED_BUFF_ACTIVE_IDS[timerName]
			if cachedId then
				buffConfig.cachedId = cachedId
			end
			local handled, resolvedName = Necrosis_RefreshSelfBuffTimer(buffConfig, playerName, curTime)
			if cachedId then
				buffConfig.cachedId = nil
			end
			local activeName = resolvedName or timerName
			if not handled then
				activeName = activeName or Necrosis_GetTrackedBuffTimerName(buffConfig)
				if activeName then
					TRACKED_BUFF_ACTIVE_IDS[activeName] = nil
					TRACKED_BUFF_ACTIVE_NAMES[activeName] = nil
					if service:TimerExists(activeName) then
						service:RemoveTimerByName(activeName)
						if DEBUG_TIMER_EVENTS then
							Necrosis_DebugPrint("BUFF fallback", activeName, "removed (buff missing)")
						end
					end
				end
			end
		end
	end
end

function Necrosis_OnPlayerAuraEvent(_, unitId)
	local service = getTimerService()
	if not service then
		return
	end
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
	markTrackedBuffsDirty(currentTime)
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
			if timerName then
				TRACKED_BUFF_ACTIVE_IDS[timerName] = nil
				TRACKED_BUFF_ACTIVE_NAMES[timerName] = nil
				if service:TimerExists(timerName) then
					service:RemoveTimerByName(timerName)
					if DEBUG_TIMER_EVENTS then
						Necrosis_DebugPrint("UNIT_AURA", timerName, "buff missing; removed timer")
					end
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
	markTrackedBuffsDirty(LastRefreshedBuffTime)
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
