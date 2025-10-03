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
	table.insert(SpellTimer, {
		Name = NECROSIS_SPELL_TABLE[IndexTable].Name,
		Time = NECROSIS_SPELL_TABLE[IndexTable].Length,
		TimeMax = floor(GetTime() + NECROSIS_SPELL_TABLE[IndexTable].Length),
		Type = NECROSIS_SPELL_TABLE[IndexTable].Type,
		Target = Target,
		TargetLevel = LevelTarget,
		Group = 0,
		Gtimer = nil,
	})

	-- Associate a graphical timer with the entry
	SpellTimer, TimerTable = Necrosis_AddFrame(SpellTimer, TimerTable)

	-- Sort entries by spell type
	Necrosis_SortTimers(SpellTimer, "Type")

	-- Create timer groups (mob names)
	SpellGroup, SpellTimer = Necrosis_AssignTimerGroups(SpellGroup, SpellTimer)

	return SpellGroup, SpellTimer, TimerTable
end

-- And to insert the stone timer
function Necrosis_InsertStoneTimer(Stone, start, duration, SpellGroup, SpellTimer, TimerTable)
	-- Insert the entry into the table
	if Stone == "Healthstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", 120)
		end
		table.insert(SpellTimer, {
			Name = NECROSIS_COOLDOWN.Healthstone,
			Time = 120,
			TimeMax = floor(GetTime() + 120),
			Type = 2,
			Target = "",
			TargetLevel = "",
			Group = 2,
			Gtimer = nil,
		})

		-- Associate a graphical timer with the entry
		SpellTimer, TimerTable = Necrosis_AddFrame(SpellTimer, TimerTable)
	elseif Stone == "Spellstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", 120)
		end
		table.insert(SpellTimer, {
			Name = NECROSIS_COOLDOWN.Spellstone,
			Time = 120,
			TimeMax = floor(GetTime() + 120),
			Type = 2,
			Target = "",
			TargetLevel = "",
			Group = 2,
			Gtimer = nil,
		})

		-- Associate a graphical timer with the entry
		SpellTimer, TimerTable = Necrosis_AddFrame(SpellTimer, TimerTable)
	elseif Stone == "Soulstone" then
		if type(Necrosis_DebugPrint) == "function" then
			Necrosis_DebugPrint("InsertTimerStone", Stone, "duration=", duration or "nil")
		end
		table.insert(SpellTimer, {
			Name = NECROSIS_SPELL_TABLE[11].Name,
			Time = floor(duration - GetTime() + start),
			TimeMax = floor(start + duration),
			Type = NECROSIS_SPELL_TABLE[11].Type,
			Target = "???",
			TargetLevel = "",
			Group = 1,
			Gtimer = nil,
		})

		-- Associate a graphical timer with the entry
		SpellTimer, TimerTable = Necrosis_AddFrame(SpellTimer, TimerTable)
	end

	-- Sort entries by spell type
	Necrosis_SortTimers(SpellTimer, "Type")

	-- Create timer groups (mob names)
	SpellGroup, SpellTimer = Necrosis_AssignTimerGroups(SpellGroup, SpellTimer)

	return SpellGroup, SpellTimer, TimerTable
end

-- For creating custom timers
function Necrosis_InsertCustomTimer(nom, duree, truc, Target, LevelTarget, SpellGroup, SpellTimer, TimerTable)
	table.insert(SpellTimer, {
		Name = nom,
		Time = duree,
		TimeMax = floor(GetTime() + duree),
		Type = truc,
		Target = Target,
		TargetLevel = LevelTarget,
		Group = 0,
		Gtimer = nil,
	})

	-- Associate a graphical timer with the entry
	SpellTimer, TimerTable = Necrosis_AddFrame(SpellTimer, TimerTable)

	-- Sort entries by spell type
	Necrosis_SortTimers(SpellTimer, "Type")

	-- Create timer groups (mob names)
	SpellGroup, SpellTimer = Necrosis_AssignTimerGroups(SpellGroup, SpellTimer)

	return SpellGroup, SpellTimer, TimerTable
end

------------------------------------------------------------------------------------------------------
-- REMOVAL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Remove the timer once its index is known
function Necrosis_RemoveTimerByIndex(index, SpellTimer, TimerTable)
	-- Remove the graphical timer
	local Gtime = SpellTimer[index].Gtimer
	TimerTable = Necrosis_RemoveFrame(Gtime, TimerTable)

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
	local GroupeOK = false
	for index = 1, table.getn(SpellTimer), 1 do
		local GroupeOK = false
		for i = 1, table.getn(SpellGroup.Name), 1 do
			if
				((SpellTimer[index].Type == i) and (i <= 3))
				or (
					SpellTimer[index].Target == SpellGroup.Name[i]
					and SpellTimer[index].TargetLevel == SpellGroup.SubName[i]
				)
			then
				GroupeOK = true
				SpellTimer[index].Group = i
				break
			end
		end
		-- Create a new group if it does not exist
		if not GroupeOK then
			table.insert(SpellGroup.Name, SpellTimer[index].Target)
			table.insert(SpellGroup.SubName, SpellTimer[index].TargetLevel)
			table.insert(SpellGroup.Visible, false)
			SpellTimer[index].Group = table.getn(SpellGroup.Name)
		end
	end

	Necrosis_SortTimers(SpellTimer, "Group")
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

function Necrosis_DisplayTimer(display, index, SpellGroup, SpellTimer, GraphicalTimer, TimerTable)
	if not SpellTimer then
		return display, SpellGroup
	end

	local minutes = 0
	local seconds = 0
	local affichage

	-- Change color based on remaining time
	local percent = (floor(SpellTimer[index].TimeMax - floor(GetTime())) / SpellTimer[index].Time) * 100
	local color = NecrosisTimerColor(percent)

	if
		not SpellGroup.Visible[SpellTimer[index].Group]
		and SpellGroup.SubName[SpellTimer[index].Group] ~= nil
		and SpellGroup.Name[SpellTimer[index].Group] ~= nil
	then
		display = display
			.. "<purple>-------------------------------\n"
			.. SpellGroup.Name[SpellTimer[index].Group]
			.. " "
			.. SpellGroup.SubName[SpellTimer[index].Group]
			.. "\n-------------------------------<close>\n"
		-- Build the table used by graphical timers
		table.insert(
			GraphicalTimer.texte,
			SpellGroup.Name[SpellTimer[index].Group] .. " " .. SpellGroup.SubName[SpellTimer[index].Group]
		)
		table.insert(GraphicalTimer.TimeMax, 0)
		table.insert(GraphicalTimer.Time, 0)
		table.insert(GraphicalTimer.titre, true)
		table.insert(GraphicalTimer.temps, "")
		table.insert(GraphicalTimer.Gtimer, 0)
		SpellGroup.Visible[SpellTimer[index].Group] = true
	end

	-- Use a stopwatch instead of a countdown for Enslave
	if SpellTimer[index].Name == NECROSIS_SPELL_TABLE[10].Name then
		seconds = floor(GetTime()) - (SpellTimer[index].TimeMax - SpellTimer[index].Time)
	else
		seconds = SpellTimer[index].TimeMax - floor(GetTime())
	end
	minutes = floor(seconds / 60)
	if minutes > 0 then
		if minutes > 9 then
			affichage = tostring(minutes) .. ":"
		else
			affichage = "0" .. minutes .. ":"
		end
	else
		affichage = "0:"
	end
	seconds = mod(seconds, 60)
	if seconds > 9 then
		affichage = affichage .. seconds
	else
		affichage = affichage .. "0" .. seconds
	end
	display = display .. "<white>" .. affichage .. " - <close>"

	-- Build the table used by graphical timers
	if
		(SpellTimer[index].Type == 1 or SpellTimer[index].Name == NECROSIS_SPELL_TABLE[16].Name)
		and (SpellTimer[index].Target ~= "")
	then
		if NecrosisConfig.SpellTimerPos == 1 then
			affichage = affichage .. " - " .. SpellTimer[index].Target
		else
			affichage = SpellTimer[index].Target .. " - " .. affichage
		end
	end
	if not SpellTimer[index].Gtimer or SpellTimer[index].Gtimer == 0 then
		for slot = 1, table.getn(TimerTable), 1 do
			if not TimerTable[slot] then
				TimerTable[slot] = true
				SpellTimer[index].Gtimer = slot
				break
			end
		end
	end
	table.insert(GraphicalTimer.texte, SpellTimer[index].Name)
	table.insert(GraphicalTimer.TimeMax, SpellTimer[index].TimeMax)
	table.insert(GraphicalTimer.Time, SpellTimer[index].Time)
	table.insert(GraphicalTimer.titre, false)
	table.insert(GraphicalTimer.temps, affichage)
	table.insert(GraphicalTimer.Gtimer, SpellTimer[index].Gtimer)

	if NecrosisConfig.CountType == 3 then
		if SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name then
			if minutes > 0 then
				NecrosisShardCount:SetText(minutes .. " m")
			else
				NecrosisShardCount:SetText(seconds)
			end
		end
	end
	if NecrosisConfig.Circle == 2 then
		if SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name then
			if minutes >= 16 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Turquoise\\Shard" .. minutes - 15)
			elseif minutes >= 1 or seconds >= 33 then
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Orange\\Shard" .. minutes + 1)
			else
				NecrosisButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\Rose\\Shard" .. seconds)
			end
		end
	end
	display = display .. color .. SpellTimer[index].Name .. "<close><white>"
	if
		(SpellTimer[index].Type == 1 or SpellTimer[index].Name == NECROSIS_SPELL_TABLE[16].Name)
		and (SpellTimer[index].Target ~= "")
	then
		display = display .. " - " .. SpellTimer[index].Target .. "<close>\n"
	else
		display = display .. "<close>\n"
	end
	-- Display graphical timers (if enabled)
	if NecrosisConfig.Graphical then
		NecrosisAfficheTimer(GraphicalTimer, TimerTable)
	end

	return display, SpellGroup, GraphicalTimer, TimerTable
end
