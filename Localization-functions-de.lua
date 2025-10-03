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

if GetLocale() == "deDE" then
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

	NECROSIS_SPELL_TABLE = {
		[1] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Teufelsross beschw\195\182ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[2] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Schreckensross herbeirufen",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[3] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Wichtel beschw\195\182ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[4] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Leerwandler beschw\195\182ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[5] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Sukkubus beschw\195\182ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[6] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Teufelsj\195\164ger beschw\195\182ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[7] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Schattenblitz",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[8] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Inferno",
			Length = 3600,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[9] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Verbannen",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[10] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monensklave",
			Length = 30000,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[11] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Seelenstein-Auferstehung",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.PRIMARY,
		},
		[12] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Feuerbrand",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[13] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Furcht",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[14] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Verderbnis",
			Length = 17,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[15] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Teufelsbeherrschung",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[16] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Verdammnis",
			Length = 60,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[17] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Opferung",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[18] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Seelenfeuer",
			Length = 60,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[19] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Todesmantel",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[20] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Schattenbrand",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[21] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Feuersbrunst",
			Length = 10,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[22] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Pein",
			Length = 24,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[23] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Schw\195\164che",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[24] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Tollk\195\188hnheit",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[25] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Sprachen",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[26] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Elemente",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[27] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Schatten",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[28] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Lebensentzug",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[29] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Schreckengeh\195\164ul",
			Length = 40,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[30] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Ritual der Verdammnis",
			Length = 3600,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[31] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monenr\195\188stung",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[32] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Unendlicher Atem",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[33] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Unsichtbarkeit",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[34] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Auge von Kilrogg",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[35] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monensklave",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[36] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monenhaut",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[37] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Ritual der Beschw\195\182rung",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[38] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Seelenverbindung",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[39] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monen sp\195\188ren",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[40] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch der Ersch\195\182pfung",
			Length = 12,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[41] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Aderlass",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[42] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fluch verst\195\164rken",
			Length = 180,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[43] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Schattenzauberschutz",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[44] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "D\195\164monische Opferung",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[45] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Teufelsstein herstellen",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[46] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Zornstein herstellen",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[47] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Leerenstein herstellen",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
	}
	-- NECROSIS_TIMER_TYPE.NONE = No timer
	-- NECROSIS_TIMER_TYPE.PRIMARY = Primary persistent timer
	-- NECROSIS_TIMER_TYPE.SELF_BUFF = Persistent timer
	-- NECROSIS_TIMER_TYPE.COOLDOWN = Cooldown timer
	-- NECROSIS_TIMER_TYPE.CURSE = Curse timer
	-- NECROSIS_TIMER_TYPE.COMBAT = Combat timer

	NECROSIS_ITEM = {
		["Soulshard"] = "Seelensplitter",
		["Soulstone"] = "Seelenstein",
		["Healthstone"] = "Gesundheitsstein",
		["Spellstone"] = "Zauberstein",
		["Firestone"] = "Feuerstein",
		["Felstone"] = "Teufelsstein",
		["Wrathstone"] = "Zornstein",
		["Voidstone"] = "Leerenstein",
		["Offhand"] = "Schildhand",
		["Twohand"] = "Zweihand",
		["InfernalStone"] = "H\195\182llenstein",
		["DemoniacStone"] = "D\195\164monenstatuette",
		["Hearthstone"] = "Ruhestein",
		["SoulPouch"] = { "Seelenbeutel", "Teufelsstofftasche", "Kernteufelsstofftasche" },
	}

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
