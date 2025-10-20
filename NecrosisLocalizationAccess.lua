------------------------------------------------------------------------------------------------------
-- Necrosis Localization Accessors
------------------------------------------------------------------------------------------------------

Necrosis = Necrosis or {}
Necrosis.Loc = Necrosis.Loc or {}

local Loc = Necrosis.Loc
local table_getn = table.getn

local function getMessageRoot()
	if type(NECROSIS_MESSAGE) ~= "table" then
		return nil
	end
	return NECROSIS_MESSAGE
end

local function getTooltipRoot()
	if type(NecrosisTooltipData) ~= "table" then
		return nil
	end
	return NecrosisTooltipData
end

local function resolveNested(root, keys)
	if type(root) ~= "table" then
		return nil
	end
	for index = 1, table_getn(keys) do
		local key = keys[index]
		if type(root) ~= "table" then
			return nil
		end
		root = root[key]
		if root == nil then
			return nil
		end
	end
	return root
end

function Loc:GetMessages()
	return getMessageRoot()
end

function Loc:GetMessageSection(section)
	local root = getMessageRoot()
	if type(root) ~= "table" then
		return nil
	end
	return root[section]
end

function Loc:GetMessage(section, key, fallback)
	if not section then
		return fallback
	end
	local sectionTable = self:GetMessageSection(section)
	if type(sectionTable) ~= "table" then
		return fallback
	end
	local value = sectionTable[key]
	if value ~= nil then
		return value
	end
	return fallback
end

function Loc:GetMessageNested(keys, fallback)
	if type(keys) ~= "table" then
		return fallback
	end
	local value = resolveNested(getMessageRoot(), keys)
	if value ~= nil then
		return value
	end
	return fallback
end

function Loc:GetTooltip(section)
	local root = getTooltipRoot()
	if type(root) ~= "table" then
		return nil
	end
	return root[section]
end

function Loc:GetTooltipField(section, key, fallback)
	local tooltip = self:GetTooltip(section)
	if type(tooltip) ~= "table" then
		return fallback
	end
	local value = tooltip[key]
	if value ~= nil then
		return value
	end
	return fallback
end

function Loc:GetTooltipNested(section, keys, fallback)
	local tooltip = self:GetTooltip(section)
	if type(tooltip) ~= "table" then
		return fallback
	end
	if type(keys) ~= "table" then
		return fallback
	end
	local value = resolveNested(tooltip, keys)
	if value ~= nil then
		return value
	end
	return fallback
end
