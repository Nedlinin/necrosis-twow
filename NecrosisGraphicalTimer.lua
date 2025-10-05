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
-- isTitle = "true if it is a title, false otherwise",
-- displayLines = "numeric timer text",
-- slotIds = "Index of the associated timer (between 1 and 65)"
-- }
function Necrosis_DisplayTimerFrames(timerData, pointer)
	-- Define the position where the first frame appears
	-- Force the first frame to always be the first mob (makes sense :P)

	if timerData ~= nil then
		local TimerTarget = 0
		local yPosition = NecrosisConfig.SensListe * 5

		local PositionTitre = {}

		if NecrosisConfig.SensListe > 0 then
			PositionTitre = { 11, 13 }
		else
			PositionTitre = { -13, -11 }
		end

		for index = 1, table.getn(timerData.names), 1 do
			-- If the entry is a mob title
			if timerData.isTitle[index] then
				-- Switch to the next mob group
				TimerTarget = TimerTarget + 1
				if TimerTarget ~= 1 then
					yPosition = yPosition - PositionTitre[1]
				end
				if TimerTarget == 11 then
					TimerTarget = 1
				end
				-- Show the title
				local frameName = "NecrosisTarget" .. TimerTarget .. "Text"
				local frameItem = getglobal(frameName)
				-- Position the frame's left corner relative to the SpellTimers button center
				frameItem:ClearAllPoints()
				frameItem:SetPoint(
					NecrosisConfig.SpellTimerJust,
					"NecrosisSpellTimerButton",
					"CENTER",
					NecrosisConfig.SpellTimerPos * 23,
					yPosition
				)
				yPosition = yPosition - PositionTitre[2]
				-- Name the frame and display it! :)
				frameItem:SetText(timerData.names[index])
				if not frameItem:IsShown() then
					frameItem:Show()
				end
			else
				-- Same for DoTs
				local JustifInverse = "LEFT"
				if NecrosisConfig.SpellTimerJust == "LEFT" then
					JustifInverse = "RIGHT"
				end

				if timerData.slotIds[index] == nil then
					return
				end
				local frameName1 = "NecrosisTimer" .. timerData.slotIds[index] .. "Text"
				local frameItem1 = getglobal(frameName1)
				local frameName2 = "NecrosisTimer" .. timerData.slotIds[index] .. "Bar"
				local frameItem2 = getglobal(frameName2)
				local frameName3 = "NecrosisTimer" .. timerData.slotIds[index] .. "Texture"
				local frameItem3 = getglobal(frameName3)
				local frameName4 = "NecrosisTimer" .. timerData.slotIds[index] .. "Spark"
				local frameItem4 = getglobal(frameName4)
				local frameName5 = "NecrosisTimer" .. timerData.slotIds[index] .. "OutText"
				local frameItem5 = getglobal(frameName5)

				frameItem1:ClearAllPoints()
				frameItem1:SetPoint(
					NecrosisConfig.SpellTimerJust,
					"NecrosisSpellTimerButton",
					"CENTER",
					NecrosisConfig.SpellTimerPos * 23,
					yPosition + 1
				)
				if NecrosisConfig.Yellow then
					frameItem1:SetTextColor(1, 0.82, 0)
				else
					frameItem1:SetTextColor(1, 1, 1)
				end
				frameItem1:SetJustifyH("LEFT")
				frameItem1:SetText(timerData.names[index])
				frameItem2:ClearAllPoints()
				frameItem2:SetPoint(
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
				frameItem2:SetMinMaxValues(startTime, expiryTime)
				local current = floor(GetTime())
				local value = 2 * expiryTime - (totalDuration + current)
				if value < startTime then
					value = startTime
				elseif value > expiryTime then
					value = expiryTime
				end
				frameItem2:SetValue(value)
				local r, g
				local b = 37 / 255
				local PercentColor = (expiryTime - current) / totalDuration
				if PercentColor < 0 then
					PercentColor = 0
				elseif PercentColor > 1 then
					PercentColor = 1
				end
				if PercentColor > 0.5 then
					r = (49 / 255) + (((1 - PercentColor) * 2) * (1 - (49 / 255)))
					g = 207 / 255
				else
					r = 1.0
					g = (207 / 255) - (0.5 - PercentColor) * 2 * (207 / 255)
				end
				frameItem2:SetStatusBarColor(r, g, b)
				frameItem3:ClearAllPoints()
				frameItem3:SetPoint(
					NecrosisConfig.SpellTimerJust,
					"NecrosisSpellTimerButton",
					"CENTER",
					NecrosisConfig.SpellTimerPos * 23,
					yPosition
				)
				frameItem5:ClearAllPoints()
				frameItem5:SetTextColor(1, 1, 1)
				frameItem5:SetJustifyH(NecrosisConfig.SpellTimerJust)
				frameItem5:SetPoint(
					NecrosisConfig.SpellTimerJust,
					frameItem2,
					JustifInverse,
					NecrosisConfig.SpellTimerPos * 5,
					1
				)
				frameItem5:SetText(timerData.displayLines[index])

				local sparkPosition = 150 - ((current - startTime) / totalDuration) * 150
				if sparkPosition < 1 then
					sparkPosition = 1
				end
				frameItem4:SetPoint("CENTER", frameItem2, "LEFT", sparkPosition, 0)
				yPosition = yPosition - NecrosisConfig.SensListe * 11
			end
		end
		if TimerTarget < 10 then
			for i = TimerTarget + 1, 10, 1 do
				local frameName = "NecrosisTarget" .. i .. "Text"
				local frameItem = getglobal(frameName)
				if frameItem:IsShown() then
					frameItem:Hide()
				end
			end
		end
	end
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
			if NecrosisConfig.Graphical then
				local elements = { "Text", "Bar", "Texture", "OutText" }
				for j = 1, 4, 1 do
					frameName = "NecrosisTimer" .. i .. elements[j]
					frameItem = getglobal(frameName)
					if frameItem then
						frameItem:Show()
					end
				end
			end
			return timerList, timerSlots
		end
	end

	-- No available slot, append a new one
	local newIndex = slotCount + 1
	timerSlots[newIndex] = true
	timerList[table.getn(timerList)].Gtimer = newIndex
	if NecrosisConfig.Graphical then
		local elements = { "Text", "Bar", "Texture", "OutText" }
		for j = 1, 4, 1 do
			frameName = "NecrosisTimer" .. newIndex .. elements[j]
			frameItem = getglobal(frameName)
			if frameItem then
				frameItem:Show()
			end
		end
	end
	return timerList, timerSlots
end

function Necrosis_RemoveTimerFrame(frameIndex, timerSlots)
	-- Hide the graphical timer
	local elements = { "Text", "Bar", "Texture", "OutText" }
	for j = 1, 4, 1 do
		frameName = "NecrosisTimer" .. frameIndex .. elements[j]
		frameItem = getglobal(frameName)
		frameItem:Hide()
	end

	-- Mark the graphical timer as reusable
	timerSlots[frameIndex] = false

	return timerSlots
end
