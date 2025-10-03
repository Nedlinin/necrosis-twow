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

local function wipe_table(t)
	for key in pairs(t) do
		t[key] = nil
	end
end

local BASE_GROUP_NAMES = { "Rez", "Main", "Cooldown" }
local BASE_GROUP_SUBNAMES = { " ", " ", " " }
local ReusableGroupNames = {}
local ReusableGroupSubNames = {}
local ReusableGroupVisible = {}
local ReusableGroupKeyCache = {}
-- Pool of recycled target-level lookup tables so we can avoid reallocating them each refresh
local ReusableGroupKeyBucketPool = {}

local function Necrosis_FinalizeTimerInsert(spellGroup, spellTimer, timerTable)
	spellTimer, timerTable = Necrosis_AddTimerFrame(spellTimer, timerTable)
	Necrosis_SortTimers(spellTimer, "Type")
	spellGroup, spellTimer = Necrosis_AssignTimerGroups(spellGroup, spellTimer)
	return spellGroup, spellTimer, timerTable
end

function Necrosis_UpdateTimerEntry(spellGroup, spellTimer, name, target, level, timeRemaining, expiryTime, timerType)
	if not spellTimer or not name then
		return false, spellGroup, spellTimer
	end

	target = target or ""
	level = level or ""
	local now = GetTime()
	if not expiryTime then
		expiryTime = floor(now + (timeRemaining or 0))
	end
	for index = 1, table.getn(spellTimer), 1 do
		local timer = spellTimer[index]
		if timer.Name == name and timer.Target == target and timer.TargetLevel == level then
			local originalType = timer.Type
			local originalTarget = timer.Target
			local originalLevel = timer.TargetLevel
			local originalGroup = timer.Group
			timer.Time = timeRemaining or 0
			timer.TimeMax = expiryTime
			if timerType then
				timer.Type = timerType
			end
			timer.Target = target
			timer.TargetLevel = level
			-- Avoid re-sorting and regrouping unless spell metadata actually changed
			local needsResort = timerType and timerType ~= originalType
			local needsReassign = needsResort or originalTarget ~= target or originalLevel ~= level
			if needsResort then
				Necrosis_SortTimers(spellTimer, "Type")
			end
			if needsReassign then
				spellGroup, spellTimer = Necrosis_AssignTimerGroups(spellGroup, spellTimer)
			elseif originalGroup then
				timer.Group = originalGroup
			end
			return true, spellGroup, spellTimer
		end
	end
	return false, spellGroup, spellTimer
end

-- That's what the timer table is for!
function Necrosis_InsertTimerEntry(IndexTable, Target, LevelTarget, SpellGroup, SpellTimer, TimerTable)
	if type(Necrosis_DebugPrint) == "function" then
		Necrosis_DebugPrint(
			"InsertTimer",
			"index=",
			IndexTable,
			"name=",
			NECROSIS_SPELL_TABLE[IndexTable].Name or "?",
			"target=",
			Target or ""
		)
	end

	-- Insert the entry into the table
	local name = NECROSIS_SPELL_TABLE[IndexTable].Name
	local target = Target or ""
	local level = LevelTarget or ""
	local duration = NECROSIS_SPELL_TABLE[IndexTable].Length or 0
	local expiryTime = floor(GetTime() + duration)
	local timerType = NECROSIS_SPELL_TABLE[IndexTable].Type
	local updated
	updated, SpellGroup, SpellTimer =
		Necrosis_UpdateTimerEntry(SpellGroup, SpellTimer, name, target, level, duration, expiryTime, timerType)
	if updated then
		return SpellGroup, SpellTimer, TimerTable
	end

	table.insert(SpellTimer, {
		Name = NECROSIS_SPELL_TABLE[IndexTable].Name,
		Time = duration,
		TimeMax = expiryTime,
		Type = timerType,
		Target = target,
		TargetLevel = level,
		Group = 0,
		Gtimer = nil,
	})

	return Necrosis_FinalizeTimerInsert(SpellGroup, SpellTimer, TimerTable)
end

-- And to insert the stone timer
function Necrosis_InsertStoneTimer(Stone, start, duration, SpellGroup, SpellTimer, TimerTable)
	-- Insert the entry into the table
	local name
	local timeRemaining
	local expiryTime
	local timerType = 2
	local target = ""
	local group = 2
	local inserted = false
	if Stone == "Healthstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", 120)
		end
		name = NECROSIS_COOLDOWN.Healthstone
		timeRemaining = 120
		expiryTime = floor(GetTime() + timeRemaining)
		local updated
		updated, SpellGroup, SpellTimer =
			Necrosis_UpdateTimerEntry(SpellGroup, SpellTimer, name, "", "", timeRemaining, expiryTime, timerType)
		if updated then
			return SpellGroup, SpellTimer, TimerTable
		end
		table.insert(SpellTimer, {
			Name = name,
			Time = timeRemaining,
			TimeMax = expiryTime,
			Type = timerType,
			Target = target,
			TargetLevel = "",
			Group = group,
			Gtimer = nil,
		})
		inserted = true
	elseif Stone == "Spellstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", 120)
		end
		name = NECROSIS_COOLDOWN.Spellstone
		timeRemaining = 120
		expiryTime = floor(GetTime() + timeRemaining)
		local updated
		updated, SpellGroup, SpellTimer =
			Necrosis_UpdateTimerEntry(SpellGroup, SpellTimer, name, "", "", timeRemaining, expiryTime, timerType)
		if updated then
			return SpellGroup, SpellTimer, TimerTable
		end
		table.insert(SpellTimer, {
			Name = name,
			Time = timeRemaining,
			TimeMax = expiryTime,
			Type = timerType,
			Target = target,
			TargetLevel = "",
			Group = group,
			Gtimer = nil,
		})
		inserted = true
	elseif Stone == "Soulstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", duration or "nil")
		end
		name = NECROSIS_SPELL_TABLE[11].Name
		timerType = NECROSIS_SPELL_TABLE[11].Type
		timeRemaining = floor((duration or 0) - GetTime() + (start or 0))
		expiryTime = floor((start or 0) + (duration or 0))
		target = "???"
		group = 1
		local updated
		updated, SpellGroup, SpellTimer =
			Necrosis_UpdateTimerEntry(SpellGroup, SpellTimer, name, target, "", timeRemaining, expiryTime, timerType)
		if updated then
			return SpellGroup, SpellTimer, TimerTable
		end
		table.insert(SpellTimer, {
			Name = name,
			Time = timeRemaining,
			TimeMax = expiryTime,
			Type = timerType,
			Target = target,
			TargetLevel = "",
			Group = group,
			Gtimer = nil,
		})
		inserted = true
	end

	if not inserted then
		return SpellGroup, SpellTimer, TimerTable
	end

	return Necrosis_FinalizeTimerInsert(SpellGroup, SpellTimer, TimerTable)
end

-- For creating custom timers
function Necrosis_InsertCustomTimer(
	spellName,
	duration,
	timerType,
	targetName,
	targetLevel,
	SpellGroup,
	SpellTimer,
	TimerTable
)
	local name = spellName
	local target = targetName or ""
	local level = targetLevel or ""
	local timeRemaining = duration or 0
	local expiryTime = floor(GetTime() + timeRemaining)
	local updated
	updated, SpellGroup, SpellTimer =
		Necrosis_UpdateTimerEntry(SpellGroup, SpellTimer, name, target, level, timeRemaining, expiryTime, timerType)
	if updated then
		return SpellGroup, SpellTimer, TimerTable
	end

	table.insert(SpellTimer, {
		Name = name,
		Time = timeRemaining,
		TimeMax = expiryTime,
		Type = timerType,
		Target = target,
		TargetLevel = level,
		Group = 0,
		Gtimer = nil,
	})

	return Necrosis_FinalizeTimerInsert(SpellGroup, SpellTimer, TimerTable)
end

------------------------------------------------------------------------------------------------------
-- REMOVAL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Remove the timer once its index is known
function Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
	-- Remove the graphical timer
	local Gtime = SpellTimer[index].Gtimer
	TimerTable = Necrosis_RemoveTimerFrame(Gtime, TimerTable)

	-- Remove the timer from the list
	table.remove(SpellTimer, index)

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
function Necrosis_RemoveCombatTimers(SpellGroup, SpellTimer, TimerTable)
	for index = 1, table.getn(SpellTimer), 1 do
		if SpellTimer[index] then
			-- Remove the target name when cooldowns are per-character
			if SpellTimer[index].Type == 3 then
				SpellTimer[index].Target = ""
				SpellTimer[index].TargetLevel = ""
			end
			-- Remove combat timers
			if (SpellTimer[index].Type == 4) or (SpellTimer[index].Type == 5) then
				SpellTimer = Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
			end
		end
	end

	if table.getn(SpellGroup.Name) >= 4 then
		for index = 4, table.getn(SpellGroup.Name), 1 do
			table.remove(SpellGroup.Name)
			table.remove(SpellGroup.SubName)
			table.remove(SpellGroup.Visible)
		end
	end
	return SpellGroup, SpellTimer, TimerTable
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

-- Assign each timer to its group
function Necrosis_AssignTimerGroups(SpellGroup, SpellTimer)
	SpellGroup = SpellGroup or { Name = {}, SubName = {}, Visible = {} }
	SpellGroup.Name = SpellGroup.Name or {}
	SpellGroup.SubName = SpellGroup.SubName or {}
	SpellGroup.Visible = SpellGroup.Visible or {}

	local previousNames = SpellGroup.Name
	local previousSubNames = SpellGroup.SubName
	local previousVisible = SpellGroup.Visible
	local baseName1 = previousNames and previousNames[1] or BASE_GROUP_NAMES[1]
	local baseName2 = previousNames and previousNames[2] or BASE_GROUP_NAMES[2]
	local baseName3 = previousNames and previousNames[3] or BASE_GROUP_NAMES[3]
	local baseSub1 = previousSubNames and previousSubNames[1]
	if baseSub1 == nil then
		baseSub1 = BASE_GROUP_SUBNAMES[1]
	end
	local baseSub2 = previousSubNames and previousSubNames[2]
	if baseSub2 == nil then
		baseSub2 = BASE_GROUP_SUBNAMES[2]
	end
	local baseSub3 = previousSubNames and previousSubNames[3]
	if baseSub3 == nil then
		baseSub3 = BASE_GROUP_SUBNAMES[3]
	end
	local baseVis1 = previousVisible and previousVisible[1]
	if baseVis1 == nil then
		baseVis1 = true
	end
	local baseVis2 = previousVisible and previousVisible[2]
	if baseVis2 == nil then
		baseVis2 = true
	end
	local baseVis3 = previousVisible and previousVisible[3]
	if baseVis3 == nil then
		baseVis3 = true
	end

	wipe_table(ReusableGroupNames)
	wipe_table(ReusableGroupSubNames)
	wipe_table(ReusableGroupVisible)

	-- Return previously used target buckets to the pool before rebuilding the map
	for target, bucket in pairs(ReusableGroupKeyCache) do
		if type(bucket) == "table" then
			for key in pairs(bucket) do
				bucket[key] = nil
			end
			local poolIndex = table.getn(ReusableGroupKeyBucketPool) + 1
			ReusableGroupKeyBucketPool[poolIndex] = bucket
		end
		ReusableGroupKeyCache[target] = nil
	end

	local names = ReusableGroupNames
	local subNames = ReusableGroupSubNames
	local visible = ReusableGroupVisible
	local groupByTarget = ReusableGroupKeyCache

	names[1] = baseName1
	names[2] = baseName2
	names[3] = baseName3
	subNames[1] = baseSub1
	subNames[2] = baseSub2
	subNames[3] = baseSub3
	visible[1] = baseVis1
	visible[2] = baseVis2
	visible[3] = baseVis3

	local nextGroupIndex = 4

	local function ensureGroupIndex(target, level)
		target = target or ""
		local levelValue = level ~= nil and level or ""
		-- Each target keeps a small table of level -> group index to minimize lookups
		local bucket = groupByTarget[target]
		if not bucket then
			local poolIndex = table.getn(ReusableGroupKeyBucketPool)
			if poolIndex > 0 then
				bucket = ReusableGroupKeyBucketPool[poolIndex]
				ReusableGroupKeyBucketPool[poolIndex] = nil
			else
				bucket = {}
			end
			groupByTarget[target] = bucket
		end
		local index = bucket[levelValue]
		if not index then
			index = nextGroupIndex
			nextGroupIndex = nextGroupIndex + 1
			names[index] = target
			subNames[index] = levelValue
			visible[index] = false
			bucket[levelValue] = index
		end
		return index
	end

	if SpellTimer then
		for index = 1, table.getn(SpellTimer), 1 do
			local timer = SpellTimer[index]
			if timer then
				if timer.Type and timer.Type <= 3 then
					timer.Group = timer.Type
				else
					timer.Group = ensureGroupIndex(timer.Target, timer.TargetLevel)
				end
			end
		end
	end

	SpellGroup.Name = names
	SpellGroup.SubName = subNames
	SpellGroup.Visible = visible

	if SpellTimer then
		Necrosis_SortTimers(SpellTimer, "Group")
	end
	return SpellGroup, SpellTimer
end

-- Sort timers by group
function Necrosis_SortTimers(SpellTimer, key)
	return table.sort(SpellTimer, function(SubTab1, SubTab2)
		return SubTab1[key] < SubTab2[key]
	end)
end

------------------------------------------------------------------------------------------------------
-- DISPLAY FUNCTIONS: STRING CREATION
------------------------------------------------------------------------------------------------------

function Necrosis_DisplayTimer(
	textBuffer,
	index,
	SpellGroup,
	SpellTimer,
	GraphicalTimer,
	TimerTable,
	graphCount,
	currentTime
)
	-- textBuffer and graphCount let callers reuse preallocated storage between updates
	if not SpellTimer then
		return SpellGroup, TimerTable, graphCount
	end

	local timer = SpellTimer[index]
	if not timer then
		return SpellGroup, TimerTable, graphCount
	end

	local groupIndex = timer.Group
	if
		not SpellGroup.Visible[groupIndex]
		and SpellGroup.SubName[groupIndex] ~= nil
		and SpellGroup.Name[groupIndex] ~= nil
	then
		local header = SpellGroup.Name[groupIndex] .. " " .. SpellGroup.SubName[groupIndex]
		textBuffer[table.getn(textBuffer) + 1] = "<purple>-------------------------------\n"
			.. header
			.. "\n-------------------------------<close>\n"
		graphCount = graphCount + 1
		GraphicalTimer.texte[graphCount] = header
		GraphicalTimer.TimeMax[graphCount] = 0
		GraphicalTimer.Time[graphCount] = 0
		GraphicalTimer.titre[graphCount] = true
		GraphicalTimer.temps[graphCount] = ""
		GraphicalTimer.Gtimer[graphCount] = 0
		SpellGroup.Visible[groupIndex] = true
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

	local remaining = timer.TimeMax - currentTime
	local percent = 0
	if timer.Time and timer.Time > 0 then
		percent = (remaining / timer.Time) * 100
	end
	local color = NecrosisTimerColor(percent)

	local showTarget = (timer.Type == 1 or timer.Name == NECROSIS_SPELL_TABLE[16].Name) and timer.Target ~= ""
	local line = "<white>" .. timeText .. " - <close>" .. color .. timer.Name .. "<close><white>"
	if showTarget then
		line = line .. " - " .. timer.Target .. "<close>\n"
	else
		line = line .. "<close>\n"
	end
	textBuffer[table.getn(textBuffer) + 1] = line

	local timerLabel = timeText
	if showTarget then
		if NecrosisConfig.SpellTimerPos == 1 then
			timerLabel = timerLabel .. " - " .. timer.Target
		else
			timerLabel = timer.Target .. " - " .. timerLabel
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
	end

	graphCount = graphCount + 1
	GraphicalTimer.texte[graphCount] = timer.Name
	GraphicalTimer.TimeMax[graphCount] = timer.TimeMax
	GraphicalTimer.Time[graphCount] = timer.Time
	GraphicalTimer.titre[graphCount] = false
	GraphicalTimer.temps[graphCount] = timerLabel
	GraphicalTimer.Gtimer[graphCount] = timer.Gtimer

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

	return SpellGroup, TimerTable, graphCount
end
