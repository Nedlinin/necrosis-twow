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

NECROSIS_TIMER_TYPE = {
	NONE = 0,
	PRIMARY = 1,
	SELF_BUFF = 2,
	COOLDOWN = 3,
	CURSE = 4,
	COMBAT = 5,
	CUSTOM = 6,
}
NECROSIS_SPELL_TEMPLATE = {
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

function Necrosis_BuildSpellTable(localizedOverrides)
	localizedOverrides = localizedOverrides or {}
	local spells = {}

	for index, base in ipairs(NECROSIS_SPELL_TEMPLATE) do
		local entry = {}
		for key, value in pairs(base) do
			entry[key] = value
		end

		local override = localizedOverrides[index]
		if type(override) == "string" then
			entry.Name = override
		elseif type(override) == "table" then
			for key, value in pairs(override) do
				entry[key] = value
			end
		end

		spells[index] = entry
	end

	return spells
end

NecrosisData = {}
NecrosisData.Version = "1.6.0"
NecrosisData.Author = "Lomig & Nyx"
NecrosisData.AppName = "Necrosis"
NecrosisData.Label = NecrosisData.AppName .. " " .. NecrosisData.Version .. " by " .. NecrosisData.Author

-- Keyboard shortcuts
BINDING_HEADER_NECRO_BIND = "Necrosis"

BINDING_NAME_SOULSTONE = "Pierre d'\195\162me / Soulstone"
BINDING_NAME_HEALTHSTONE = "Pierre de soins / Healthstone"
BINDING_NAME_SPELLSTONE = "Pierre de sort / Spellstone"
BINDING_NAME_FIRESTONE = "Pierre de feu / Firestone"
BINDING_NAME_STEED = "Monture / Steed"
BINDING_NAME_WARD = "Gardien de l'ombre / Shadow Ward"
BINDING_NAME_BANISH = "Bannir / Ban"
BINDING_NAME_LIFETAP = "Connexion / Life tap"
BINDING_NAME_REDOCURSE = "Relancer la mal\195\169diction / Recast the last curse"
