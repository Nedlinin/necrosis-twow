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
-- Version 28.06.2006-1
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------
-- INITIALIZATION FUNCTION
------------------------------------------------------------------------------------------------------

local function Necrosis_DeepMerge(target, source)
	for key, s_val in pairs(source) do
		local t_val = target[key]
		if type(s_val) == "table" and type(t_val) == "table" then
			Necrosis_DeepMerge(t_val, s_val)
		elseif t_val == nil then
			target[key] = s_val
		end
	end
end

local function Necrosis_ConfigClone(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = Necrosis_ConfigClone(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function Necrosis_ConfigSchemasMatch(defaultValue, savedValue)
	if type(defaultValue) ~= type(savedValue) then
		return false
	end
	if type(defaultValue) ~= "table" then
		return true
	end
	for key, defVal in pairs(defaultValue) do
		local savedVal = savedValue[key]
		if savedVal == nil then
			return false
		end
		if not Necrosis_ConfigSchemasMatch(defVal, savedVal) then
			return false
		end
	end
	for key in pairs(savedValue) do
		if defaultValue[key] == nil then
			return false
		end
	end
	return true
end

local function Necrosis_ResetDefaultAnchors()
	NecrosisButton:ClearAllPoints()
	NecrosisShadowTranceButton:ClearAllPoints()
	NecrosisAntiFearButton:ClearAllPoints()
	NecrosisSpellTimerButton:ClearAllPoints()
	NecrosisButton:SetPoint("CENTER", "UIParent", "CENTER", 0, -100)
	NecrosisShadowTranceButton:SetPoint("CENTER", "UIParent", "CENTER", 100, -30)
	NecrosisAntiFearButton:SetPoint("CENTER", "UIParent", "CENTER", 100, 30)
	NecrosisSpellTimerButton:SetPoint("CENTER", "UIParent", "CENTER", 120, 340)
end

local LANGUAGE_SLIDER_INDEX = { deDE = 3, enUS = 2 }
local COLOR_SLIDER_INDEX = { Rose = 1, Bleu = 2, Orange = 3, Turquoise = 4, Violet = 5 }
local LANGUAGE_SLIDER_LABEL = "Langue / Language / Sprache"

local function sliderValueAngle(config)
	return config.NecrosisAngle or 0
end

local function sliderValueBag(config)
	local container = config.SoulshardContainer or 4
	return 4 - container
end

local function sliderValueLanguage(config)
	return LANGUAGE_SLIDER_INDEX[config.NecrosisLanguage] or 1
end

local function sliderValueCountType(config)
	return config.CountType or 0
end

local function sliderValueCircle(config)
	return config.Circle or 0
end

local function sliderValueShadowScale(config)
	return config.ShadowTranceScale or 100
end

local function sliderValueColor(config)
	return COLOR_SLIDER_INDEX[config.NecrosisColor] or 6
end

local function sliderValueButtonScale(config)
	return config.NecrosisButtonScale or 100
end

local function sliderValueBanishScale(config)
	return config.BanishScale or 100
end

local OPTION_SLIDER_CONFIG = {
	{
		sliderName = "NecrosisButtonRotate_Slider",
		lowLabelName = "NecrosisButtonRotate_SliderLow",
		highLabelName = "NecrosisButtonRotate_SliderHigh",
		getValue = sliderValueAngle,
		lowText = "0",
		highText = "360",
	},
	{
		sliderName = "NecrosisLanguage_Slider",
		lowLabelName = "NecrosisLanguage_SliderLow",
		highLabelName = "NecrosisLanguage_SliderHigh",
		labelName = "NecrosisLanguage_SliderText",
		labelText = LANGUAGE_SLIDER_LABEL,
		getValue = sliderValueLanguage,
		lowText = "",
		highText = "",
	},
	{
		sliderName = "NecrosisBag_Slider",
		lowLabelName = "NecrosisBag_SliderLow",
		highLabelName = "NecrosisBag_SliderHigh",
		getValue = sliderValueBag,
		lowText = "5",
		highText = "1",
	},
	{
		sliderName = "NecrosisCountType_Slider",
		lowLabelName = "NecrosisCountType_SliderLow",
		highLabelName = "NecrosisCountType_SliderHigh",
		getValue = sliderValueCountType,
		lowText = "",
		highText = "",
	},
	{
		sliderName = "NecrosisCircle_Slider",
		lowLabelName = "NecrosisCircle_SliderLow",
		highLabelName = "NecrosisCircle_SliderHigh",
		getValue = sliderValueCircle,
		lowText = "",
		highText = "",
	},
	{
		sliderName = "ShadowTranceScale_Slider",
		lowLabelName = "ShadowTranceScale_SliderLow",
		highLabelName = "ShadowTranceScale_SliderHigh",
		getValue = sliderValueShadowScale,
		lowText = "50%",
		highText = "150%",
	},
	{
		sliderName = "NecrosisColor_Slider",
		lowLabelName = "NecrosisColor_SliderLow",
		highLabelName = "NecrosisColor_SliderHigh",
		getValue = sliderValueColor,
		lowText = "",
		highText = "",
	},
	{
		sliderName = "NecrosisButtonScale_Slider",
		lowLabelName = "NecrosisButtonScale_SliderLow",
		highLabelName = "NecrosisButtonScale_SliderHigh",
		getValue = sliderValueButtonScale,
		lowText = "50 %",
		highText = "150 %",
	},
	{
		sliderName = "NecrosisBanishScale_Slider",
		lowLabelName = "NecrosisBanishScale_SliderLow",
		highLabelName = "NecrosisBanishScale_SliderHigh",
		getValue = sliderValueBanishScale,
		lowText = "100 %",
		highText = "200 %",
	},
}

function Necrosis_Initialize()
	Necrosis_Localization_Dialog_En()
	-- Initialize localized text (original / French / German)
	--if NecrosisConfig ~= {} then
	--	if (NecrosisConfig.NecrosisLanguage == "enUS") or (NecrosisConfig.NecrosisLanguage == "enGB") then
	--		Necrosis_Localization_Dialog_En();
	--	elseif (NecrosisConfig.NecrosisLanguage == "deDE") then
	--		Necrosis_Localization_Dialog_De();
	--	else
	--		Necrosis_Localization_Dialog_Fr();
	--	end
	--elseif GetLocale() == "enUS" or GetLocale() == "enGB" then
	--	Necrosis_Localization_Dialog_En();
	--elseif GetLocale() == "deDE" then
	--	Necrosis_Localization_Dialog_De();
	--else
	--	Necrosis_Localization_Dialog_Fr();
	--end

	-- Initialize! If the player is not a Warlock, hide Necrosis (shhhh!)
	-- Flag Necrosis as initialized
	if UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		HideUIPanel(NecrosisShardMenu)
		HideUIPanel(NecrosisSpellTimerButton)
		HideUIPanel(NecrosisButton)
		HideUIPanel(NecrosisPetMenuButton)
		HideUIPanel(NecrosisBuffMenuButton)
		HideUIPanel(NecrosisCurseMenuButton)
		HideUIPanel(NecrosisMountButton)
		HideUIPanel(NecrosisFirestoneButton)
		HideUIPanel(NecrosisSpellstoneButton)
		HideUIPanel(NecrosisHealthstoneButton)
		HideUIPanel(NecrosisSoulstoneButton)
		HideUIPanel(NecrosisAntiFearButton)
		HideUIPanel(NecrosisShadowTranceButton)
	else
		-- Load (or create) the player's configuration and print it to the console
		local resetToDefault = false
		if NecrosisConfig == nil then
			NecrosisConfig = Necrosis_ConfigClone(Default_NecrosisConfig)
			resetToDefault = true
		elseif NecrosisConfig.Version ~= Default_NecrosisConfig.Version then
			if Necrosis_ConfigSchemasMatch(Default_NecrosisConfig, NecrosisConfig) then
				Necrosis_DeepMerge(NecrosisConfig, Default_NecrosisConfig)
			else
				NecrosisConfig = Necrosis_ConfigClone(Default_NecrosisConfig)
				resetToDefault = true
			end
			NecrosisConfig.Version = Default_NecrosisConfig.Version
		end

		if resetToDefault then
			Necrosis_Msg(NECROSIS_MESSAGE.Interface.DefaultConfig, "USER")
			Necrosis_ResetDefaultAnchors()
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Interface.UserConfig, "USER")
		end

		-----------------------------------------------------------
		-- Execute startup routines
		-----------------------------------------------------------

		-- Display a message in the console
		Necrosis_Msg(NECROSIS_MESSAGE.Interface.Welcome, "USER")
		-- Build the list of available spells
		Necrosis_SpellSetup()
		-- Build the list of shard bag slots
		Necrosis_SoulshardSetup()
		-- Inventory the stones and shards owned by the Warlock
		Necrosis_BagExplore()
		-- Build the buff and summon menus
		Necrosis_CreateMenu()

		-- Read configuration from SavedVariables.lua and populate the runtime variables
		local function shouldCheck(binding)
			if binding.condition then
				return binding.condition()
			end
			local value = NecrosisConfig
			if binding.path then
				for index = 1, table.getn(binding.path), 1 do
					if not value then
						return false
					end
					value = value[binding.path[index]]
				end
			else
				return false
			end
			if binding.expected ~= nil then
				return value == binding.expected
			end
			return not not value
		end

		local checkboxBindings = {
			{ frame = "NecrosisSoulshardSort_Button", path = { "SoulshardSort" } },
			{ frame = "NecrosisSoulshardDestroy_Button", path = { "SoulshardDestroy" } },
			{ frame = "NecrosisShadowTranceAlert_Button", path = { "ShadowTranceAlert" } },
			{ frame = "NecrosisShowSpellTimers_Button", path = { "ShowSpellTimers" } },
			{ frame = "NecrosisAntiFearAlert_Button", path = { "AntiFearAlert" } },
			{ frame = "NecrosisIconsLock_Button", path = { "NecrosisLockServ" } },
			{ frame = "NecrosisShowHealthStone_Button", path = { "StonePosition", StonePos.Healthstone } },
			{ frame = "NecrosisShowSpellstone_Button", path = { "StonePosition", StonePos.Spellstone } },
			{ frame = "NecrosisShowSoulstone_Button", path = { "StonePosition", StonePos.Soulstone } },
			{ frame = "NecrosisShowBuffMenu_Button", path = { "StonePosition", StonePos.BuffMenu } },
			{ frame = "NecrosisShowMount_Button", path = { "StonePosition", StonePos.Mount } },
			{ frame = "NecrosisShowPetMenu_Button", path = { "StonePosition", StonePos.PetMenu } },
			{ frame = "NecrosisShowCurseMenu_Button", path = { "StonePosition", StonePos.CurseMenu } },
			{ frame = "NecrosisShowStoneMenu_Button", path = { "StonePosition", StonePos.StoneMenu } },
			{ frame = "NecrosisShowTooltips_Button", path = { "NecrosisToolTip" } },
			{ frame = "NecrosisSound_Button", path = { "Sound" } },
			{ frame = "NecrosisShowCount_Button", path = { "ShowCount" } },
			{ frame = "NecrosisShowMessage_Button", path = { "ChatMsg" } },
			{ frame = "NecrosisShowDemonSummon_Button", path = { "DemonSummon" } },
			{ frame = "NecrosisShowSteedSummon_Button", path = { "SteedSummon" } },
			{ frame = "NecrosisShowRitualSummon_Button", path = { "RitualMessage" } },
			{ frame = "NecrosisChatType_Button", path = { "ChatType" }, expected = false },
			{ frame = "NecrosisGraphicalTimer_Button", path = { "Graphical" } },
			{ frame = "NecrosisTimerColor_Button", path = { "Yellow" }, expected = false },
			{ frame = "NecrosisTimerDirection_Button", path = { "SensListe" }, expected = -1 },
			{ frame = "NecrosisTimerDebug_Button", path = { "DebugTimers" } },
			{ frame = "NecrosisBuffMenu_Button", path = { "BuffMenuPos" }, expected = -34 },
			{ frame = "NecrosisPetMenu_Button", path = { "PetMenuPos" }, expected = -34 },
			{ frame = "NecrosisCurseMenu_Button", path = { "CurseMenuPos" }, expected = -34 },
			{ frame = "NecrosisStoneMenu_Button", path = { "StoneMenuPos" }, expected = -34 },
			{ frame = "NecrosisLock_Button", path = { "NoDragAll" } },
			{ frame = "NecrosisSTimer_Button", path = { "SpellTimerPos" }, expected = -1 },
		}

		for index = 1, table.getn(checkboxBindings), 1 do
			local binding = checkboxBindings[index]
			if shouldCheck(binding) then
				local button = getglobal(binding.frame)
				if button then
					button:SetChecked(1)
				end
			end
		end
		-- Slider settings
		for index = 1, table.getn(OPTION_SLIDER_CONFIG), 1 do
			local entry = OPTION_SLIDER_CONFIG[index]
			local slider = getglobal(entry.sliderName)
			if slider and entry.getValue then
				local value = entry.getValue(NecrosisConfig)
				if value ~= nil then
					slider:SetValue(value)
				end
			end
			if entry.lowLabelName and entry.lowText ~= nil then
				local lowLabel = getglobal(entry.lowLabelName)
				if lowLabel then
					lowLabel:SetText(entry.lowText)
				end
			end
			if entry.highLabelName and entry.highText ~= nil then
				local highLabel = getglobal(entry.highLabelName)
				if highLabel then
					highLabel:SetText(entry.highText)
				end
			end
			if entry.labelName and entry.labelText then
				local label = getglobal(entry.labelName)
				if label then
					label:SetText(entry.labelText)
				end
			end
		end

		Necrosis_SetTimerDebug(NecrosisConfig.DebugTimers)

		if NecrosisConfig.DiagnosticsEnabled then
			Necrosis_DumpDiagnostics()
		end

		-- Size the stone and buttons based on the saved settings
		NecrosisButton:SetScale(NecrosisConfig.NecrosisButtonScale / 100)
		NecrosisShadowTranceButton:SetScale(NecrosisConfig.ShadowTranceScale / 100)
		NecrosisAntiFearButton:SetScale(NecrosisConfig.ShadowTranceScale / 100)
		NecrosisBuffMenu9:SetScale(NecrosisConfig.BanishScale / 100)

		-- Decide whether timers appear to the left or right of the button
		NecrosisListSpells:ClearAllPoints()
		NecrosisListSpells:SetJustifyH(NecrosisConfig.SpellTimerJust)
		NecrosisListSpells:SetPoint(
			"TOP" .. NecrosisConfig.SpellTimerJust,
			"NecrosisSpellTimerButton",
			"CENTER",
			NecrosisConfig.SpellTimerPos * 23,
			5
		)
		ShowUIPanel(NecrosisButton)

		-- Also choose the tooltip anchor for the timers
		if NecrosisConfig.SpellTimerJust == -23 then
			AnchorSpellTimerTooltip = "ANCHOR_LEFT"
		else
			AnchorSpellTimerTooltip = "ANCHOR_RIGHT"
		end

		-- Verify shards are inside the designated bag
		Necrosis_SoulshardSwitch("CHECK")

		-- Is the shard locked on the interface?
		if NecrosisConfig.NoDragAll then
			Necrosis_NoDrag()
			NecrosisButton:RegisterForDrag("")
			NecrosisSpellTimerButton:RegisterForDrag("")
		else
			Necrosis_Drag()
			NecrosisButton:RegisterForDrag("LeftButton")
			NecrosisSpellTimerButton:RegisterForDrag("LeftButton")
		end

		-- Are the buttons locked to the shard?
		Necrosis_ButtonSetup()

		-- If the Warlock wields a one-handed weapon, equip the first off-hand item
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetInventoryItem("player", 16)
		local itemName = tostring(NecrosisTooltipTextLeft2:GetText())
		if itemName == "Soulbound" then
			itemName = tostring(NecrosisTooltipTextLeft3:GetText())
		end
		Necrosis_MoneyToggle()
		if not GetInventoryItemLink("player", 17) and not string.find(itemName, NECROSIS_ITEM.Twohand) then
			Necrosis_SwitchOffHand(NECROSIS_ITEM.Offhand)
		end

		-- Initialize localization files -- enable SMS mode if needed
		Necrosis_LanguageInitialize()
		if NecrosisConfig.SM then
			NECROSIS_SOULSTONE_ALERT_MESSAGE = NECROSIS_SHORT_MESSAGES[1]
			NECROSIS_INVOCATION_MESSAGES = NECROSIS_SHORT_MESSAGES[2]
		end
	end
end

function Necrosis_LanguageInitialize()
	-- Localize speech.lua
	NecrosisLocalization()

	-- Localize XML
	NecrosisVersion:SetText(NecrosisData.Label)
	NecrosisShardsInventory_Section:SetText(NECROSIS_CONFIGURATION.ShardMenu)
	NecrosisShardsCount_Section:SetText(NECROSIS_CONFIGURATION.ShardMenu2)
	NecrosisSoulshardSort_Option:SetText(NECROSIS_CONFIGURATION.ShardMove)
	NecrosisSoulshardDestroy_Option:SetText(NECROSIS_CONFIGURATION.ShardDestroy)

	NecrosisMessageSpell_Section:SetText(NECROSIS_CONFIGURATION.SpellMenu1)
	NecrosisMessagePlayer_Section:SetText(NECROSIS_CONFIGURATION.SpellMenu2)
	NecrosisShadowTranceAlert_Option:SetText(NECROSIS_CONFIGURATION.TranseWarning)
	NecrosisAntiFearAlert_Option:SetText(NECROSIS_CONFIGURATION.AntiFearWarning)

	NecrosisShowTrance_Option:SetText(NECROSIS_CONFIGURATION.TranceButtonView)
	NecrosisIconsLock_Option:SetText(NECROSIS_CONFIGURATION.ButtonLock)

	NecrosisShowSpellstone_Option:SetText(NECROSIS_CONFIGURATION.Show.Spellstone)
	NecrosisShowHealthStone_Option:SetText(NECROSIS_CONFIGURATION.Show.Healthstone)
	NecrosisShowSoulstone_Option:SetText(NECROSIS_CONFIGURATION.Show.Soulstone)
	NecrosisShowMount_Option:SetText(NECROSIS_CONFIGURATION.Show.Steed)
	NecrosisShowBuffMenu_Option:SetText(NECROSIS_CONFIGURATION.Show.Buff)
	NecrosisShowPetMenu_Option:SetText(NECROSIS_CONFIGURATION.Show.Demon)
	NecrosisShowCurseMenu_Option:SetText(NECROSIS_CONFIGURATION.Show.Curse)
	NecrosisShowStoneMenu_Option:SetText(NECROSIS_CONFIGURATION.Show.Stone)
	NecrosisShowTooltips_Option:SetText(NECROSIS_CONFIGURATION.Show.Tooltips)

	NecrosisShowSpellTimers_Option:SetText(NECROSIS_CONFIGURATION.SpellTime)
	NecrosisGraphicalTimer_Section:SetText(NECROSIS_CONFIGURATION.TimerMenu)
	NecrosisGraphicalTimer_Option:SetText(NECROSIS_CONFIGURATION.GraphicalTimer)
	NecrosisTimerColor_Option:SetText(NECROSIS_CONFIGURATION.TimerColor)
	NecrosisTimerDirection_Option:SetText(NECROSIS_CONFIGURATION.TimerDirection)
	NecrosisTimerDebug_Option:SetText(NECROSIS_CONFIGURATION.TimerDebug)

	NecrosisLock_Option:SetText(NECROSIS_CONFIGURATION.MainLock)
	NecrosisBuffMenu_Option:SetText(NECROSIS_CONFIGURATION.BuffMenu)
	NecrosisPetMenu_Option:SetText(NECROSIS_CONFIGURATION.PetMenu)
	NecrosisCurseMenu_Option:SetText(NECROSIS_CONFIGURATION.CurseMenu)
	NecrosisStoneMenu_Option:SetText(NECROSIS_CONFIGURATION.StoneMenu)
	NecrosisShowCount_Option:SetText(NECROSIS_CONFIGURATION.ShowCount)
	NecrosisSTimer_Option:SetText(NECROSIS_CONFIGURATION.STimerLeft)

	NecrosisSound_Option:SetText(NECROSIS_CONFIGURATION.Sound)
	NecrosisShowMessage_Option:SetText(NECROSIS_CONFIGURATION.ShowMessage)
	NecrosisShowSteedSummon_Option:SetText(NECROSIS_CONFIGURATION.ShowSteedSummon)
	NecrosisShowDemonSummon_Option:SetText(NECROSIS_CONFIGURATION.ShowDemonSummon)
	NecrosisShowRitualSummon_Option:SetText(NECROSIS_CONFIGURATION.ShowRitualSummon)
	NecrosisChatType_Option:SetText(NECROSIS_CONFIGURATION.ChatType)

	NecrosisButtonRotate_SliderText:SetText(NECROSIS_CONFIGURATION.MainRotation)
	NecrosisCountType_SliderText:SetText(NECROSIS_CONFIGURATION.CountType)
	NecrosisCircle_SliderText:SetText(NECROSIS_CONFIGURATION.Circle)
	NecrosisBag_SliderText:SetText(NECROSIS_CONFIGURATION.BagSelect)
	NecrosisButtonScale_SliderText:SetText(NECROSIS_CONFIGURATION.NecrosisSize)
	NecrosisBanishScale_SliderText:SetText(NECROSIS_CONFIGURATION.BanishSize)
	ShadowTranceScale_SliderText:SetText(NECROSIS_CONFIGURATION.TranseSize)
	NecrosisColor_SliderText:SetText(NECROSIS_CONFIGURATION.Skin)
end

------------------------------------------------------------------------------------------------------
-- FUNCTION HANDLING THE /NECRO CONSOLE COMMAND
------------------------------------------------------------------------------------------------------

function Necrosis_SlashHandler(arg1)
	-- Blah blah blah, is the player really a Warlock? We'll figure it out!
	if UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end
	if string.find(string.lower(arg1), "recall") then
		NecrosisButton:ClearAllPoints()
		NecrosisButton:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
		NecrosisSpellTimerButton:ClearAllPoints()
		NecrosisSpellTimerButton:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
		NecrosisAntiFearButton:ClearAllPoints()
		NecrosisAntiFearButton:SetPoint("CENTER", "UIParent", "CENTER", 20, 0)
		NecrosisShadowTranceButton:ClearAllPoints()
		NecrosisShadowTranceButton:SetPoint("CENTER", "UIParent", "CENTER", -20, 0)
	elseif string.find(string.lower(arg1), "sm") then
		if NECROSIS_SOULSTONE_ALERT_MESSAGE == NECROSIS_SHORT_MESSAGES[1] then
			NecrosisConfig.SM = false
			NecrosisLocalization()
			Necrosis_Msg("Short Messages : <red>Off", "USER")
		else
			NecrosisConfig.SM = true
			NECROSIS_SOULSTONE_ALERT_MESSAGE = NECROSIS_SHORT_MESSAGES[1]
			NECROSIS_INVOCATION_MESSAGES = NECROSIS_SHORT_MESSAGES[2]
			Necrosis_Msg("Short Messages : <brightGreen>On", "USER")
		end
	elseif string.find(string.lower(arg1), "diag") then
		Necrosis_ToggleDiagnostics()
	elseif string.find(string.lower(arg1), "cast") then
		NecrosisSpellCast(string.lower(arg1))
	else
		if NECROSIS_MESSAGE.Help ~= nil then
			for i = 1, table.getn(NECROSIS_MESSAGE.Help), 1 do
				Necrosis_Msg(NECROSIS_MESSAGE.Help[i], "USER")
			end
		end
		Necrosis_Toggle()
	end
end

SlashCmdList = SlashCmdList or {}
SLASH_NECRO1 = "/necro"
SLASH_NECRO2 = "/necrosis"
SlashCmdList["NECRO"] = Necrosis_SlashHandler
