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
-- Version 05.09.2006-1
------------------------------------------------------------------------------------------------------

------------------------------------------------
-- FRENCH VERSION FUNCTIONS --
------------------------------------------------

function Necrosis_Localization_Functions_Fr()
	NECROSIS_UNIT_WARLOCK = "D\195\169moniste"

	NECROSIS_ANTI_FEAR_SPELL = {
		-- Buffs giving temporary immunity to fear effects
		["Buff"] = {
			"Gardien de peur", -- Dwarf priest racial trait
			"Volont\195\169 des r\195\169prouv\195\169", -- Forsaken racial trait
			"Sans peur", -- Trinket
			"Furie Berzerker", -- Warrior Fury talent
			"T\195\169m\195\169rit\195\169", -- Warrior Fury talent
			"Souhait mortel", -- Warrior Fury talent
			"Courroux bestial", -- Hunter Beast Mastery talent (pet only)
			"Carapace de glace", -- Mage Ice talent
			"Protection divine", -- Paladin Holy buff
			"Bouclier divin", -- Paladin Holy buff
			"Totem de s\195\169isme", -- Shaman totem
			"Abolir la magie", -- Majordomo (NPC) spell
			--  "Grounding Totem" is not considerated, as it can remove other spell than fear, and only one each 10 sec.
		},

		-- Debuffs and curses giving temporary immunity to fear effects
		["Debuff"] = {
			"Mal\195\169diction de t\195\169m\195\169rit\195\169", -- Warlock curse
		},
	}

	-- Creature type absolutly immune to fear effects
	NECROSIS_ANTI_FEAR_UNIT = {
		"Mort-vivant",
	}

	-- Word to search for spell immunity. First (.+) replace the spell's name, 2nd (.+) replace the creature's name
	NECROSIS_ANTI_FEAR_SRCH = "Votre (.+) rate. (.+) y est insensible."

	local localizedSpellOverrides = {
		[1] = "Invocation d'un palefroi corrompu",
		[2] = "Invocation d'un destrier de l'effroi",
		[3] = "Invocation d'un diablotin",
		[4] = "Invocation d'un marcheur du Vide",
		[5] = "Invocation d'une succube",
		[6] = "Invocation d'un chasseur corrompu",
		[7] = "Trait de l'ombre",
		[8] = "Inferno",
		[9] = "Bannir",
		[10] = "Asservir d\195\169mon",
		[11] = "R\195\169surrection de Pierre d'\195\162me",
		[12] = "Immolation",
		[13] = "Peur",
		[14] = "Corruption",
		[15] = "Domination corrompue",
		[16] = "Mal\195\169diction funeste",
		[17] = "Sacrifice",
		[18] = "Feu de l'\195\162me",
		[19] = "Voile mortel",
		[20] = "Br\195\187lure de l'ombre",
		[21] = "Conflagration",
		[22] = "Mal\195\169diction d'agonie",
		[23] = "Mal\195\169diction de faiblesse",
		[24] = "Mal\195\169diction de t\195\169m\195\169rit\195\169",
		[25] = "Mal\195\169diction des langages",
		[26] = "Mal\195\169diction des \195\169l\195\169ments",
		[27] = "Mal\195\169diction de l'ombre",
		[28] = "Siphon de vie",
		[29] = "Hurlement de terreur",
		[30] = "Rituel de mal\195\169diction",
		[31] = "Armure d\195\169moniaque",
		[32] = "Respiration interminable",
		[33] = "Invisibilit\195\169",
		[34] = "Oeil de Kilrogg",
		[35] = "Asservir d\195\169mon",
		[36] = "Peau de d\195\169mon",
		[37] = "Rituel d'invocation",
		[38] = "Lien spirituel",
		[39] = "D\195\169tection des d\195\169mons",
		[40] = "Mal\195\169diction de fatigue",
		[41] = "Connexion",
		[42] = "Mal\195\169diction amplifi\195\169e",
		[43] = "Gardien de l'ombre",
		[44] = "Sacrifice d\195\169moniaque",
		[45] = "Création de Pierre gangrenée",
		[46] = "Création de Pierre de colère",
		[47] = "Création de Pierre du Vide",
	}

	NECROSIS_SPELL_TABLE = Necrosis_BuildSpellTable(localizedSpellOverrides)

	-- NECROSIS_TIMER_TYPE.NONE = No timer
	-- NECROSIS_TIMER_TYPE.PRIMARY = Primary persistent timer
	-- NECROSIS_TIMER_TYPE.SELF_BUFF = Persistent timer
	-- NECROSIS_TIMER_TYPE.COOLDOWN = Cooldown timer
	-- NECROSIS_TIMER_TYPE.CURSE = Curse timer
	-- NECROSIS_TIMER_TYPE.COMBAT = Combat timer

	NECROSIS_STONE_RANK = {
		[1] = " (mineure)", -- Rank Minor
		[2] = " (inf\195\169rieure)", -- Rank Lesser
		[3] = "", -- Rank Intermediate, no name
		[4] = " (sup\195\169rieure)", -- Rank Greater
		[5] = " (majeure)", -- Rank Major
	}

	NECROSIS_NIGHTFALL = {
		["BoltName"] = "Trait",
		["ShadowTrance"] = "Transe de l'ombre",
	}

	NECROSIS_CREATE = {
		[1] = "Cr\195\169ation de Pierre d'\195\162me",
		[2] = "Cr\195\169ation de Pierre de soins",
		[3] = "Cr\195\169ation de Pierre de sort",
		[4] = "Cr\195\169ation de Pierre de feu",
		[5] = "Cr\195\169ation de Pierre gangrenée",
		[6] = "Cr\195\169ation de Pierre de colère",
		[7] = "Cr\195\169ation de Pierre du Vide",
	}

	NECROSIS_PET_LOCAL_NAME = {
		[1] = "Diablotin",
		[2] = "Marcheur du Vide",
		[3] = "Succube",
		[4] = "Chasseur corrompu",
		[5] = "Infernal",
		[6] = "Garde funeste",
	}

	NECROSIS_TRANSLATION = {
		["Cooldown"] = "Temps",
		["Hearth"] = "Pierre de foyer",
		["Rank"] = "Rang",
		["Invisible"] = "D\195\169tection de l'invisibilit\195\169",
		["LesserInvisible"] = "D\195\169tection de l'invisibilit\195\169 inf\195\169rieure",
		["GreaterInvisible"] = "D\195\169tection de l'invisibilit\195\169 sup\195\169rieure",
		["SoulLinkGain"] = "Vous gagnez Lien spirituel.",
		["SacrificeGain"] = "Vous gagnez Sacrifice.",
		["SummoningRitual"] = "Rituel d'invocation",
	}
end

-- Auto-initialize on load if client locale matches
if GetLocale() == "frFR" then
	Necrosis_Localization_Functions_Fr()
end
