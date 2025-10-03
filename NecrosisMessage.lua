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
-- Version 30.04.2005-1
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- DISPLAY FUNCTIONS (CONSOLE, CHAT, SYSTEM MESSAGE)
------------------------------------------------------------------------------------------------------

function Necrosis_Msg(msg, type)
	if msg and type then
		-- If the type is "USER", display the message on screen...
		if type == "USER" then
			-- Cleverly colorize the message :D
			msg = Necrosis_MsgAddColor(msg)
			local Intro = "|CFFFF00FFNe|CFFFF50FFcr|CFFFF99FFos|CFFFFC4FFis|CFFFFFFFF: "
			if NecrosisConfig.ChatType then
				-- ...... on the first chat window
				ChatFrame1:AddMessage(Intro .. msg, 1.0, 0.7, 1.0, 1.0, UIERRORS_HOLD_TIME)
			else
				-- ...... or at the center of the screen
				UIErrorsFrame:AddMessage(Intro .. msg, 1.0, 0.7, 1.0, 1.0, UIERRORS_HOLD_TIME)
			end
		-- If the type is "WORLD", send the message to the raid, otherwise to the party, otherwise to local chat
		elseif type == "WORLD" then
			if GetNumRaidMembers() > 0 then
				SendChatMessage(msg, "RAID")
			elseif GetNumPartyMembers() > 0 then
				SendChatMessage(msg, "PARTY")
			else
				SendChatMessage(msg, "SAY")
			end
		-- If the type is "PARTY", send the message to the party
		elseif type == "PARTY" then
			SendChatMessage(msg, "PARTY")
		-- If the type is "RAID", send the message to the raid
		elseif type == "RAID" then
			SendChatMessage(msg, "RAID")
		elseif type == "SAY" then
			-- If the type is "SAY", send the message to local chat
			SendChatMessage(msg, "SAY")
		end
	end
end

------------------------------------------------------------------------------------------------------
-- ... AND COLORAMA WAS BORN!
------------------------------------------------------------------------------------------------------

-- Replace color codes in strings with their color definitions
function Necrosis_MsgAddColor(msg)
	msg = string.gsub(msg, "<white>", "|CFFFFFFFF")
	msg = string.gsub(msg, "<lightBlue>", "|CFF99CCFF")
	msg = string.gsub(msg, "<brightGreen>", "|CFF00FF00")
	msg = string.gsub(msg, "<lightGreen2>", "|CFF66FF66")
	msg = string.gsub(msg, "<lightGreen1>", "|CFF99FF66")
	msg = string.gsub(msg, "<yellowGreen>", "|CFFCCFF66")
	msg = string.gsub(msg, "<lightYellow>", "|CFFFFFF66")
	msg = string.gsub(msg, "<darkYellow>", "|CFFFFCC00")
	msg = string.gsub(msg, "<lightOrange>", "|CFFFFCC66")
	msg = string.gsub(msg, "<dirtyOrange>", "|CFFFF9933")
	msg = string.gsub(msg, "<darkOrange>", "|CFFFF6600")
	msg = string.gsub(msg, "<redOrange>", "|CFFFF3300")
	msg = string.gsub(msg, "<red>", "|CFFFF0000")
	msg = string.gsub(msg, "<lightRed>", "|CFFFF5555")
	msg = string.gsub(msg, "<lightPurple1>", "|CFFFFC4FF")
	msg = string.gsub(msg, "<lightPurple2>", "|CFFFF99FF")
	msg = string.gsub(msg, "<purple>", "|CFFFF50FF")
	msg = string.gsub(msg, "<darkPurple1>", "|CFFFF00FF")
	msg = string.gsub(msg, "<darkPurple2>", "|CFFB700B7")
	msg = string.gsub(msg, "<close>", "|r")
	return msg
end

-- Insert color codes into timers based on remaining duration
function NecrosisTimerColor(percent)
	local color = "<brightGreen>"
	if percent < 10 then
		color = "<red>"
	elseif percent < 20 then
		color = "<redOrange>"
	elseif percent < 30 then
		color = "<darkOrange>"
	elseif percent < 40 then
		color = "<dirtyOrange>"
	elseif percent < 50 then
		color = "<darkYellow>"
	elseif percent < 60 then
		color = "<lightYellow>"
	elseif percent < 70 then
		color = "<yellowGreen>"
	elseif percent < 80 then
		color = "<lightGreen1>"
	elseif percent < 90 then
		color = "<lightGreen2>"
	end
	return color
end

------------------------------------------------------------------------------------------------------
-- USER-FRIENDLY PLACEHOLDERS IN SUMMON MESSAGES
------------------------------------------------------------------------------------------------------

function Necrosis_MsgReplace(msg, target, pet)
	msg = string.gsub(msg, "<player>", UnitName("player"))
	if target then
		msg = string.gsub(msg, "<target>", target)
	end
	if pet then
		msg = string.gsub(msg, "<pet>", NecrosisConfig.PetName[pet])
	end
	return msg
end
