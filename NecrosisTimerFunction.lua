------------------------------------------------------------------------------------------------------
-- Necrosis Timer Service
------------------------------------------------------------------------------------------------------

NecrosisTimerService = NecrosisTimerService or {}

local TimerService = NecrosisTimerService
local Spells = Necrosis.Spells
local Loc = Necrosis.Loc
local SpellIndex = Spells.Index

local floor = math.floor
local table_getn = table.getn
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local math_mod = math.mod
local math_huge = math.huge or 1e9
local unpack = unpack
local wipe_table = NecrosisUtils and NecrosisUtils.WipeTable

if not math_mod then
	math_mod = math.fmod
end

-- Spell name cache to avoid repeated lookups in hot path
local cachedSpellNames = {}

local function getSpellName(index)
	local data = Spells and Spells:Get(index)
	return data and data.Name
end

local function getCachedSpellName(spellIndex)
	if not cachedSpellNames[spellIndex] then
		cachedSpellNames[spellIndex] = getSpellName(spellIndex)
	end
	return cachedSpellNames[spellIndex]
end

function Necrosis_InvalidateSpellNameCache()
	cachedSpellNames = {}
end

-- Pre-calculated timer color codes (percent is quantized to 10% buckets)
-- Buckets: 0=0-9%, 1=10-19%, 2=20-29%, ..., 10=90-100%
local TIMER_COLOR_CODES = {}

-- Reusable string builder buffer for timer suffix construction
local suffixParts = {}

-- Reusable soulstone tracker to avoid allocation every BuildDisplayData call
local soulstoneTracker = { displayed = false }

local function InitializeTimerColorCodes()
	if not NecrosisTimerColor then
		return
	end
	for i = 0, 10 do
		TIMER_COLOR_CODES[i] = NecrosisTimerColor(i * 10) or ""
	end
end

local function buildTimerSuffix(colorCode, displayName, shouldShowTarget, targetName)
	-- Ensure all values are strings (COLOR_CLOSE/COLOR_WHITE may not be initialized yet)
	local closeCode = COLOR_CLOSE or ""
	local whiteCode = COLOR_WHITE or ""

	suffixParts[1] = " - "
	suffixParts[2] = closeCode
	suffixParts[3] = colorCode or ""
	suffixParts[4] = displayName or ""
	suffixParts[5] = closeCode

	local endIndex = 5
	if shouldShowTarget then
		suffixParts[6] = whiteCode
		suffixParts[7] = " - "
		suffixParts[8] = targetName or ""
		suffixParts[9] = closeCode
		endIndex = 9
	end

	local suffix = table.concat(suffixParts, "", 1, endIndex)

	-- Clear buffer for reuse
	for i = 1, 9 do
		suffixParts[i] = nil
	end

	return suffix .. "\n"
end

local function isTimerDebugEnabled()
	if DEBUG_TIMER_EVENTS then
		return true
	end
	local config = NecrosisConfig
	if type(config) == "table" then
		if config.DebugTimers or config.DiagnosticsEnabled then
			return true
		end
	end
	return false
end

local function debugTimerEvent(action, name, ...)
	if not isTimerDebugEnabled() then
		return
	end
	local debugPrinter = Necrosis_DebugPrint
	if type(debugPrinter) ~= "function" then
		return
	end
	local params = arg
	local paramCount = params and params.n or 0
	if paramCount == 0 then
		debugPrinter("TimerService", action or "<nil>", name or "<nil>")
		return
	end
	local detailsBuffer = TimerService.debugDetailsBuffer
	if not detailsBuffer then
		detailsBuffer = {}
		TimerService.debugDetailsBuffer = detailsBuffer
	end
	local labelCount = 0
	for index = 1, paramCount, 2 do
		local key = params[index]
		local value = params[index + 1]
		labelCount = labelCount + 1
		local keyText = key ~= nil and tostring(key) or "<nil>"
		if value == nil then
			detailsBuffer[labelCount] = keyText .. "=<nil>"
		else
			detailsBuffer[labelCount] = keyText .. "=" .. tostring(value)
		end
	end
	for index = labelCount + 1, TimerService.debugDetailsCount do
		detailsBuffer[index] = nil
	end
	TimerService.debugDetailsCount = labelCount
	detailsBuffer[labelCount + 1] = nil
	debugPrinter("TimerService", action or "<nil>", name or "<nil>", unpack(detailsBuffer))
end

local TIMER_TYPE = NECROSIS_TIMER_TYPE or {}
local COLOR_CODES = NECROSIS_COLOR_CODES or {}
local COLOR_WHITE = COLOR_CODES.white or ""
local COLOR_CLOSE = COLOR_CODES.close or ""

TimerService.timers = TimerService.timers or {}
TimerService.timerSlots = TimerService.timerSlots or {}
TimerService.graphical = TimerService.graphical
	or {
		activeCount = 0,
		names = {},
		expiryTimes = {},
		initialDurations = {},
		displayLines = {},
		slotIds = {},
	}
TimerService.textSegments = TimerService.textSegments or {}
TimerService.textDisplay = TimerService.textDisplay or ""
TimerService.coloredDisplay = TimerService.coloredDisplay or ""
TimerService.textDirty = TimerService.textDirty ~= false
TimerService.lastTextBuildTime = TimerService.lastTextBuildTime or 0
TimerService.reusableEnsureOptions = TimerService.reusableEnsureOptions or {}
TimerService.reusableTextureCache = TimerService.reusableTextureCache or {}
TimerService.debugDetailsBuffer = TimerService.debugDetailsBuffer or {}
TimerService.debugDetailsCount = TimerService.debugDetailsCount or 0
TimerService.timeTextCache = TimerService.timeTextCache or {}
local reusableTextureCache = TimerService.reusableTextureCache
local debugDetailsBuffer = TimerService.debugDetailsBuffer
local timeTextCache = TimerService.timeTextCache

local function clear_table(t)
	if not t then
		return
	end
	if wipe_table then
		wipe_table(t)
	else
		for key in pairs(t) do
			t[key] = nil
		end
	end
end

local function getReusableTextureCache()
	clear_table(reusableTextureCache)
	return reusableTextureCache
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

local function getTextureForBuff(cache, buffName)
	if not buffName then
		return nil
	end
	local cached = cache[buffName]
	if cached ~= nil then
		return cached ~= false and cached or nil
	end
	local texture = safeGetSpellTexture(buffName)
	cache[buffName] = texture or false
	return texture
end

local function playerHasSelfBuff(cache, buffName)
	if not buffName then
		return false
	end
	local expectedTexture = getTextureForBuff(cache, buffName)
	local index = 0
	while true do
		local buffId = GetPlayerBuff(index, "HELPFUL")
		if not buffId or buffId == -1 then
			break
		end
		local texture = GetPlayerBuffTexture(buffId)
		if expectedTexture and texture == expectedTexture then
			return true
		end
		index = index + 1
	end
	if expectedTexture then
		return false
	end
	local checker
	if type(Necrosis_UnitHasBuff) == "function" then
		checker = Necrosis_UnitHasBuff
	elseif type(Necrosis_UnitHasEffect) == "function" then
		checker = Necrosis_UnitHasEffect
	end
	if not checker then
		return true
	end
	return checker("player", buffName) and true or false
end

local function getTimeText(secondsValue, minutes, secondsComponent)
	if secondsValue < 0 then
		secondsValue = 0
	end
	local cached = timeTextCache[secondsValue]
	if cached then
		return cached
	end
	local timeText
	if minutes > 0 then
		if minutes > 9 then
			timeText = tostring(minutes) .. ":"
		else
			timeText = "0" .. minutes .. ":"
		end
	else
		timeText = "0:"
	end
	if secondsComponent > 9 then
		timeText = timeText .. secondsComponent
	else
		timeText = timeText .. "0" .. secondsComponent
	end
	timeTextCache[secondsValue] = timeText
	return timeText
end

------------------------------------------------------------------------------------------------------
-- INTERNAL HELPERS
------------------------------------------------------------------------------------------------------

local function ensureTimerSlotTable(service)
	local slots = service.timerSlots
	if table_getn(slots) == 0 then
		for index = 1, 50 do
			slots[index] = false
		end
	end
end

local function resetEnsureOptions(service)
	local options = service.reusableEnsureOptions
	options.spellIndex = nil
	options.name = nil
	options.duration = nil
	options.timerType = nil
	options.target = nil
	options.initial = nil
	options.expiry = nil
	return options
end

local function shouldSkipSpellTimer(spellIndex)
	if not spellIndex then
		return false
	end
	local spellData = Spells and Spells:Get(spellIndex)
	if not spellData then
		return false
	end
	if spellIndex == 13 then
		-- Preserve Fear timer handling
		return false
	end
	local timerType = spellData.Type
	if timerType == TIMER_TYPE.CURSE or timerType == TIMER_TYPE.COMBAT then
		return true
	end
	return false
end

local function markTextDirty(service)
	service.textDirty = true
end

local function resetTimerDisplayCache(service, timer)
	if not timer then
		return
	end
	timer.cachedDisplaySuffix = nil
	timer.cachedPercentBucket = nil
	timer.cachedDisplayName = nil
	timer.cachedShowTarget = nil
	timer.cachedTarget = nil
	timer.cachedTimeText = nil
	timer.cachedTimeSeconds = nil
	timer.cachedTextLine = nil
	timer.cachedGraphLabel = nil
	markTextDirty(service)
end

local function compareTimers(left, right)
	if not left then
		return false
	end
	if not right then
		return true
	end
	local leftTime = left.TimeMax
	if type(leftTime) ~= "number" or leftTime <= 0 then
		leftTime = math_huge
	end
	local rightTime = right.TimeMax
	if type(rightTime) ~= "number" or rightTime <= 0 then
		rightTime = math_huge
	end
	if leftTime == rightTime then
		local leftName = left.Name or ""
		local rightName = right.Name or ""
		return leftName < rightName
	end
	return leftTime < rightTime
end

local function sortTimers(service)
	local timers = service.timers
	if not timers then
		return
	end
	table_sort(timers, compareTimers)
end

local function assignGraphicalSlot(service, timer)
	if not timer then
		return 0
	end
	if timer.Gtimer and timer.Gtimer ~= 0 then
		return timer.Gtimer
	end
	ensureTimerSlotTable(service)
	local slots = service.timerSlots
	local slotCount = table_getn(slots)
	for slot = 1, slotCount do
		if not slots[slot] then
			slots[slot] = true
			timer.Gtimer = slot
			if type(Necrosis_ShowTimerFrame) == "function" then
				Necrosis_ShowTimerFrame(slot)
			end
			return slot
		end
	end
	local newIndex = slotCount + 1
	slots[newIndex] = true
	timer.Gtimer = newIndex
	if type(Necrosis_ShowTimerFrame) == "function" then
		Necrosis_ShowTimerFrame(newIndex)
	end
	return newIndex
end

local function updateTimerEntry(service, name, target, timeRemaining, expiryTime, timerType, initialDuration)
	local timers = service.timers
	if not timers or not name then
		return false
	end

	target = target or ""
	local now = GetTime()
	if not expiryTime and timeRemaining and timeRemaining > 0 then
		expiryTime = floor(now + timeRemaining)
	end

	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer and timer.Name == name and timer.Target == target then
			local previousInitial = timer.InitialDuration or timer.Time
			local newInitial = initialDuration
			if not newInitial or newInitial <= 0 then
				if previousInitial and previousInitial > 0 then
					newInitial = previousInitial
				elseif timer.Time and timer.Time > 0 then
					newInitial = timer.Time
				elseif timeRemaining and timeRemaining > 0 then
					newInitial = timeRemaining
				else
					newInitial = 0
				end
			end
			-- preserve known initial duration; don't replace it with the remaining time
			timer.InitialDuration = newInitial > 0 and newInitial or nil
			timer.Time = newInitial or 0
			if expiryTime then
				timer.TimeMax = expiryTime
			end
			if timerType then
				timer.Type = timerType
			end
			timer.Target = target
			debugTimerEvent(
				"update",
				name,
				"target",
				target or "",
				"expiry",
				timer.TimeMax or expiryTime or "",
				"remaining",
				timeRemaining or 0,
				"initial",
				timer.InitialDuration or 0
			)
			resetTimerDisplayCache(service, timer)
			sortTimers(service)
			return true
		end
	end
	return false
end

local function buildTimerView(
	service,
	graphData,
	textBuffer,
	timer,
	currentTime,
	buildText,
	graphIndex,
	soulstoneTracker
)
	if not timer then
		return graphIndex
	end

	local expiry = timer.TimeMax or 0
	if currentTime > expiry then
		return graphIndex
	end

	local secondsValue
	local enslaveName = getCachedSpellName(SpellIndex.ENSLAVE_DEMON)
	if enslaveName and timer.Name == enslaveName then
		secondsValue = currentTime - (expiry - timer.Time)
	else
		secondsValue = expiry - currentTime
	end

	if secondsValue < 0 then
		secondsValue = 0
	end
	local minutes = floor(secondsValue / 60)
	local secondsComponent = math_mod(secondsValue, 60)

	if timer.cachedTimeSeconds ~= secondsValue then
		local timeText = getTimeText(secondsValue, minutes, secondsComponent)
		timer.cachedTimeSeconds = secondsValue
		timer.cachedTimeText = timeText
		timer.cachedTextLine = nil
		timer.cachedGraphLabel = nil
		if not buildText then
			markTextDirty(service)
		end
	end
	local timeText = timer.cachedTimeText or getTimeText(secondsValue, minutes, secondsComponent)

	local remaining = 0
	if expiry then
		remaining = expiry - currentTime
		if remaining < 0 then
			remaining = 0
		end
	end
	local totalDuration = timer.InitialDuration or timer.Time
	local percent = 0
	if totalDuration and totalDuration > 0 then
		percent = (remaining / totalDuration) * 100
		if percent < 0 then
			percent = 0
		elseif percent > 100 then
			percent = 100
		end
	end
	local percentBucket = floor(percent / 10)
	if percentBucket < 0 then
		percentBucket = 0
	elseif percentBucket > 10 then
		percentBucket = 10
	end

	local displayName
	if timer.Type == TIMER_TYPE.COOLDOWN and timer.Name and timer.Name ~= "" then
		local cooldownLabel = (NECROSIS_COOLDOWN and NECROSIS_COOLDOWN.Label) or "Cooldown"
		local expected = timer.Name .. " " .. cooldownLabel
		if timer.DisplayName ~= expected then
			timer.DisplayName = expected
		end
		displayName = timer.DisplayName
	else
		timer.DisplayName = nil
		displayName = timer.Name or ""
	end

	local targetName = timer.Target or ""
	local banishName = getCachedSpellName(SpellIndex.CURSE_OF_DOOM)
	local shouldShowTarget = (timer.Type == TIMER_TYPE.PRIMARY or (banishName and timer.Name == banishName))
		and targetName ~= ""
	local needsSuffixUpdate = timer.cachedDisplaySuffix == nil
	if not needsSuffixUpdate and timer.cachedPercentBucket ~= percentBucket then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and timer.cachedDisplayName ~= displayName then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and timer.cachedShowTarget ~= shouldShowTarget then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and shouldShowTarget and timer.cachedTarget ~= targetName then
		needsSuffixUpdate = true
	end
	if needsSuffixUpdate then
		local colorCode = TIMER_COLOR_CODES[percentBucket] or ""
		timer.cachedDisplaySuffix = buildTimerSuffix(colorCode, displayName, shouldShowTarget, targetName)
		timer.cachedPercentBucket = percentBucket
		timer.cachedDisplayName = displayName
		timer.cachedShowTarget = shouldShowTarget
		timer.cachedTarget = shouldShowTarget and targetName or ""
		timer.cachedTextLine = nil
		timer.cachedGraphLabel = nil
	end

	if buildText then
		local textLine = timer.cachedTextLine
		if not textLine then
			textLine = COLOR_WHITE .. timeText .. (timer.cachedDisplaySuffix or "\n")
			timer.cachedTextLine = textLine
		end
		textBuffer[table_getn(textBuffer) + 1] = textLine
	end

	local timerLabel = timer.cachedGraphLabel
	if not timerLabel then
		timerLabel = timeText
		if shouldShowTarget then
			if NecrosisConfig and NecrosisConfig.SpellTimerPos == 1 then
				timerLabel = timerLabel .. " - " .. targetName
			else
				timerLabel = targetName .. " - " .. timerLabel
			end
		end
		timer.cachedGraphLabel = timerLabel
	end

	graphIndex = graphIndex + 1
	graphData.names[graphIndex] = displayName
	graphData.expiryTimes[graphIndex] = expiry or currentTime
	local displayDuration = totalDuration and totalDuration > 0 and totalDuration or (remaining > 0 and remaining or 1)
	graphData.initialDurations[graphIndex] = displayDuration
	graphData.displayLines[graphIndex] = timerLabel
	graphData.slotIds[graphIndex] = assignGraphicalSlot(service, timer)

	local soulstoneName = getSpellName(SpellIndex.SOULSTONE_RESURRECTION)
	if NecrosisConfig and NecrosisConfig.CountType == 3 then
		if soulstoneName and timer.Name == soulstoneName then
			if type(Necrosis_UpdateShardCountTimer) == "function" then
				Necrosis_UpdateShardCountTimer(minutes, secondsComponent)
			elseif minutes > 0 then
				NecrosisShardCount:SetText(minutes .. " m")
			else
				NecrosisShardCount:SetText(secondsComponent)
			end
			if soulstoneTracker then
				soulstoneTracker.displayed = true
			end
		end
	end
	if NecrosisConfig and NecrosisConfig.Circle == 2 then
		if soulstoneName and timer.Name == soulstoneName then
			if minutes >= 16 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Turquoise\\Shard" .. minutes - 15)
			elseif minutes >= 1 or secondsComponent >= 33 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Orange\\Shard" .. minutes + 1)
			else
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Rose\\Shard" .. secondsComponent)
			end
		end
	end

	return graphIndex
end

------------------------------------------------------------------------------------------------------
-- TIMER SERVICE METHODS
------------------------------------------------------------------------------------------------------

function TimerService:GetTimers()
	return self.timers
end

function TimerService:GetTimerCount()
	return table_getn(self.timers)
end

function TimerService:GetTimerAt(index)
	return self.timers[index]
end

function TimerService:IterateTimers(callback)
	if type(callback) ~= "function" then
		return
	end
	local timers = self.timers
	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer ~= nil then
			local shouldContinue = callback(timer, index)
			if shouldContinue == false then
				break
			end
		end
	end
end

function TimerService:UpdateTimerEntry(name, target, timeRemaining, expiryTime, timerType, initialDuration)
	return updateTimerEntry(self, name, target, timeRemaining, expiryTime, timerType, initialDuration)
end

function TimerService:EnsureTimer(options)
	if type(Necrosis_ShouldUseSpellTimers) == "function" and not Necrosis_ShouldUseSpellTimers() then
		return self.timers, self.timerSlots
	end

	options = options or resetEnsureOptions(self)
	local spellIndex = options.spellIndex
	local name = options.name
	local target = options.target or ""
	local timerType = options.timerType or TIMER_TYPE.SELF_BUFF
	local duration = options.duration
	local initial = options.initial
	local expiry = options.expiry

	if spellIndex then
		local data = Spells and Spells:Get(spellIndex)
		if data then
			name = name or data.Name
			timerType = timerType or data.Type
			if duration == nil then
				duration = data.Length
			end
			if initial == nil and data.Length and data.Length > 0 then
				initial = data.Length
			end
		end
		if shouldSkipSpellTimer(spellIndex) then
			if name then
				debugTimerEvent("skip", name, "spellIndex", spellIndex)
				self:RemoveTimerByName(name)
			end
			return self.timers, self.timerSlots
		end
	end

	if not name then
		return self.timers, self.timerSlots
	end

	if duration and duration <= 0 and (not expiry or expiry <= 0) then
		return self.timers, self.timerSlots
	end

	if (not expiry or expiry <= 0) and duration and duration > 0 then
		expiry = floor(GetTime() + duration)
	end

	if initial == nil then
		initial = duration
	end

	local updated = updateTimerEntry(self, name, target, duration, expiry, timerType, initial)
	if updated then
		return self.timers, self.timerSlots
	end

	local insertDuration = initial or duration or 0
	if insertDuration < 0 then
		insertDuration = 0
	end

	local timer = {
		Name = name,
		Time = insertDuration,
		TimeMax = expiry,
		InitialDuration = insertDuration > 0 and insertDuration or nil,
		Type = timerType,
		Target = target,
	}

	table_insert(self.timers, timer)
	resetTimerDisplayCache(self, timer)
	ensureTimerSlotTable(self)
	self.timers, self.timerSlots = Necrosis_AddTimerFrame(self.timers, self.timerSlots)
	sortTimers(self)
	debugTimerEvent(
		"insert",
		name,
		"target",
		target or "",
		"type",
		timerType,
		"expiry",
		expiry,
		"duration",
		insertDuration
	)
	return self.timers, self.timerSlots
end

function TimerService:EnsureSpellIndexTimer(spellIndex, target, duration, timerType, initial, expiry)
	local options = resetEnsureOptions(self)
	options.spellIndex = spellIndex
	options.target = target
	options.duration = duration
	options.timerType = timerType
	options.initial = initial
	options.expiry = expiry
	return self:EnsureTimer(options)
end

function TimerService:EnsureNamedTimer(name, duration, timerType, target, initial, expiry)
	if not name then
		return self.timers, self.timerSlots
	end
	local options = resetEnsureOptions(self)
	options.name = name
	options.duration = duration
	options.timerType = timerType
	options.target = target
	options.initial = initial
	options.expiry = expiry
	return self:EnsureTimer(options)
end

function TimerService:InsertCustomTimer(spellName, duration, timerType, targetName, initialDuration, expiryTime)
	return self:EnsureNamedTimer(spellName, duration, timerType, targetName, initialDuration, expiryTime)
end

function TimerService:RemoveTimerByIndex(index, reason)
	local timers = self.timers
	local timer = timers[index]
	if not timer then
		return timers, self.timerSlots
	end
	debugTimerEvent("remove", timer.Name, "target", timer.Target or "", "cause", reason or "index")
	local removedSlot = timer.Gtimer
	if removedSlot then
		self.timerSlots = Necrosis_RemoveTimerFrame(removedSlot, self.timerSlots)
	end
	table_remove(timers, index)
	for nextIndex = index, table_getn(timers) do
		local nextTimer = timers[nextIndex]
		if nextTimer then
			nextTimer.Gtimer = nil
		end
	end
	markTextDirty(self)
	return timers, self.timerSlots
end

function TimerService:RemoveTimerByName(name)
	if not name then
		return self.timers, self.timerSlots
	end
	local timers = self.timers
	for index = 1, table_getn(timers) do
		if timers[index].Name == name then
			return self:RemoveTimerByIndex(index, "name")
		end
	end
	return timers, self.timerSlots
end

function TimerService:RemoveCombatTimers()
	local timers = self.timers
	for index = table_getn(timers), 1, -1 do
		local timer = timers[index]
		if timer then
			if timer.Type == TIMER_TYPE.COOLDOWN then
				timer.Target = ""
				resetTimerDisplayCache(self, timer)
			end
			if timer.Type == TIMER_TYPE.CURSE or timer.Type == TIMER_TYPE.COMBAT then
				self:RemoveTimerByIndex(index, "combat-clear")
			end
		end
	end
	return timers, self.timerSlots
end

function TimerService:RemoveAllTimers()
	local timers = self.timers
	if not timers then
		return
	end
	for index = table_getn(timers), 1, -1 do
		self:RemoveTimerByIndex(index, "clear-all")
	end
	self:ResetTimerAssignments()
	self.textDisplay = ""
	self.coloredDisplay = ""
	self.graphical.activeCount = 0
	self.lastTextBuildTime = 0
	markTextDirty(self)
end

function TimerService:TimerExists(name)
	if not name then
		return false
	end
	local timers = self.timers
	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer and timer.Name == name then
			return true
		end
	end
	return false
end

function TimerService:FindTimerByName(name, target)
	if not name then
		return nil, 0
	end
	target = target or ""
	local timers = self.timers
	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer and timer.Name == name then
			if target == "" or target == timer.Target then
				return timer, index
			end
		end
	end
	return nil, 0
end

function TimerService:UpdateTimer(name, target, mutator)
	if type(mutator) ~= "function" then
		return false
	end
	local timer, index = self:FindTimerByName(name, target)
	if not timer then
		return false
	end
	local shouldSort = mutator(timer, index)
	resetTimerDisplayCache(self, timer)
	if shouldSort ~= false then
		sortTimers(self)
	end
	return true, timer, index
end

function TimerService:ResetTimerAssignments()
	local slots = self.timerSlots
	for slot = 1, table_getn(slots) do
		if slots[slot] then
			slots = Necrosis_RemoveTimerFrame(slot, slots)
		else
			slots[slot] = false
		end
	end
	self.timerSlots = slots
	local timers = self.timers
	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer then
			timer.Gtimer = nil
		end
	end
end

function TimerService:ClearExpiredTimers(currentTime, targetName)
	local timers = self.timers
	if not timers then
		return
	end
	local soulstoneName = getSpellName(SpellIndex.SOULSTONE_RESURRECTION)
	local enslaveName = getSpellName(SpellIndex.ENSLAVE_DEMON)
	local demonArmorName = getSpellName(SpellIndex.DEMON_ARMOR)
	local demonSkinName = getSpellName(SpellIndex.DEMON_SKIN)
	local textureCache = getReusableTextureCache()
	for index = table_getn(timers), 1, -1 do
		local timer = timers[index]
		if timer then
			local name = timer.Name
			local timeMax = timer.TimeMax or 0
			if currentTime >= (timeMax - 0.5) and timeMax ~= -1 then
				if soulstoneName and name == soulstoneName then
					local message = Loc and Loc:GetMessage("Information", "SoulstoneEnd")
					if message then
						Necrosis_Msg(message, "USER")
					end
					timer.Target = ""
					timer.TimeMax = -1
					if NecrosisConfig.Sound then
						PlaySoundFile(NECROSIS_SOUND.SoulstoneEnd)
					end
					if timer.Gtimer then
						self.timerSlots = Necrosis_RemoveTimerFrame(timer.Gtimer, self.timerSlots)
					end
					Necrosis_UpdateIcons()
					debugTimerEvent("expire", name, "reason", "soulstone-end")
				elseif not (enslaveName and name == enslaveName) then
					self:RemoveTimerByIndex(index, "expired")
				end
			else
				if (demonArmorName and name == demonArmorName) or (demonSkinName and name == demonSkinName) then
					if not playerHasSelfBuff(textureCache, name) then
						self:RemoveTimerByIndex(index, "buff-missing")
					end
				elseif
					(timer.Type == TIMER_TYPE.CURSE or timer.Type == TIMER_TYPE.COMBAT)
					and timer.Target == targetName
					and currentTime >= ((timer.TimeMax - timer.Time) + 1.5)
				then
					if not Necrosis_UnitHasEffect("target", name or timer.Name) then
						self:RemoveTimerByIndex(index, "target-lost")
					end
				end
			end
		end
	end
end

function TimerService:BuildDisplayData(currentTime, buildText)
	local timers = self.timers
	if not timers then
		return 0
	end

	local textBuffer = self.textSegments
	if wipe_table then
		wipe_table(textBuffer)
	else
		for index = table_getn(textBuffer), 1, -1 do
			textBuffer[index] = nil
		end
	end

	local graphData = self.graphical
	local previousActive = graphData.activeCount or 0
	local graphCount = 0
	local curTimeFloor = floor(currentTime)
	local useTracker = NecrosisConfig and NecrosisConfig.CountType == 3
	if useTracker then
		soulstoneTracker.displayed = false
	else
		soulstoneTracker = nil
	end

	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer then
			graphCount = buildTimerView(
				self,
				graphData,
				textBuffer,
				timer,
				curTimeFloor,
				buildText,
				graphCount,
				soulstoneTracker
			)
		end
	end

	if previousActive > graphCount then
		for slotIndex = graphCount + 1, previousActive do
			graphData.names[slotIndex] = nil
			graphData.expiryTimes[slotIndex] = nil
			graphData.initialDurations[slotIndex] = nil
			graphData.displayLines[slotIndex] = nil
			graphData.slotIds[slotIndex] = nil
		end
	end
	graphData.activeCount = graphCount

	if buildText then
		self.textDisplay = table.concat(textBuffer)
		self.coloredDisplay = self.textDisplay
		self.lastTextBuildTime = curTimeFloor
		self.textDirty = false
	end

	if soulstoneTracker and not soulstoneTracker.displayed then
		if type(Necrosis_ClearShardCountTimer) == "function" then
			Necrosis_ClearShardCountTimer()
		elseif NecrosisShardCount then
			NecrosisShardCount:SetText("")
		end
	end

	return graphCount
end

function TimerService:GetGraphicalData()
	return self.graphical
end

function TimerService:GetTextDisplay()
	return self.textDisplay
end

function TimerService:GetColoredDisplay()
	return self.coloredDisplay
end

function TimerService:IsTextDirty()
	return self.textDirty
end

function TimerService:GetLastTextBuildTime()
	return self.lastTextBuildTime
end

function TimerService:MarkTextDirty()
	markTextDirty(self)
end

------------------------------------------------------------------------------------------------------
-- COMPATIBILITY WRAPPERS
------------------------------------------------------------------------------------------------------

function Necrosis_MarkTextTimersDirty()
	TimerService:MarkTextDirty()
end

function Necrosis_UpdateTimerEntry(spellTimer, name, target, timeRemaining, expiryTime, timerType, initialDuration)
	local updated = TimerService:UpdateTimerEntry(name, target, timeRemaining, expiryTime, timerType, initialDuration)
	return updated, TimerService.timers
end

function Necrosis_InsertCustomTimer(
	spellName,
	duration,
	timerType,
	targetName,
	spellTimer,
	timerTable,
	initialDuration,
	expiryTime
)
	return TimerService:InsertCustomTimer(spellName, duration, timerType, targetName, initialDuration, expiryTime)
end

function Necrosis_EnsureTimer(options, spellTimer, timerTable)
	return TimerService:EnsureTimer(options)
end

function Necrosis_EnsureSpellIndexTimer(
	spellIndex,
	target,
	duration,
	timerType,
	initial,
	expiry,
	spellTimer,
	timerTable
)
	return TimerService:EnsureSpellIndexTimer(spellIndex, target, duration, timerType, initial, expiry)
end

function Necrosis_EnsureNamedTimer(name, duration, timerType, target, initial, expiry, spellTimer, timerTable)
	return TimerService:EnsureNamedTimer(name, duration, timerType, target, initial, expiry)
end

function Necrosis_RemoveTimerByIndex(index, spellTimer, timerTable)
	return TimerService:RemoveTimerByIndex(index)
end

function Necrosis_RemoveTimerByName(name, spellTimer, timerTable)
	return TimerService:RemoveTimerByName(name)
end

function Necrosis_RemoveCombatTimers(spellTimer, timerTable)
	return TimerService:RemoveCombatTimers()
end

function Necrosis_TimerExists(name)
	return TimerService:TimerExists(name)
end

function Necrosis_SortTimers(spellTimer)
	sortTimers(TimerService)
end

function Necrosis_DisplayTimer(
	textBuffer,
	index,
	spellTimer,
	graphicalTimer,
	timerTable,
	graphCount,
	currentTime,
	buildText
)
	local timer = TimerService:GetTimerAt(index)
	if not timer then
		return timerTable, graphCount
	end
	local graphData = TimerService:GetGraphicalData()
	if graphicalTimer ~= graphData then
		graphicalTimer.names = graphData.names
		graphicalTimer.expiryTimes = graphData.expiryTimes
		graphicalTimer.initialDurations = graphData.initialDurations
		graphicalTimer.displayLines = graphData.displayLines
		graphicalTimer.slotIds = graphData.slotIds
	end
	return timerTable, graphCount
end

SpellTimer = TimerService.timers
TimerTable = TimerService.timerSlots

-- Initialize timer color codes cache when module loads
InitializeTimerColorCodes()
