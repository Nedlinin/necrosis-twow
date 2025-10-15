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

function Necrosis_Localization_Functions_En()
	NECROSIS_UNIT_WARLOCK = "Warlock"

	NECROSIS_ANTI_FEAR_SPELL = {
		-- Buffs giving temporary immunity to fear effects
		["Buff"] = {
			"Fear Ward", -- Dwarf priest racial trait
			"Will of the Forsaken", -- Forsaken racial trait
			"Fearless", -- Trinket
			"Berserker Rage", -- Warrior Fury talent
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

	NECROSIS_SPELL_TABLE = Necrosis_BuildSpellTable()

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

-- Auto-initialize on load if client locale matches
if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
	Necrosis_Localization_Functions_En()
end
