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

------------------------------------------------
-- GERMAN  VERSION FUNCTIONS --
------------------------------------------------

function Necrosis_Localization_Functions_De()
	NECROSIS_UNIT_WARLOCK = "Hexenmeister"

	NECROSIS_ANTI_FEAR_SPELL = {
		-- Buffs that grant temporary immunity to fear
		["Buff"] = {
			"Furchtzauberschutz", -- Dwarf priest racial trait
			"Wille der Verlassenen", -- Forsaken racial trait
			"Furchtlos", -- Trinket
			"Berserkerwut", -- Warrior Fury talent
			"Tollk\195\188hnheit", -- Warrior Fury talent
			"Todeswunsch", -- Warrior Fury talent
			"Zorn des Wildtieres", -- Hunter Beast Mastery talent (pet only)
			"Eisblock", -- Mage Ice talent
			"G\195\182ttlicher Schutz", -- Paladin Holy buff
			"Gottesschild", -- Paladin Holy buff
			"Totem des Erdsto\195\159es", -- Shaman totem
			"Abolish Magic", -- Majordomo (NPC) spell
			--  "Grounding Totem" is not considerated, as it can remove other spell than fear, and only one each 10 sec.
		},

		-- Debuffs and curses giving temporary immunity to fear effects
		["Debuff"] = {
			"Fluch der Tollk\195\188hnheit", -- Warlock curse
		},
	}

	-- Creature type absolutly immune to fear effects
	NECROSIS_ANTI_FEAR_UNIT = {
		"Untoter",
	}

	-- Word to search for spell immunity. First (.+) replace the spell's name, 2nd (.+) replace the creature's name
	NECROSIS_ANTI_FEAR_SRCH = "(.+) war ein Fehlschlag. (.+) ist immun."

	local localizedSpellOverrides = {
		[1] = "Teufelsross beschw\195\182ren",
		[2] = "Schreckensross herbeirufen",
		[3] = "Wichtel beschw\195\182ren",
		[4] = "Leerwandler beschw\195\182ren",
		[5] = "Sukkubus beschw\195\182ren",
		[6] = "Teufelsj\195\164ger beschw\195\182ren",
		[7] = "Schattenblitz",
		[8] = "Inferno",
		[9] = "Verbannen",
		[10] = "D\195\164monensklave",
		[11] = "Seelenstein-Auferstehung",
		[12] = "Feuerbrand",
		[13] = "Furcht",
		[14] = "Verderbnis",
		[15] = "Teufelsbeherrschung",
		[16] = "Fluch der Verdammnis",
		[17] = "Opferung",
		[18] = "Seelenfeuer",
		[19] = "Todesmantel",
		[20] = "Schattenbrand",
		[21] = "Feuersbrunst",
		[22] = "Fluch der Pein",
		[23] = "Fluch der Schw\195\164che",
		[24] = "Fluch der Tollk\195\188hnheit",
		[25] = "Fluch der Sprachen",
		[26] = "Fluch der Elemente",
		[27] = "Fluch der Schatten",
		[28] = "Lebensentzug",
		[29] = "Schreckengeh\195\164ul",
		[30] = "Ritual der Verdammnis",
		[31] = "D\195\164monenr\195\188stung",
		[32] = "Unendlicher Atem",
		[33] = "Unsichtbarkeit",
		[34] = "Auge von Kilrogg",
		[35] = "D\195\164monensklave",
		[36] = "D\195\164monenhaut",
		[37] = "Ritual der Beschw\195\182rung",
		[38] = "Seelenverbindung",
		[39] = "D\195\164monen sp\195\188ren",
		[40] = "Fluch der Ersch\195\182pfung",
		[41] = "Aderlass",
		[42] = "Fluch verst\195\164rken",
		[43] = "Schattenzauberschutz",
		[44] = "D\195\164monische Opferung",
		[45] = "Teufelsstein herstellen",
		[46] = "Zornstein herstellen",
		[47] = "Leerenstein herstellen",
	}

	NECROSIS_SPELL_TABLE = Necrosis_BuildSpellTable(localizedSpellOverrides)

	-- NECROSIS_TIMER_TYPE.NONE = No timer
	-- NECROSIS_TIMER_TYPE.PRIMARY = Primary persistent timer
	-- NECROSIS_TIMER_TYPE.SELF_BUFF = Persistent timer
	-- NECROSIS_TIMER_TYPE.COOLDOWN = Cooldown timer
	-- NECROSIS_TIMER_TYPE.CURSE = Curse timer
	-- NECROSIS_TIMER_TYPE.COMBAT = Combat timer

	NECROSIS_STONE_RANK = {
		[1] = " (schwach)", -- Rank Minor
		[2] = " (gering)", -- Rank Lesser
		[3] = "", -- Rank Intermediate, no name
		[4] = " (gro\195\159)", -- Rank Greater
		[5] = " (erheblich)", -- Rank Major
	}

	NECROSIS_NIGHTFALL = {
		["BoltName"] = "blitz",
		["ShadowTrance"] = "Schattentrance",
	}

	NECROSIS_CREATE = {
		[1] = "Seelenstein herstellen",
		[2] = "Gesundheitsstein herstellen",
		[3] = "Zauberstein herstellen",
		[4] = "Feuerstein herstellen",
		[5] = "Teufelsstein herstellen",
		[6] = "Zornstein herstellen",
		[7] = "Leerenstein herstellen",
	}

	NECROSIS_PET_LOCAL_NAME = {
		[1] = "Wichtel",
		[2] = "Leerwandler",
		[3] = "Sukkubus",
		[4] = "Teufelsj\195\164ger",
		[5] = "H\195\182llenbestie",
		[6] = "Verdammniswache",
	}

	NECROSIS_TRANSLATION = {
		["Cooldown"] = "Cooldown",
		["Hearth"] = "Ruhestein",
		["Rank"] = "Rang",
		["Invisible"] = "Unsichtbarkeit entdecken",
		["LesserInvisible"] = "Geringe Unsichtbarkeit entdecken",
		["GreaterInvisible"] = "Gro\195\159e Unsichtbarkeit entdecken",
		["SoulLinkGain"] = "Du bekommst Seelenverbindung.",
		["SacrificeGain"] = "Du bekommst Opferung.",
		["SummoningRitual"] = "Ritual der Beschw\195\182rung",
	}
end

-- Auto-initialize on load if client locale matches
if GetLocale() == "deDE" then
	Necrosis_Localization_Functions_De()
end
