------------------------------------------------------------------------------------------------------
-- Necrosis Timer Service
------------------------------------------------------------------------------------------------------

NecrosisTimerService = NecrosisTimerService or {}

local TimerService = NecrosisTimerService

local floor = math.floor
local table_getn = table.getn
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local math_mod = math.mod

if not math_mod then
	math_mod = math.fmod
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
	local spellData = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[spellIndex]
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
	markTextDirty(service)
end

local function sortTimers(service)
	local timers = service.timers
	if not timers then
		return
	end
	table_sort(timers, function(left, right)
		if not left then
			return false
		end
		if not right then
			return true
		end
		local leftTime = left.TimeMax
		if type(leftTime) ~= "number" or leftTime <= 0 then
			leftTime = math.huge
		end
		local rightTime = right.TimeMax
		if type(rightTime) ~= "number" or rightTime <= 0 then
			rightTime = math.huge
		end
		if leftTime == rightTime then
			local leftName = left.Name or ""
			local rightName = right.Name or ""
			return leftName < rightName
		end
		return leftTime < rightTime
	end)
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
			if timeRemaining and timeRemaining > 0 and timeRemaining > newInitial then
				newInitial = timeRemaining
			end
			timer.InitialDuration = newInitial > 0 and newInitial or nil
			timer.Time = newInitial or 0
			if expiryTime then
				timer.TimeMax = expiryTime
			end
			if timerType then
				timer.Type = timerType
			end
			timer.Target = target
			resetTimerDisplayCache(service, timer)
			sortTimers(service)
			return true
		end
	end
	return false
end

local function buildTimerView(service, graphData, textBuffer, timer, currentTime, buildText, graphIndex)
	if not timer then
		return graphIndex
	end

	local expiry = timer.TimeMax or 0
	if currentTime > expiry then
		return graphIndex
	end

	local seconds
	if NECROSIS_SPELL_TABLE and timer.Name == (NECROSIS_SPELL_TABLE[10] and NECROSIS_SPELL_TABLE[10].Name) then
		seconds = currentTime - (expiry - timer.Time)
	else
		seconds = expiry - currentTime
	end

	local minutes = floor(seconds / 60)
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
	seconds = math_mod(seconds, 60)
	if seconds > 9 then
		timeText = timeText .. seconds
	else
		timeText = timeText .. "0" .. seconds
	end

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
		local expected = timer.Name .. " Cooldown"
		if timer.DisplayName ~= expected then
			timer.DisplayName = expected
		end
		displayName = timer.DisplayName
	else
		timer.DisplayName = nil
		displayName = timer.Name or ""
	end

	local targetName = timer.Target or ""
	local shouldShowTarget = (
		timer.Type == TIMER_TYPE.PRIMARY or (NECROSIS_SPELL_TABLE[16] and timer.Name == NECROSIS_SPELL_TABLE[16].Name)
	) and targetName ~= ""
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
		local colorCode = NecrosisTimerColor and NecrosisTimerColor(percent) or ""
		local suffix = " - " .. COLOR_CLOSE .. colorCode .. displayName .. COLOR_CLOSE
		if shouldShowTarget then
			suffix = suffix .. COLOR_WHITE .. " - " .. targetName .. COLOR_CLOSE
		end
		timer.cachedDisplaySuffix = suffix .. "\n"
		timer.cachedPercentBucket = percentBucket
		timer.cachedDisplayName = displayName
		timer.cachedShowTarget = shouldShowTarget
		timer.cachedTarget = shouldShowTarget and targetName or ""
	end

	if buildText then
		textBuffer[table_getn(textBuffer) + 1] = COLOR_WHITE .. timeText .. (timer.cachedDisplaySuffix or "\n")
	end

	local timerLabel = timeText
	if shouldShowTarget then
		if NecrosisConfig and NecrosisConfig.SpellTimerPos == 1 then
			timerLabel = timerLabel .. " - " .. targetName
		else
			timerLabel = targetName .. " - " .. timerLabel
		end
	end

	graphIndex = graphIndex + 1
	graphData.names[graphIndex] = displayName
	graphData.expiryTimes[graphIndex] = expiry or currentTime
	local displayDuration = totalDuration and totalDuration > 0 and totalDuration or (remaining > 0 and remaining or 1)
	graphData.initialDurations[graphIndex] = displayDuration
	graphData.displayLines[graphIndex] = timerLabel
	graphData.slotIds[graphIndex] = assignGraphicalSlot(service, timer)

	if NecrosisConfig and NecrosisConfig.CountType == 3 then
		if NECROSIS_SPELL_TABLE and timer.Name == (NECROSIS_SPELL_TABLE[11] and NECROSIS_SPELL_TABLE[11].Name) then
			if minutes > 0 then
				NecrosisShardCount:SetText(minutes .. " m")
			else
				NecrosisShardCount:SetText(seconds)
			end
		end
	end
	if NecrosisConfig and NecrosisConfig.Circle == 2 then
		if NECROSIS_SPELL_TABLE and timer.Name == (NECROSIS_SPELL_TABLE[11] and NECROSIS_SPELL_TABLE[11].Name) then
			if minutes >= 16 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Turquoise\\Shard" .. minutes - 15)
			elseif minutes >= 1 or seconds >= 33 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Orange\\Shard" .. minutes + 1)
			else
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Rose\\Shard" .. seconds)
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
		local data = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[spellIndex]
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

function TimerService:RemoveTimerByIndex(index)
	local timers = self.timers
	local timer = timers[index]
	if not timer then
		return timers, self.timerSlots
	end
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
			return self:RemoveTimerByIndex(index)
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
				self:RemoveTimerByIndex(index)
			end
		end
	end
	return timers, self.timerSlots
end

function TimerService:TimerExists(name)
	if not name then
		return false
	end
	local timers = self.timers
	for index = 1, table_getn(timers) do
		if timers[index].Name == name then
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
	local soulstoneName = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[11] and NECROSIS_SPELL_TABLE[11].Name
	local enslaveName = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[10] and NECROSIS_SPELL_TABLE[10].Name
	local demonArmorName = NECROSIS_SPELL_TABLE and NECROSIS_SPELL_TABLE[17] and NECROSIS_SPELL_TABLE[17].Name
	for index = table_getn(timers), 1, -1 do
		local timer = timers[index]
		if timer then
			local name = timer.Name
			local timeMax = timer.TimeMax or 0
			if currentTime >= (timeMax - 0.5) and timeMax ~= -1 then
				if soulstoneName and name == soulstoneName then
					Necrosis_Msg(NECROSIS_MESSAGE.Information.SoulstoneEnd, "USER")
					timer.Target = ""
					timer.TimeMax = -1
					if NecrosisConfig.Sound then
						PlaySoundFile(NECROSIS_SOUND.SoulstoneEnd)
					end
					if timer.Gtimer then
						self.timerSlots = Necrosis_RemoveTimerFrame(timer.Gtimer, self.timerSlots)
					end
					Necrosis_UpdateIcons()
				elseif not (enslaveName and name == enslaveName) then
					self:RemoveTimerByIndex(index)
				end
			else
				if demonArmorName and name == demonArmorName and not Necrosis_UnitHasEffect("player", name) then
					self:RemoveTimerByIndex(index)
				elseif
					(timer.Type == TIMER_TYPE.CURSE or timer.Type == TIMER_TYPE.COMBAT)
					and timer.Target == targetName
					and currentTime >= ((timer.TimeMax - timer.Time) + 1.5)
				then
					if not Necrosis_UnitHasEffect("target", name or timer.Name) then
						self:RemoveTimerByIndex(index)
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
	for index = table_getn(textBuffer), 1, -1 do
		textBuffer[index] = nil
	end

	local graphData = self.graphical
	local previousActive = graphData.activeCount or 0
	local graphCount = 0
	local curTimeFloor = floor(currentTime)

	for index = 1, table_getn(timers) do
		local timer = timers[index]
		if timer then
			graphCount = buildTimerView(self, graphData, textBuffer, timer, curTimeFloor, buildText, graphCount)
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
