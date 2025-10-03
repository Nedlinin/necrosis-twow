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
-- Version 06.05.2006-1
------------------------------------------------------------------------------------------------------

------------------------------------------------
-- ENGLISH  VERSION FUNCTIONS --
------------------------------------------------

if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
	NECROSIS_UNIT_WARLOCK = "Warlock"

	NECROSIS_ANTI_FEAR_SPELL = {
		-- Buffs giving temporary immunity to fear effects
		["Buff"] = {
			"Fear Ward", -- Dwarf priest racial trait
			"Will of the Forsaken", -- Forsaken racial trait
			"Fearless", -- Trinket
			"Berzerker Rage", -- Warrior Fury talent
			"Recklessness", -- Warrior Fury talent
			"Death Wish", -- Warrior Fury talent
			"Bestial Wrath", -- Hunter Beast Mastery talent (pet only)
			"Ice Block", -- Mage Ice talent
			"Divine Protection", -- Paladin Holy buff
			"Divine Shield", -- Paladin Holy buff
			"Tremor Totem", -- Shaman totem
			"Abolish Magic", -- Majordomo (NPC) spell
			--  "Grounding Totem" is not considerated, as it can remove other spell than fear, and only one each 10 sec.
		},

		-- Debuffs and curses giving temporary immunity to fear effects
		["Debuff"] = {
			"Curse of Recklessness", -- Warlock curse
		},
	}

	-- Creature type absolutly immune to fear effects
	NECROSIS_ANTI_FEAR_UNIT = {
		"Undead",
	}

	-- Word to search for spell immunity. First (.+) replace the spell's name, 2nd (.+) replace the creature's name
	NECROSIS_ANTI_FEAR_SRCH = "Your (.+) failed. (.+) is immune."

	NECROSIS_SPELL_TABLE = {
		[1] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Felsteed",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[2] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Dreadsteed",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[3] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Imp",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[4] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Voidwalker",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[5] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Succubus",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[6] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Summon Felhunter",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[7] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Shadow Bolt",
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
			Name = "Banish",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[10] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Enslave Demon",
			Length = 30000,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[11] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Soulstone Resurrection",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.PRIMARY,
		},
		[12] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Immolate",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[13] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fear",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[14] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Corruption",
			Length = 17,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[15] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Fel Domination",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[16] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Doom",
			Length = 60,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[17] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Sacrifice",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[18] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Soul Fire",
			Length = 60,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[19] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Death Coil",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[20] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Shadowburn",
			Length = 15,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[21] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Conflagrate",
			Length = 10,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[22] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Agony",
			Length = 24,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[23] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Weakness",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[24] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Recklessness",
			Length = 120,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[25] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Tongues",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[26] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of the Elements",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[27] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Shadow",
			Length = 300,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[28] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Siphon Life",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COMBAT,
		},
		[29] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Howl of Terror",
			Length = 40,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[30] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Ritual of Doom",
			Length = 3600,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[31] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Demon Armor",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[32] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Unending Breath",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[33] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Invisibility",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[34] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Eye of Kilrogg",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[35] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Enslave Demon",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[36] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Demon Skin",
			Length = 1800,
			Type = NECROSIS_TIMER_TYPE.SELF_BUFF,
		},
		[37] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Ritual of Summoning",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[38] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Soul Link",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[39] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Sense Demons",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[40] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Curse of Exhaustion",
			Length = 12,
			Type = NECROSIS_TIMER_TYPE.CURSE,
		},
		[41] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Life Tap",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[42] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Amplify Curse",
			Length = 180,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[43] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Shadow Ward",
			Length = 30,
			Type = NECROSIS_TIMER_TYPE.COOLDOWN,
		},
		[44] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Demonic Sacrifice",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[45] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Create Felstone",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[46] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Create Wrathstone",
			Length = 0,
			Type = NECROSIS_TIMER_TYPE.NONE,
		},
		[47] = {
			ID = nil,
			Rank = nil,
			CastTime = nil,
			Mana = nil,
			Name = "Create Voidstone",
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
		["Soulshard"] = "Soul Shard",
		["Soulstone"] = "Soulstone",
		["Healthstone"] = "Healthstone",
		["Spellstone"] = "Spellstone",
		["Firestone"] = "Firestone",
		["Felstone"] = "Felstone",
		["Wrathstone"] = "Wrathstone",
		["Voidstone"] = "Voidstone",
		["Offhand"] = "Held In Off-hand",
		["Twohand"] = "Two-Hand",
		["InfernalStone"] = "Infernal Stone",
		["DemoniacStone"] = "Demonic Figurine",
		["Hearthstone"] = "Hearthstone",
		["SoulPouch"] = { "Soul Pouch", "Felcloth Bag", "Core Felcloth Bag" },
	}

	NECROSIS_STONE_RANK = {
		[1] = " (Minor)", -- Rank Minor
		[2] = " (Lesser)", -- Rank Lesser
		[3] = "", -- Rank Intermediate, no name
		[4] = " (Greater)", -- Rank Greater
		[5] = " (Major)", -- Rank Major
	}

	NECROSIS_NIGHTFALL = {
		["BoltName"] = "Bolt",
		["ShadowTrance"] = "Shadow Trance",
	}

	NECROSIS_CREATE = {
		[1] = "Create Soulstone",
		[2] = "Create Healthstone",
		[3] = "Create Spellstone",
		[4] = "Create Firestone",
		[5] = "Create Felstone",
		[6] = "Create Wrathstone",
		[7] = "Create Voidstone",
	}

	NECROSIS_PET_LOCAL_NAME = {
		[1] = "Imp",
		[2] = "Voidwalker",
		[3] = "Succubus",
		[4] = "Felhunter",
		[5] = "Inferno",
		[6] = "Doomguard",
	}

	NECROSIS_TRANSLATION = {
		["Cooldown"] = "Cooldown",
		["Hearth"] = "Hearthstone",
		["Rank"] = "Rank",
		["Invisible"] = "Detect Invisibility",
		["LesserInvisible"] = "Detect Lesser Invisibility",
		["GreaterInvisible"] = "Detect Greater Invisibility",
		["SoulLinkGain"] = "You gain Soul Link.",
		["SacrificeGain"] = "You gain Sacrifice.",
		["SummoningRitual"] = "Ritual of Summoning",
	}
end
