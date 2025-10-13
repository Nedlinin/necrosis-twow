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
-- Version 07.04.2006-1
------------------------------------------------------------------------------------------------------

-- Timer display function
-- Table layout:
-- table {
-- names = "Mob or spell name",
-- expiryTimes = "Absolute expiration timestamp",
-- initialDurations = "Full duration of the spell",
-- displayLines = "numeric timer text",
-- slotIds = "Index of the associated timer (between 1 and 65)"
-- }
local LABEL_COLOR_YELLOW = { 1, 0.82, 0 }
local LABEL_COLOR_WHITE = { 1, 1, 1 }
local TIMER_BAR_BLUE = 37 / 255
local TIMER_COLOR_LOW = 49 / 255
local TIMER_COLOR_HIGH = 207 / 255
local TIMER_SPARK_RANGE = 150
local GRAPH_TIMER_BUTTON = "NecrosisSpellTimerButton"

local TimerFrameCache = {}

local function Necrosis_GetTimerFrame(slotId)
	local cached = TimerFrameCache[slotId]
	if cached then
		return cached
	end
	local label = getglobal("NecrosisTimer" .. slotId .. "Text")
	local bar = getglobal("NecrosisTimer" .. slotId .. "Bar")
	local texture = getglobal("NecrosisTimer" .. slotId .. "Texture")
	local spark = getglobal("NecrosisTimer" .. slotId .. "Spark")
	local outText = getglobal("NecrosisTimer" .. slotId .. "OutText")
	cached = {
		label = label,
		bar = bar,
		texture = texture,
		spark = spark,
		outText = outText,
	}
	TimerFrameCache[slotId] = cached
	return cached
end

local function Necrosis_ApplyBarColor(barFrame, percent)
	if percent < 0 then
		percent = 0
	elseif percent > 1 then
		percent = 1
	end
	local r
	local g
	if percent > 0.5 then
		r = TIMER_COLOR_LOW + (((1 - percent) * 2) * (1 - TIMER_COLOR_LOW))
		g = TIMER_COLOR_HIGH
	else
		r = 1
		g = TIMER_COLOR_HIGH - (0.5 - percent) * 2 * TIMER_COLOR_HIGH
	end
	barFrame:SetStatusBarColor(r, g, TIMER_BAR_BLUE)
end

function Necrosis_DisplayTimerFrames(timerData, pointer)
	-- Define the position where the first frame appears
	-- Force the first frame to always be the first mob (makes sense :P)

	if timerData ~= nil then
		local anchorJustify = NecrosisConfig.SpellTimerJust
		local opposite = anchorJustify == "LEFT" and "RIGHT" or "LEFT"
		local baseOffset = NecrosisConfig.SpellTimerPos * 23
		local textOffset = NecrosisConfig.SpellTimerPos * 5
		local yStep = NecrosisConfig.SensListe * 11
		local yPosition = NecrosisConfig.SensListe * 5
		local labelColor = NecrosisConfig.Yellow and LABEL_COLOR_YELLOW or LABEL_COLOR_WHITE
		local labelR, labelG, labelB = labelColor[1], labelColor[2], labelColor[3]
		local current = floor(GetTime())
		local names = timerData.names
		local durations = timerData.initialDurations
		local expiryTimes = timerData.expiryTimes
		local displayLines = timerData.displayLines
		local slotIds = timerData.slotIds

		for index = 1, table.getn(names), 1 do
			local slotId = timerData.slotIds[index]
			if not slotId then
				return
			end

			local frames = Necrosis_GetTimerFrame(slotId)
			local labelFrame = frames.label
			local barFrame = frames.bar
			local textureFrame = frames.texture
			local sparkFrame = frames.spark
			local timerTextFrame = frames.outText
			if not (labelFrame and barFrame and textureFrame and sparkFrame and timerTextFrame) then
				return
			end

			labelFrame:ClearAllPoints()
			labelFrame:SetPoint(anchorJustify, GRAPH_TIMER_BUTTON, "CENTER", baseOffset, yPosition + 1)
			labelFrame:SetTextColor(labelR, labelG, labelB)
			labelFrame:SetJustifyH("LEFT")
			labelFrame:SetText(names[index])

			barFrame:ClearAllPoints()
			barFrame:SetPoint(anchorJustify, GRAPH_TIMER_BUTTON, "CENTER", baseOffset, yPosition)
			local totalDuration = durations[index]
			if not totalDuration or totalDuration <= 0 then
				totalDuration = 1
			end
			local expiryTime = expiryTimes[index]
			local startTime = expiryTime - totalDuration
			barFrame:SetMinMaxValues(0, totalDuration)
			local clamped = current
			if clamped < startTime then
				clamped = startTime
			elseif clamped > expiryTime then
				clamped = expiryTime
			end
			local remaining = expiryTime - clamped
			if remaining < 0 then
				remaining = 0
			elseif remaining > totalDuration then
				remaining = totalDuration
			end
			barFrame:SetValue(remaining)
			local percentRemaining = totalDuration > 0 and (remaining / totalDuration) or 0
			Necrosis_ApplyBarColor(barFrame, percentRemaining)

			textureFrame:ClearAllPoints()
			textureFrame:SetPoint(anchorJustify, GRAPH_TIMER_BUTTON, "CENTER", baseOffset, yPosition)

			timerTextFrame:ClearAllPoints()
			timerTextFrame:SetTextColor(1, 1, 1)
			timerTextFrame:SetJustifyH(anchorJustify)
			timerTextFrame:SetPoint(anchorJustify, barFrame, opposite, textOffset, 1)
			timerTextFrame:SetText(displayLines[index])

			local barWidth = barFrame:GetWidth() or TIMER_SPARK_RANGE
			local sparkOffset = percentRemaining * barWidth
			sparkFrame:SetPoint("CENTER", barFrame, "LEFT", sparkOffset, 0)

			yPosition = yPosition - yStep
		end
	end
end

local NECROSIS_TIMER_FRAME_ELEMENTS = { "Text", "Bar", "Texture", "OutText" }

local function Necrosis_ShowTimerFrameElements(frameIndex)
	if not frameIndex or frameIndex <= 0 then
		return
	end
	local elements = NECROSIS_TIMER_FRAME_ELEMENTS
	for j = 1, 4, 1 do
		local frameName = "NecrosisTimer" .. frameIndex .. elements[j]
		local frameItem = getglobal(frameName)
		if frameItem then
			frameItem:Show()
		end
	end
end

function Necrosis_ShowTimerFrame(frameIndex)
	if NecrosisConfig and not NecrosisConfig.Graphical then
		return
	end
	Necrosis_ShowTimerFrameElements(frameIndex)
end

function Necrosis_AddTimerFrame(timerList, timerSlots)
	if not timerSlots then
		timerSlots = {}
	end

	local slotCount = table.getn(timerSlots)
	for i = 1, slotCount, 1 do
		if not timerSlots[i] then
			timerSlots[i] = true
			timerList[table.getn(timerList)].Gtimer = i
			-- Display the associated graphical timer
			Necrosis_ShowTimerFrame(i)
			return timerList, timerSlots
		end
	end

	-- No available slot, append a new one
	local newIndex = slotCount + 1
	timerSlots[newIndex] = true
	timerList[table.getn(timerList)].Gtimer = newIndex
	Necrosis_ShowTimerFrame(newIndex)
	return timerList, timerSlots
end

function Necrosis_RemoveTimerFrame(frameIndex, timerSlots)
	-- Hide the graphical timer
	local elements = NECROSIS_TIMER_FRAME_ELEMENTS
	for j = 1, 4, 1 do
		local frameName = "NecrosisTimer" .. frameIndex .. elements[j]
		local frameItem = getglobal(frameName)
		if frameItem then
			frameItem:Hide()
		end
	end

	-- Mark the graphical timer as reusable
	timerSlots[frameIndex] = false

	return timerSlots
end
