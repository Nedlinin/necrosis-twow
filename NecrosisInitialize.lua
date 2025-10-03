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
		if NecrosisConfig == nil then
			NecrosisConfig = Default_NecrosisConfig
			Necrosis_Msg(NECROSIS_MESSAGE.Interface.DefaultConfig, "USER")
			NecrosisButton:ClearAllPoints()
			NecrosisShadowTranceButton:ClearAllPoints()
			NecrosisAntiFearButton:ClearAllPoints()
			NecrosisSpellTimerButton:ClearAllPoints()
			NecrosisButton:SetPoint("CENTER", "UIParent", "CENTER", 0, -100)
			NecrosisShadowTranceButton:SetPoint("CENTER", "UIParent", "CENTER", 100, -30)
			NecrosisAntiFearButton:SetPoint("CENTER", "UIParent", "CENTER", 100, 30)
			NecrosisSpellTimerButton:SetPoint("CENTER", "UIParent", "CENTER", 120, 340)
		else
			if NecrosisConfig.Version ~= Default_NecrosisConfig.Version then
				Necrosis_DeepMerge(NecrosisConfig, Default_NecrosisConfig)
				NecrosisConfig.Version = Default_NecrosisConfig.Version
			end
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
		if NecrosisConfig.SoulshardSort then
			NecrosisSoulshardSort_Button:SetChecked(1)
		end
		if NecrosisConfig.SoulshardDestroy then
			NecrosisSoulshardDestroy_Button:SetChecked(1)
		end
		if NecrosisConfig.ShadowTranceAlert then
			NecrosisShadowTranceAlert_Button:SetChecked(1)
		end
		if NecrosisConfig.ShowSpellTimers then
			NecrosisShowSpellTimers_Button:SetChecked(1)
		end
		if NecrosisConfig.AntiFearAlert then
			NecrosisAntiFearAlert_Button:SetChecked(1)
		end
		if NecrosisConfig.NecrosisLockServ then
			NecrosisIconsLock_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.Healthstone] then
			NecrosisShowHealthStone_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.Spellstone] then
			NecrosisShowSpellstone_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.Soulstone] then
			NecrosisShowSoulstone_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.BuffMenu] then
			NecrosisShowBuffMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.Mount] then
			NecrosisShowMount_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.PetMenu] then
			NecrosisShowPetMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.CurseMenu] then
			NecrosisShowCurseMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.StonePosition[StonePos.StoneMenu] then
			NecrosisShowStoneMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.NecrosisToolTip then
			NecrosisShowTooltips_Button:SetChecked(1)
		end
		if NecrosisConfig.Sound then
			NecrosisSound_Button:SetChecked(1)
		end
		if NecrosisConfig.ShowCount then
			NecrosisShowCount_Button:SetChecked(1)
		end
		if NecrosisConfig.BuffMenuPos == -34 then
			NecrosisBuffMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.PetMenuPos == -34 then
			NecrosisPetMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.CurseMenuPos == -34 then
			NecrosisCurseMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.StoneMenuPos == -34 then
			NecrosisStoneMenu_Button:SetChecked(1)
		end
		if NecrosisConfig.NoDragAll then
			NecrosisLock_Button:SetChecked(1)
		end
		if NecrosisConfig.SpellTimerPos == -1 then
			NecrosisSTimer_Button:SetChecked(1)
		end
		if NecrosisConfig.ChatMsg then
			NecrosisShowMessage_Button:SetChecked(1)
		end
		if NecrosisConfig.DemonSummon then
			NecrosisShowDemonSummon_Button:SetChecked(1)
		end
		if NecrosisConfig.SteedSummon then
			NecrosisShowSteedSummon_Button:SetChecked(1)
		end
		if NecrosisConfig.RitualMessage then
			NecrosisShowRitualSummon_Button:SetChecked(1)
		end
		if not NecrosisConfig.ChatType then
			NecrosisChatType_Button:SetChecked(1)
		end
		if NecrosisConfig.Graphical then
			NecrosisGraphicalTimer_Button:SetChecked(1)
		end
		if not NecrosisConfig.Yellow then
			NecrosisTimerColor_Button:SetChecked(1)
		end
		if NecrosisConfig.SensListe == -1 then
			NecrosisTimerDirection_Button:SetChecked(1)
		end

		-- Slider settings
		NecrosisButtonRotate_Slider:SetValue(NecrosisConfig.NecrosisAngle)
		NecrosisButtonRotate_SliderLow:SetText("0")
		NecrosisButtonRotate_SliderHigh:SetText("360")

		if NecrosisConfig.NecrosisLanguage == "deDE" then
			NecrosisLanguage_Slider:SetValue(3)
		elseif NecrosisConfig.NecrosisLanguage == "enUS" then
			NecrosisLanguage_Slider:SetValue(2)
		else
			NecrosisLanguage_Slider:SetValue(1)
		end
		NecrosisLanguage_SliderText:SetText("Langue / Language / Sprache")
		NecrosisLanguage_SliderLow:SetText("")
		NecrosisLanguage_SliderHigh:SetText("")

		NecrosisBag_Slider:SetValue(4 - NecrosisConfig.SoulshardContainer)
		NecrosisBag_SliderLow:SetText("5")
		NecrosisBag_SliderHigh:SetText("1")

		NecrosisCountType_Slider:SetValue(NecrosisConfig.CountType)
		NecrosisCountType_SliderLow:SetText("")
		NecrosisCountType_SliderHigh:SetText("")

		NecrosisCircle_Slider:SetValue(NecrosisConfig.Circle)
		NecrosisCircle_SliderLow:SetText("")
		NecrosisCircle_SliderHigh:SetText("")

		ShadowTranceScale_Slider:SetValue(NecrosisConfig.ShadowTranceScale)
		ShadowTranceScale_SliderLow:SetText("50%")
		ShadowTranceScale_SliderHigh:SetText("150%")

		if NecrosisConfig.NecrosisColor == "Rose" then
			NecrosisColor_Slider:SetValue(1)
		elseif NecrosisConfig.NecrosisColor == "Bleu" then
			NecrosisColor_Slider:SetValue(2)
		elseif NecrosisConfig.NecrosisColor == "Orange" then
			NecrosisColor_Slider:SetValue(3)
		elseif NecrosisConfig.NecrosisColor == "Turquoise" then
			NecrosisColor_Slider:SetValue(4)
		elseif NecrosisConfig.NecrosisColor == "Violet" then
			NecrosisColor_Slider:SetValue(5)
		else
			NecrosisColor_Slider:SetValue(6)
		end
		NecrosisColor_SliderLow:SetText("")
		NecrosisColor_SliderHigh:SetText("")

		NecrosisButtonScale_Slider:SetValue(NecrosisConfig.NecrosisButtonScale)
		NecrosisButtonScale_SliderLow:SetText("50 %")
		NecrosisButtonScale_SliderHigh:SetText("150 %")

		NecrosisBanishScale_Slider:SetValue(NecrosisConfig.BanishScale)
		NecrosisBanishScale_SliderLow:SetText("100 %")
		NecrosisBanishScale_SliderHigh:SetText("200 %")

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
