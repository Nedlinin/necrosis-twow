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
-- Version 23.04.2006-1
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- INSERTION FUNCTIONS
------------------------------------------------------------------------------------------------------

SpellTimer = {}

local TIMER_TYPE = NECROSIS_TIMER_TYPE
local COLOR_CODES = NECROSIS_COLOR_CODES or {}
local COLOR_WHITE = COLOR_CODES.white or ""
local COLOR_CLOSE = COLOR_CODES.close or ""

local function Necrosis_ResetTimerDisplayCache(timer)
	if not timer then
		return
	end
	timer.cachedDisplaySuffix = nil
	timer.cachedPercentBucket = nil
	timer.cachedDisplayName = nil
	timer.cachedShowTarget = nil
	timer.cachedTarget = nil
	if type(Necrosis_MarkTextTimersDirty) == "function" then
		Necrosis_MarkTextTimersDirty()
	end
end

local function Necrosis_ShouldSkipSpellTimer(spellIndex)
	if not spellIndex then
		return false
	end
	local spellData = NECROSIS_SPELL_TABLE[spellIndex]
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

local function Necrosis_FinalizeTimerInsert(spellTimer, timerTable)
	spellTimer, timerTable = Necrosis_AddTimerFrame(spellTimer, timerTable)
	Necrosis_SortTimers(spellTimer)
	return spellTimer, timerTable
end

function Necrosis_UpdateTimerEntry(spellTimer, name, target, timeRemaining, expiryTime, timerType, initialDuration)
	if not spellTimer or not name then
		return false, spellTimer
	end

	target = target or ""
	local now = GetTime()
	if not expiryTime then
		expiryTime = floor(now + (timeRemaining or 0))
	end
	for index = 1, table.getn(spellTimer), 1 do
		local timer = spellTimer[index]
		if timer.Name == name and timer.Target == target then
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
			Necrosis_ResetTimerDisplayCache(timer)
			Necrosis_SortTimers(spellTimer)
			return true, spellTimer
		end
	end
	return false, spellTimer
end

-- For creating custom timers
function Necrosis_InsertCustomTimer(
	spellName,
	duration,
	timerType,
	targetName,
	SpellTimer,
	TimerTable,
	initialDuration,
	expiryTime
)
	return Necrosis_EnsureNamedTimer(
		spellName,
		duration,
		timerType,
		targetName,
		initialDuration,
		expiryTime,
		SpellTimer,
		TimerTable
	)
end

local Necrosis_ReusableEnsureOptions = {}

local function Necrosis_GetEnsureOptions()
	Necrosis_ReusableEnsureOptions.spellIndex = nil
	Necrosis_ReusableEnsureOptions.name = nil
	Necrosis_ReusableEnsureOptions.duration = nil
	Necrosis_ReusableEnsureOptions.timerType = nil
	Necrosis_ReusableEnsureOptions.target = nil
	Necrosis_ReusableEnsureOptions.initial = nil
	Necrosis_ReusableEnsureOptions.expiry = nil
	return Necrosis_ReusableEnsureOptions
end

function Necrosis_EnsureTimer(options, SpellTimer, TimerTable)
	if type(Necrosis_ShouldUseSpellTimers) == "function" and not Necrosis_ShouldUseSpellTimers() then
		return SpellTimer, TimerTable
	end
	options = options or Necrosis_GetEnsureOptions()
	local spellIndex = options.spellIndex
	local name = options.name
	local target = options.target or ""
	local timerType = options.timerType or TIMER_TYPE.SELF_BUFF
	local duration = options.duration
	local initial = options.initial
	local expiry = options.expiry

	if spellIndex then
		local data = NECROSIS_SPELL_TABLE[spellIndex]
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
		if Necrosis_ShouldSkipSpellTimer(spellIndex) then
			if SpellTimer and name then
				SpellTimer, TimerTable = Necrosis_RemoveTimerByName(name, SpellTimer, TimerTable)
			end
			return SpellTimer, TimerTable
		end
	end

	if not name then
		return SpellTimer, TimerTable
	end

	if duration and duration <= 0 then
		if not expiry then
			return SpellTimer, TimerTable
		end
	end

	if not expiry and duration and duration > 0 then
		expiry = floor(GetTime() + duration)
	end

	if initial == nil then
		initial = duration
	end

	local updated
	updated, SpellTimer = Necrosis_UpdateTimerEntry(SpellTimer, name, target, duration, expiry, timerType, initial)
	if updated then
		return SpellTimer, TimerTable
	end

	local insertDuration = initial or duration or 0
	if insertDuration < 0 then
		insertDuration = 0
	end

	if not SpellTimer then
		SpellTimer = {}
	end

	table.insert(SpellTimer, {
		Name = name,
		Time = insertDuration,
		TimeMax = expiry,
		InitialDuration = insertDuration > 0 and insertDuration or nil,
		Type = timerType,
		Target = target,
	})
	Necrosis_ResetTimerDisplayCache(SpellTimer[table.getn(SpellTimer)])

	return Necrosis_FinalizeTimerInsert(SpellTimer, TimerTable)
end

function Necrosis_EnsureSpellIndexTimer(
	spellIndex,
	target,
	duration,
	timerType,
	initial,
	expiry,
	SpellTimer,
	TimerTable
)
	local options = Necrosis_GetEnsureOptions()
	options.spellIndex = spellIndex
	options.target = target
	options.duration = duration
	options.timerType = timerType
	options.initial = initial
	options.expiry = expiry
	return Necrosis_EnsureTimer(options, SpellTimer, TimerTable)
end

function Necrosis_EnsureNamedTimer(name, duration, timerType, target, initial, expiry, SpellTimer, TimerTable)
	if not name then
		return SpellTimer, TimerTable
	end
	local options = Necrosis_GetEnsureOptions()
	options.name = name
	options.duration = duration
	options.timerType = timerType
	options.target = target
	options.initial = initial
	options.expiry = expiry
	return Necrosis_EnsureTimer(options, SpellTimer, TimerTable)
end

------------------------------------------------------------------------------------------------------
-- REMOVAL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Remove the timer once its index is known
function Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
	-- Remove the graphical timer
	local removedSlot = SpellTimer[index].Gtimer
	if removedSlot then
		TimerTable = Necrosis_RemoveTimerFrame(removedSlot, TimerTable)
	end

	-- Remove the timer from the list
	table.remove(SpellTimer, index)

	for i = index, table.getn(SpellTimer), 1 do
		local timer = SpellTimer[i]
		if timer then
			timer.Gtimer = nil
		end
	end
	if type(Necrosis_MarkTextTimersDirty) == "function" then
		Necrosis_MarkTextTimersDirty()
	end

	return SpellTimer, TimerTable
end

-- When a specific timer must be removed...
function Necrosis_RemoveTimerByName(name, SpellTimer, TimerTable)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index].Name == name then
			SpellTimer = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
			break
		end
	end
	return SpellTimer, TimerTable
end

-- Remove combat timers when regeneration starts
function Necrosis_RemoveCombatTimers(SpellTimer, TimerTable)
	for index = table.getn(SpellTimer), 1, -1 do
		local timer = SpellTimer[index]
		if timer then
			if timer.Type == TIMER_TYPE.COOLDOWN then
				timer.Target = ""
				Necrosis_ResetTimerDisplayCache(timer)
			end
			if timer.Type == TIMER_TYPE.CURSE or timer.Type == TIMER_TYPE.COMBAT then
				SpellTimer, TimerTable = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
			end
		end
	end

	return SpellTimer, TimerTable
end

------------------------------------------------------------------------------------------------------
-- BOOLEAN FUNCTIONS
------------------------------------------------------------------------------------------------------

function Necrosis_TimerExists(Name)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index].Name == Name then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------------------------------
-- SORTING FUNCTIONS
------------------------------------------------------------------------------------------------------

function Necrosis_SortTimers(SpellTimer)
	if not SpellTimer then
		return
	end
	table.sort(SpellTimer, function(left, right)
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

------------------------------------------------------------------------------------------------------
-- DISPLAY FUNCTIONS: STRING CREATION
------------------------------------------------------------------------------------------------------

function Necrosis_DisplayTimer(
	textBuffer,
	index,
	SpellTimer,
	GraphicalTimer,
	TimerTable,
	graphCount,
	currentTime,
	buildText
)
	-- textBuffer and graphCount let callers reuse preallocated storage between updates
	if not SpellTimer then
		return TimerTable, graphCount
	end

	local timer = SpellTimer[index]
	if not timer then
		return TimerTable, graphCount
	end

	local seconds
	if timer.Name == NECROSIS_SPELL_TABLE[10].Name then
		seconds = currentTime - (timer.TimeMax - timer.Time)
	else
		seconds = timer.TimeMax - currentTime
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
	seconds = mod(seconds, 60)
	if seconds > 9 then
		timeText = timeText .. seconds
	else
		timeText = timeText .. "0" .. seconds
	end

	local remaining = 0
	if timer.TimeMax then
		remaining = timer.TimeMax - currentTime
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
	local showTarget = (timer.Type == TIMER_TYPE.PRIMARY or timer.Name == NECROSIS_SPELL_TABLE[16].Name)
		and targetName ~= ""
	local needsSuffixUpdate = timer.cachedDisplaySuffix == nil
	if not needsSuffixUpdate and timer.cachedPercentBucket ~= percentBucket then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and timer.cachedDisplayName ~= displayName then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and timer.cachedShowTarget ~= showTarget then
		needsSuffixUpdate = true
	end
	if not needsSuffixUpdate and showTarget and timer.cachedTarget ~= targetName then
		needsSuffixUpdate = true
	end
	if needsSuffixUpdate then
		local colorCode = NecrosisTimerColor(percent) or ""
		local suffix = " - " .. COLOR_CLOSE .. colorCode .. displayName .. COLOR_CLOSE
		if showTarget then
			suffix = suffix .. COLOR_WHITE .. " - " .. targetName .. COLOR_CLOSE
		end
		timer.cachedDisplaySuffix = suffix .. "\n"
		timer.cachedPercentBucket = percentBucket
		timer.cachedDisplayName = displayName
		timer.cachedShowTarget = showTarget
		timer.cachedTarget = showTarget and targetName or ""
	end
	if buildText then
		textBuffer[table.getn(textBuffer) + 1] = COLOR_WHITE .. timeText .. (timer.cachedDisplaySuffix or "\n")
	end

	local timerLabel = timeText
	if showTarget then
		if NecrosisConfig.SpellTimerPos == 1 then
			timerLabel = timerLabel .. " - " .. targetName
		else
			timerLabel = targetName .. " - " .. timerLabel
		end
	end

	if not timer.Gtimer or timer.Gtimer == 0 then
		local assigned = false
		local slotCount = TimerTable and table.getn(TimerTable) or 0
		for slot = 1, slotCount, 1 do
			if not TimerTable[slot] then
				TimerTable[slot] = true
				timer.Gtimer = slot
				assigned = true
				break
			end
		end
		if not assigned then
			local newIndex = slotCount + 1
			if TimerTable then
				TimerTable[newIndex] = true
			end
			timer.Gtimer = newIndex
		end
		if type(Necrosis_ShowTimerFrame) == "function" then
			Necrosis_ShowTimerFrame(timer.Gtimer)
		end
	end

	graphCount = graphCount + 1
	GraphicalTimer.names[graphCount] = displayName
	GraphicalTimer.expiryTimes[graphCount] = timer.TimeMax or currentTime
	local displayDuration = totalDuration and totalDuration > 0 and totalDuration or (remaining > 0 and remaining or 1)
	GraphicalTimer.initialDurations[graphCount] = displayDuration
	GraphicalTimer.displayLines[graphCount] = timerLabel
	GraphicalTimer.slotIds[graphCount] = timer.Gtimer

	if NecrosisConfig.CountType == 3 then
		if timer.Name == NECROSIS_SPELL_TABLE[11].Name then
			if minutes > 0 then
				NecrosisShardCount:SetText(minutes .. " m")
			else
				NecrosisShardCount:SetText(seconds)
			end
		end
	end
	if NecrosisConfig.Circle == 2 then
		if timer.Name == NECROSIS_SPELL_TABLE[11].Name then
			if minutes >= 16 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Turquoise\\Shard" .. minutes - 15)
			elseif minutes >= 1 or seconds >= 33 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Orange\\Shard" .. minutes + 1)
			else
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Rose\\Shard" .. seconds)
			end
		end
	end

	if NecrosisConfig.Graphical then
		Necrosis_DisplayTimerFrames(GraphicalTimer, TimerTable)
	end

	return TimerTable, graphCount
end
