------------------------------------------------------------------------------------------------------
-- Necrosis Spell Accessors
------------------------------------------------------------------------------------------------------

Necrosis = Necrosis or {}
Necrosis.Spells = Necrosis.Spells or {}

local Spells = Necrosis.Spells
local table_getn = table.getn

Spells.Index = Spells.Index
	or {
		SUMMON_FELSTEED = 1,
		SUMMON_DREADSTEED = 2,
		SUMMON_IMP = 3,
		SUMMON_VOIDWALKER = 4,
		SUMMON_SUCCUBUS = 5,
		SUMMON_FELHUNTER = 6,
		INFERNO = 8,
		BANISH = 9,
		ENSLAVE_DEMON = 10,
		SOULSTONE_RESURRECTION = 11,
		FEL_DOMINATION = 15,
		CURSE_OF_DOOM = 16,
		SACRIFICE = 17,
		CURSE_OF_AGONY = 22,
		CURSE_OF_WEAKNESS = 23,
		CURSE_OF_RECKLESSNESS = 24,
		CURSE_OF_TONGUES = 25,
		CURSE_OF_THE_ELEMENTS = 26,
		CURSE_OF_SHADOW = 27,
		RITUAL_OF_DOOM = 30,
		DEMON_ARMOR = 31,
		UNENDING_BREATH = 32,
		DETECT_INVISIBILITY = 33,
		EYE_OF_KILROGG = 34,
		ENSLAVE_DEMON_EFFECT = 35,
		DEMON_SKIN = 36,
		RITUAL_OF_SUMMONING = 37,
		SOUL_LINK = 38,
		CURSE_OF_EXHAUSTION = 40,
		AMPLIFY_CURSE = 42,
		SHADOW_WARD = 43,
		DEMONIC_SACRIFICE = 44,
		SENSE_DEMONS = 39,
		CREATE_FELSTONE = 45,
		CREATE_WRATHSTONE = 46,
		CREATE_VOIDSTONE = 47,
	}

local function getSpellTable()
	if type(NECROSIS_SPELL_TABLE) ~= "table" then
		return nil
	end
	return NECROSIS_SPELL_TABLE
end

local function getField(data, field)
	if type(data) ~= "table" then
		return nil
	end
	return data[field]
end

function Spells:Get(index)
	if type(index) ~= "number" then
		return nil
	end
	local spells = getSpellTable()
	if not spells then
		return nil
	end
	return spells[index]
end

function Spells:GetField(index, fieldName)
	return getField(self:Get(index), fieldName)
end

function Spells:GetName(index, fallback)
	local value = self:GetField(index, "Name")
	if value ~= nil then
		return value
	end
	return fallback
end

function Spells:GetID(index)
	return self:GetField(index, "ID")
end

function Spells:HasID(index)
	return self:GetID(index) ~= nil
end

function Spells:GetType(index, fallback)
	local value = self:GetField(index, "Type")
	if value ~= nil then
		return value
	end
	return fallback
end

function Spells:GetLength(index, fallback)
	local value = self:GetField(index, "Length")
	if type(value) == "number" then
		return value
	end
	return fallback or 0
end

function Spells:GetMana(index, fallback)
	local value = self:GetField(index, "Mana")
	if type(value) == "number" then
		return value
	end
	return fallback
end

function Spells:GetRank(index, fallback)
	local value = self:GetField(index, "Rank")
	if value ~= nil then
		return value
	end
	return fallback
end

function Spells:GetCastTime(index, fallback)
	local value = self:GetField(index, "CastTime")
	if type(value) == "number" then
		return value
	end
	return fallback
end

function Spells:GetInitialDuration(index, fallback)
	local value = self:GetField(index, "Length")
	if type(value) == "number" then
		return value
	end
	return fallback
end

function Spells:Iterate(callback)
	if type(callback) ~= "function" then
		return
	end
	local spells = getSpellTable()
	if not spells then
		return
	end
	for index = 1, table_getn(spells) do
		local data = spells[index]
		if data ~= nil then
			local shouldContinue = callback(data, index)
			if shouldContinue == false then
				break
			end
		end
	end
end

function Spells:FindByName(name)
	if not name then
		return nil, 0
	end
	local spells = getSpellTable()
	if not spells then
		return nil, 0
	end
	for index = 1, table_getn(spells) do
		local data = spells[index]
		if data and data.Name == name then
			return data, index
		end
	end
	return nil, 0
end

function Spells:GetTypeOrDefault(index, defaultType)
	local value = self:GetType(index)
	if value ~= nil then
		return value
	end
	return defaultType
end

function Spells:GetIndex(key)
	if not key then
		return nil
	end
	return self.Index and self.Index[key]
end
