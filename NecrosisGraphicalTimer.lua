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
function Necrosis_DisplayTimerFrames(timerData, pointer)
	-- Define the position where the first frame appears
	-- Force the first frame to always be the first mob (makes sense :P)

	if timerData ~= nil then
		local yPosition = NecrosisConfig.SensListe * 5

		for index = 1, table.getn(timerData.names), 1 do
			local slotId = timerData.slotIds[index]
			if not slotId then
				return
			end

			local labelFrame = getglobal("NecrosisTimer" .. slotId .. "Text")
			local barFrame = getglobal("NecrosisTimer" .. slotId .. "Bar")
			local textureFrame = getglobal("NecrosisTimer" .. slotId .. "Texture")
			local sparkFrame = getglobal("NecrosisTimer" .. slotId .. "Spark")
			local timerTextFrame = getglobal("NecrosisTimer" .. slotId .. "OutText")

			labelFrame:ClearAllPoints()
			labelFrame:SetPoint(
				NecrosisConfig.SpellTimerJust,
				"NecrosisSpellTimerButton",
				"CENTER",
				NecrosisConfig.SpellTimerPos * 23,
				yPosition + 1
			)
			if NecrosisConfig.Yellow then
				labelFrame:SetTextColor(1, 0.82, 0)
			else
				labelFrame:SetTextColor(1, 1, 1)
			end
			labelFrame:SetJustifyH("LEFT")
			labelFrame:SetText(timerData.names[index])

			barFrame:ClearAllPoints()
			barFrame:SetPoint(
				NecrosisConfig.SpellTimerJust,
				"NecrosisSpellTimerButton",
				"CENTER",
				NecrosisConfig.SpellTimerPos * 23,
				yPosition
			)
			local totalDuration = timerData.initialDurations[index]
			if not totalDuration or totalDuration <= 0 then
				totalDuration = 1
			end
			local expiryTime = timerData.expiryTimes[index]
			local startTime = expiryTime - totalDuration
			barFrame:SetMinMaxValues(startTime, expiryTime)
			local current = floor(GetTime())
			local value = 2 * expiryTime - (totalDuration + current)
			if value < startTime then
				value = startTime
			elseif value > expiryTime then
				value = expiryTime
			end
			barFrame:SetValue(value)
			local r, g
			local b = 37 / 255
			local percentColor = (expiryTime - current) / totalDuration
			if percentColor < 0 then
				percentColor = 0
			elseif percentColor > 1 then
				percentColor = 1
			end
			if percentColor > 0.5 then
				r = (49 / 255) + (((1 - percentColor) * 2) * (1 - (49 / 255)))
				g = 207 / 255
			else
				r = 1.0
				g = (207 / 255) - (0.5 - percentColor) * 2 * (207 / 255)
			end
			barFrame:SetStatusBarColor(r, g, b)

			textureFrame:ClearAllPoints()
			textureFrame:SetPoint(
				NecrosisConfig.SpellTimerJust,
				"NecrosisSpellTimerButton",
				"CENTER",
				NecrosisConfig.SpellTimerPos * 23,
				yPosition
			)

			timerTextFrame:ClearAllPoints()
			timerTextFrame:SetTextColor(1, 1, 1)
			timerTextFrame:SetJustifyH(NecrosisConfig.SpellTimerJust)
			local opposite = NecrosisConfig.SpellTimerJust == "LEFT" and "RIGHT" or "LEFT"
			timerTextFrame:SetPoint(
				NecrosisConfig.SpellTimerJust,
				barFrame,
				opposite,
				NecrosisConfig.SpellTimerPos * 5,
				1
			)
			timerTextFrame:SetText(timerData.displayLines[index])

			local sparkPosition = 150 - ((current - startTime) / totalDuration) * 150
			if sparkPosition < 1 then
				sparkPosition = 1
			end
			sparkFrame:SetPoint("CENTER", barFrame, "LEFT", sparkPosition, 0)

			yPosition = yPosition - NecrosisConfig.SensListe * 11
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
