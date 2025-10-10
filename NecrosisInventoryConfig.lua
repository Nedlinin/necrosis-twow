------------------------------------------------------------------------------------------------------
-- Necrosis Inventory Configuration
------------------------------------------------------------------------------------------------------

NecrosisInventoryConfig = NecrosisInventoryConfig or {}
local InventoryConfig = NecrosisInventoryConfig

InventoryConfig.stoneKeys = InventoryConfig.stoneKeys
	or { "Soulstone", "Healthstone", "Spellstone", "Firestone", "Felstone", "Wrathstone", "Voidstone", "Hearthstone" }
InventoryConfig.stoneNamePatterns = InventoryConfig.stoneNamePatterns or {}
InventoryConfig.offhandPatterns = InventoryConfig.offhandPatterns or {}

local function wipeTable(target)
	if type(target) ~= "table" then
		return
	end
	for key in pairs(target) do
		target[key] = nil
	end
end

function InventoryConfig:GetStoneKeys()
	return self.stoneKeys
end

function InventoryConfig:BuildStoneNamePatterns()
	local patterns = self.stoneNamePatterns
	wipeTable(patterns)
	if type(NECROSIS_ITEM) ~= "table" then
		return patterns
	end
	for index = 1, table.getn(self.stoneKeys) do
		local key = self.stoneKeys[index]
		local pattern = NECROSIS_ITEM[key]
		if pattern and type(pattern) == "string" then
			patterns[key] = pattern
		end
	end
	return patterns
end

function InventoryConfig:EnsureStoneNamePatterns()
	if not next(self.stoneNamePatterns) then
		self:BuildStoneNamePatterns()
	end
	return self.stoneNamePatterns
end

function InventoryConfig:GetStoneNamePatterns()
	return self.stoneNamePatterns
end

function InventoryConfig:BuildOffhandPattern()
	self.offhandPatterns[1] = nil
	if type(NECROSIS_ITEM) == "table" and type(NECROSIS_ITEM.Offhand) == "string" then
		self.offhandPatterns[1] = NECROSIS_ITEM.Offhand
	end
	return self.offhandPatterns[1]
end

function InventoryConfig:GetOffhandPattern()
	return self.offhandPatterns[1] or self:BuildOffhandPattern()
end

function InventoryConfig:IsOffhandTooltip(line3, line4)
	local pattern = self:GetOffhandPattern()
	if not pattern then
		return false
	end
	return line3 == pattern or line4 == pattern
end

function InventoryConfig:IsOffhandItem(equipLoc, line3, line4)
	if equipLoc == "INVTYPE_HOLDABLE" then
		return true
	end
	return self:IsOffhandTooltip(line3, line4)
end
