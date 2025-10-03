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
-- texte = "Mob or spell name",
-- TimeMax = "Total duration of the spell",
-- Time = "Remaining time for the spell",
-- titre = "true if it is a title, false otherwise",
-- temps = "numeric timer",
-- Gtimer = "Index of the associated timer (between 1 and 65)"
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

		for index = 1, table.getn(timerData.texte), 1 do
			-- If the entry is a mob title
			if timerData.titre[index] then
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
				frameItem:SetText(timerData.texte[index])
				if not frameItem:IsShown() then
					frameItem:Show()
				end
			else
				-- Same for DoTs
				local JustifInverse = "LEFT"
				if NecrosisConfig.SpellTimerJust == "LEFT" then
					JustifInverse = "RIGHT"
				end

				local frameName1 = "NecrosisTimer" .. timerData.Gtimer[index] .. "Text"
				local frameItem1 = getglobal(frameName1)
				local frameName2 = "NecrosisTimer" .. timerData.Gtimer[index] .. "Bar"
				local frameItem2 = getglobal(frameName2)
				local frameName3 = "NecrosisTimer" .. timerData.Gtimer[index] .. "Texture"
				local frameItem3 = getglobal(frameName3)
				local frameName4 = "NecrosisTimer" .. timerData.Gtimer[index] .. "Spark"
				local frameItem4 = getglobal(frameName4)
				local frameName5 = "NecrosisTimer" .. timerData.Gtimer[index] .. "OutText"
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
				frameItem1:SetText(timerData.texte[index])
				frameItem2:ClearAllPoints()
				frameItem2:SetPoint(
					NecrosisConfig.SpellTimerJust,
					"NecrosisSpellTimerButton",
					"CENTER",
					NecrosisConfig.SpellTimerPos * 23,
					yPosition
				)
				frameItem2:SetMinMaxValues(timerData.TimeMax[index] - timerData.Time[index], timerData.TimeMax[index])
				frameItem2:SetValue(2 * timerData.TimeMax[index] - (timerData.Time[index] + floor(GetTime())))
				local r, g
				local b = 37 / 255
				local PercentColor = (timerData.TimeMax[index] - floor(GetTime())) / timerData.Time[index]
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
				frameItem5:SetText(timerData.temps[index])

				local sparkPosition = 150
					- (
							(floor(GetTime()) - (timerData.TimeMax[index] - timerData.Time[index]))
							/ timerData.Time[index]
						)
						* 150
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
	for i = 1, table.getn(timerSlots), 1 do
		if not timerSlots[i] then
			timerSlots[i] = true
			timerList[table.getn(timerList)].Gtimer = i
			-- Display the associated graphical timer
			if NecrosisConfig.Graphical then
				local elements = { "Text", "Bar", "Texture", "OutText" }
				for j = 1, 4, 1 do
					frameName = "NecrosisTimer" .. i .. elements[j]
					frameItem = getglobal(frameName)
					frameItem:Show()
				end
			end
			break
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
