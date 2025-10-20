------------------------------------------------------------------------------------------------------
-- Necrosis Inventory & Shard Logic
------------------------------------------------------------------------------------------------------

local floor = math.floor
local wipe_table = NecrosisUtils.WipeTable
local GetTime = GetTime
local GetItemInfo = GetItemInfo
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local InventoryConfig = NecrosisInventoryConfig

local getState = Necrosis.GetStateSlice
local getInventory = Necrosis.GetInventorySlice

local SoulshardState = getState("soulshards")
local ComponentState = getState("components")
local CombatState = getState("combat")
local MountState = getState("mount")
local MessageState = getState("messages")
local BagQueueState = getState("bags")
local DemonState = getState("demon")
local SoulstoneState_Internal = getState("soulstone")
local StoneInventory = getInventory("stones")
local BagIsSoulPouch = getInventory("bagIsSoulPouch")
local LastCast = Necrosis.GetLastCast()
local Timers = Necrosis.Timers
local Spells = Necrosis.Spells
local Loc = Necrosis.Loc
local SpellIndex = Spells.Index
local ShardDial = NecrosisShardDial

local SOUL_SHARD_ITEM_ID = 6265
local MAX_SHARD_COUNT = 32
local CachedManaPetState = { "3", "3", "3", "3", "3", "3" }

local PET_BUTTON_CONFIG = {
	{ buttonName = "NecrosisPetMenu2", texture = "Imp" },
	{ buttonName = "NecrosisPetMenu3", texture = "Voidwalker" },
	{ buttonName = "NecrosisPetMenu4", texture = "Succubus" },
	{ buttonName = "NecrosisPetMenu5", texture = "Felhunter" },
	{ buttonName = "NecrosisPetMenu6", texture = "Infernal" },
	{ buttonName = "NecrosisPetMenu7", texture = "Doomguard" },
}

local MENU_BUTTON_DEFNS = {
	buff = {
		{
			buttonName = "NecrosisDemonArmorButton",
			texture = "ArmureDemo",
			spellIndex = SpellIndex.DEMON_ARMOR,
			fallbackSpellIndex = SpellIndex.DEMON_SKIN,
			requiresShard = false,
			requiresPet = false,
		},
		{
			buttonName = "NecrosisUnendingBreathButton",
			texture = "Aqua",
			spellIndex = SpellIndex.UNENDING_BREATH,
		},
		{
			buttonName = "NecrosisDetectInvisibilityButton",
			texture = "Invisible",
			spellIndex = SpellIndex.DETECT_INVISIBILITY,
		},
		{
			buttonName = "NecrosisEyeOfKilroggButton",
			texture = "Kilrogg",
			spellIndex = SpellIndex.EYE_OF_KILROGG,
		},
		{
			buttonName = "NecrosisSoulLinkButton",
			texture = "Lien",
			spellIndex = SpellIndex.SOUL_LINK,
		},
		{
			buttonName = "NecrosisShadowWardButton",
			texture = "ShadowWard",
			spellIndex = SpellIndex.SHADOW_WARD,
			trackedCooldown = true,
		},
		{
			buttonName = "NecrosisBanishButton",
			texture = "Banish",
			spellIndex = SpellIndex.BANISH,
		},
	},
	curse = {
		{
			buttonName = "NecrosisAmplifyCurseButton",
			texture = "Amplify",
			spellIndex = SpellIndex.AMPLIFY_CURSE,
			trackedCooldown = true,
			checkMana = false,
			skipWhenActiveBuff = true,
		},
		{
			buttonName = "NecrosisCurseOfWeaknessButton",
			texture = "Weakness",
			spellIndex = SpellIndex.CURSE_OF_WEAKNESS,
		},
		{
			buttonName = "NecrosisCurseOfAgonyButton",
			texture = "Agony",
			spellIndex = SpellIndex.CURSE_OF_AGONY,
		},
		{
			buttonName = "NecrosisCurseOfRecklessnessButton",
			texture = "Reckless",
			spellIndex = SpellIndex.CURSE_OF_RECKLESSNESS,
		},
		{
			buttonName = "NecrosisCurseOfTonguesButton",
			texture = "Tongues",
			spellIndex = SpellIndex.CURSE_OF_TONGUES,
		},
		{
			buttonName = "NecrosisCurseOfExhaustionButton",
			texture = "Exhaust",
			spellIndex = SpellIndex.CURSE_OF_EXHAUSTION,
		},
		{
			buttonName = "NecrosisCurseOfTheElementsButton",
			texture = "Elements",
			spellIndex = SpellIndex.CURSE_OF_THE_ELEMENTS,
		},
		{
			buttonName = "NecrosisCurseOfShadowButton",
			texture = "Shadow",
			spellIndex = SpellIndex.CURSE_OF_SHADOW,
		},
		{
			buttonName = "NecrosisCurseOfDoomButton",
			texture = "Doom",
			spellIndex = SpellIndex.CURSE_OF_DOOM,
		},
	},
}

local function syncShardDial()
	if type(ShardDial) ~= "table" then
		return nil
	end
	local sync = ShardDial.SyncConfiguredTheme
	if type(sync) ~= "function" then
		return nil
	end
	return sync()
end

local function applyShardDialCount(dial)
	if not dial then
		return
	end

	local dialCount = SoulshardState and SoulshardState.count
	if type(dialCount) ~= "number" then
		dialCount = dial.baseCount or 0
	end

	if dialCount < 0 then
		dialCount = 0
	elseif dialCount > MAX_SHARD_COUNT then
		dialCount = MAX_SHARD_COUNT
	end

	if NecrosisConfig and NecrosisConfig.Circle == 2 then
		local hasOverride = type(dial.IsOverrideActive) == "function" and dial:IsOverrideActive()
		if not hasOverride then
			dialCount = 0
		end
	end

	dial:SetShardCount(dialCount)
end

local function refreshShardDialDisplay()
	local dial = syncShardDial()
	if dial then
		applyShardDialCount(dial)
	end
end

Necrosis_UpdateShardDialDisplay = refreshShardDialDisplay

function Necrosis_UpdateShardDialTheme()
	local dial = syncShardDial()
	if dial then
		applyShardDialCount(dial)
	end
end

local function spellHasId(index)
	return Spells:HasID(index)
end

local function spellId(index)
	return Spells:GetID(index)
end

local function spellName(index)
	return Spells:GetName(index)
end

local function spellMana(index)
	return Spells:GetMana(index, 0)
end

local function spellType(index)
	return Spells:GetType(index)
end

local function getActivePetIndex(currentType)
	if type(NECROSIS_PET_LOCAL_NAME) ~= "table" or not currentType then
		return nil
	end
	for index = 1, table.getn(PET_BUTTON_CONFIG) do
		if currentType == NECROSIS_PET_LOCAL_NAME[index] then
			return index
		end
	end
	return nil
end

local function applyPetMenuTextures(activeIndex, manaVariants)
	for index = 1, table.getn(PET_BUTTON_CONFIG) do
		local config = PET_BUTTON_CONFIG[index]
		local button = _G[config.buttonName]
		if button then
			local variant = manaVariants[index] or "3"
			if activeIndex and index == activeIndex then
				variant = 2
			end
			Necrosis_SetButtonTexture(button, config.texture, variant)
		end
	end
end

local function setMenuButtonState(buttonName, texture, enabled, activeVariant)
	local button = _G[buttonName]
	if not button then
		return
	end
	local variant = enabled and (activeVariant or 3) or 1
	Necrosis_SetButtonTexture(button, texture, variant)
end

local function resolveMenuSpellIndex(def)
	local index = def.spellIndex
	if index and not spellHasId(index) and def.fallbackSpellIndex then
		index = def.fallbackSpellIndex
	end
	if index and not spellHasId(index) then
		return nil
	end
	return index
end

local function isSpellOnCooldownByIndex(index)
	local id = spellId(index)
	if not id then
		return false
	end
	local start, duration = GetSpellCooldown(id, "spell")
	return start > 0 and duration > 0
end

local function updateMenuButtons(definitions, mana)
	for idx = 1, table.getn(definitions) do
		local def = definitions[idx]
		local index = resolveMenuSpellIndex(def)
		if index then
			if def.skipWhenActiveBuff and AmplifyUp then
				-- Keep the prior texture while Amplify Curse is active.
			else
				local enabled = true
				if def.requiresShard and SoulshardState.count == 0 then
					enabled = false
				end
				if def.requiresPet and not UnitExists("Pet") then
					enabled = false
				end
				if def.trackedCooldown and isSpellOnCooldownByIndex(index) then
					enabled = false
				end
				if (def.checkMana ~= false) and mana ~= nil then
					local cost = spellMana(index)
					if cost and cost > mana then
						enabled = false
					end
				end
				setMenuButtonState(def.buttonName, def.texture, enabled, def.enabledVariant)
			end
		end
	end
end

StoneIDInSpellTable = StoneIDInSpellTable or { 0, 0, 0, 0, 0, 0, 0 }
StonePos = StonePos
	or {
		Healthstone = 1,
		Spellstone = 2,
		Soulstone = 3,
		BuffMenu = 4,
		Mount = 5,
		PetMenu = 6,
		CurseMenu = 7,
		StoneMenu = 8,
	}
SoulstoneUsedOnTarget = SoulstoneUsedOnTarget or false

local function ensureShardDisplay()
	local display = SoulshardState.shardDisplay
	if not display then
		display = { text = "" }
		SoulshardState.shardDisplay = display
	end
	if display.timerActive == nil then
		display.timerActive = false
	end
	return display
end

local function applyShardCountText(display, text)
	local normalized = text or ""
	if display.text == normalized then
		return
	end
	display.text = normalized
	if NecrosisShardCount then
		NecrosisShardCount:SetText(normalized)
	end
end

function Necrosis_ClearShardCountDisplay()
	local display = ensureShardDisplay()
	display.countType = nil
	display.primary = nil
	display.secondary = nil
	display.timerMinutes = nil
	display.timerSeconds = nil
	display.timerControlled = false
	display.timerActive = false
	applyShardCountText(display, "")
end

function Necrosis_UpdateShardCountNumeric(countType, primary, secondary)
	local display = ensureShardDisplay()
	if display.countType == countType and display.primary == primary and display.secondary == secondary then
		return
	end
	display.countType = countType
	display.primary = primary
	display.secondary = secondary
	display.timerControlled = false
	display.timerMinutes = nil
	display.timerSeconds = nil
	display.timerActive = false

	local text = ""
	if countType == 1 then
		local value = primary or 0
		if value < 10 then
			text = "0" .. value
		else
			text = tostring(value)
		end
	elseif countType == 2 then
		text = tostring(primary or 0) .. " / " .. tostring(secondary or 0)
	end
	applyShardCountText(display, text)
	if countType == 1 then
		local dial = type(ShardDial) == "table" and ShardDial.Ensure and ShardDial.Ensure()
		if dial then
			local dialCount = primary or 0
			if NecrosisConfig and NecrosisConfig.Circle == 2 then
				dialCount = 0
			end
			dial:SetShardCount(dialCount)
		end
	end
end

function Necrosis_UpdateShardCountTimer(minutes, seconds)
	local display = ensureShardDisplay()
	local minuteValue = minutes or 0
	local secondValue = seconds or 0
	if display.timerControlled and display.timerMinutes == minuteValue and display.timerSeconds == secondValue then
		return
	end
	display.countType = 3
	display.timerControlled = true
	display.timerMinutes = minuteValue
	display.timerSeconds = secondValue
	display.primary = nil
	display.secondary = nil
	display.timerActive = true

	local text
	if minuteValue > 0 then
		text = minuteValue .. " m"
	else
		text = tostring(secondValue)
	end
	applyShardCountText(display, text)
end

function Necrosis_ClearShardCountTimer()
	local display = ensureShardDisplay()
	display.timerActive = false

	local countType = NecrosisConfig and NecrosisConfig.CountType
	if countType == 1 then
		Necrosis_UpdateShardCountNumeric(1, SoulshardState.count or 0, nil)
		return
	elseif countType == 2 then
		Necrosis_UpdateShardCountNumeric(2, ComponentState.infernal or 0, ComponentState.demonic or 0)
		return
	elseif countType ~= 3 then
		Necrosis_ClearShardCountDisplay()
		return
	end

	display.countType = 3
	display.timerControlled = true
	display.timerMinutes = nil
	display.timerSeconds = nil
	display.primary = nil
	display.secondary = nil
	applyShardCountText(display, "")
end

local function Necrosis_GetBagState()
	if type(BagQueueState) ~= "table" then
		BagQueueState = getState("bags")
	end
	if BagQueueState.scanQueued == nil then
		BagQueueState.scanQueued = false
	end
	if BagQueueState.nextScanTime == nil then
		BagQueueState.nextScanTime = 0
	end
	if BagQueueState.processing == nil then
		BagQueueState.processing = false
	end
	BagQueueState.pending = nil
	BagQueueState.pendingSort = nil
	BagQueueState.snapshot = BagQueueState.snapshot or {}
	BagQueueState.dirtyBags = BagQueueState.dirtyBags or {}
	return BagQueueState
end

local function GetSlotItemID(container, slot)
	local itemLink = GetContainerItemLink(container, slot)
	if not itemLink then
		return nil
	end
	local _, _, itemId = string.find(itemLink, "item:(%d+)")
	if itemId then
		return tonumber(itemId, 10)
	end
	return nil
end

local function IsSoulShardSlot(container, slot)
	if not slot then
		return false
	end
	return GetSlotItemID(container, slot) == SOUL_SHARD_ITEM_ID
end

function Necrosis_FlagBagDirty(bag)
	local state = Necrosis_GetBagState()
	local dirty = state.dirtyBags
	if not dirty then
		dirty = {}
		state.dirtyBags = dirty
	end
	if not bag or bag < 0 then
		for index = 0, 4 do
			dirty[index] = true
		end
	else
		dirty[bag] = true
	end
end

local function GetSlotItemID(container, slot)
	local itemLink = GetContainerItemLink(container, slot)
	if not itemLink then
		return nil
	end
	local startIndex, endIndex, itemId = string.find(itemLink, "item:(%d+)")
	if startIndex and itemId then
		return tonumber(itemId, 10)
	end
	return nil
end

local function IsSoulShardSlot(container, slot)
	if not slot then
		return false
	end
	return GetSlotItemID(container, slot) == SOUL_SHARD_ITEM_ID
end

local function Necrosis_ProcessBagScanQueue(curTime)
	local state = Necrosis_GetBagState()
	if state.processing then
		return
	end
	if not state.scanQueued then
		return
	end
	curTime = curTime or GetTime()
	local nextScan = state.nextScanTime or 0
	if nextScan > 0 and curTime < nextScan then
		return
	end
	state.scanQueued = false
	state.nextScanTime = 0
	state.processing = true

	local handledSort = false
	if SoulshardState.pendingSortCheck then
		SoulshardState.pendingSortCheck = false
		Necrosis_SoulshardSwitch("CHECK")
		handledSort = true
	end

	if not handledSort then
		Necrosis_BagExplore()
	end

	state.processing = false
	if state.scanQueued then
		Necrosis_ProcessBagScanQueue(curTime)
	end
end

local function Necrosis_GetTooltipLines(container, slot)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetBagItem(container, slot)
	local line1 = NecrosisTooltipTextLeft1 and NecrosisTooltipTextLeft1:GetText()
	local line3 = NecrosisTooltipTextLeft3 and NecrosisTooltipTextLeft3:GetText()
	local line4 = NecrosisTooltipTextLeft4 and NecrosisTooltipTextLeft4:GetText()
	return line1, line3, line4
end

local function Necrosis_GetBagSlotInfo(container, slot)
	local texture, itemCount = GetContainerItemInfo(container, slot)
	if not texture then
		return nil, 0, nil
	end
	if not itemCount or itemCount == 0 then
		itemCount = 1
	end

	local itemLink = GetContainerItemLink(container, slot)
	local itemName
	local equipLoc
	if itemLink then
		local infoName, _, _, _, _, _, _, _, infoEquipLoc = GetItemInfo(itemLink)
		if infoName then
			itemName = infoName
		else
			local nameStart, nameEnd = string.find(itemLink, "%b[]")
			if nameStart and nameEnd then
				itemName = string.sub(itemLink, nameStart + 1, nameEnd - 1)
			end
		end
		equipLoc = infoEquipLoc
	end

	if not itemName or not equipLoc then
		local tooltipName, line3, line4 = Necrosis_GetTooltipLines(container, slot)
		itemName = itemName or tooltipName
		if not equipLoc and InventoryConfig:IsOffhandTooltip(line3, line4) then
			equipLoc = "INVTYPE_HOLDABLE"
		end
	end

	return itemName, itemCount, equipLoc
end

local function Necrosis_IsOffhandItem(equipLoc, container, slot)
	if equipLoc == "INVTYPE_HOLDABLE" then
		return true
	end
	local _, line3, line4 = Necrosis_GetTooltipLines(container, slot)
	return InventoryConfig:IsOffhandItem(equipLoc, line3, line4)
end

function Necrosis_RequestBagScan(delay, forceFull)
	local state = Necrosis_GetBagState()
	delay = delay or 0
	if delay < 0 then
		delay = 0
	end
	local now = GetTime()
	local targetTime = 0
	if delay > 0 then
		targetTime = now + delay
	end
	if not state.scanQueued then
		state.nextScanTime = targetTime
	else
		if targetTime == 0 or state.nextScanTime == 0 or targetTime < state.nextScanTime then
			state.nextScanTime = targetTime
		end
	end
	state.scanQueued = true
	if forceFull then
		Necrosis_FlagBagDirty(-1)
	end
	if state.processing then
		return
	end
	if targetTime == 0 then
		Necrosis_ProcessBagScanQueue(now)
	end
end

InventoryConfig:BuildStoneNamePatterns()
InventoryConfig:BuildOffhandPattern()

function Necrosis_RecordStoneInventory(stoneKey, container, slot)
	local data = StoneInventory[stoneKey]
	if not data then
		return
	end
	data.onHand = true
	data.location = { container, slot }
end

function Necrosis_SoulshardSetup()
	SoulshardState.nextSlotIndex = 1
	for key in pairs(SoulshardState.slots) do
		SoulshardState.slots[key] = nil
	end
	local slotCount = GetContainerNumSlots(NecrosisConfig.SoulshardContainer)
	for slot = 1, slotCount, 1 do
		SoulshardState.slots[slot] = nil
	end
end

function Necrosis_BagExplore(forceFull)
	local state = Necrosis_GetBagState()
	state.scanQueued = false
	state.nextScanTime = 0
	state.snapshot = state.snapshot or {}
	state.dirtyBags = state.dirtyBags or {}

	if forceFull then
		Necrosis_FlagBagDirty(-1)
	end

	local dirty = state.dirtyBags
	local snapshot = state.snapshot
	local sawIncompleteInfo = false

	for bag in pairs(dirty) do
		local slotCount = GetContainerNumSlots(bag)
		snapshot[bag] = snapshot[bag] or {}
		local bagSnapshot = snapshot[bag]
		for slot = 1, slotCount do
			local itemName, itemCount, equipLoc = Necrosis_GetBagSlotInfo(bag, slot)
			local itemId = GetSlotItemID(bag, slot)
			if itemName then
				bagSnapshot[slot] = bagSnapshot[slot] or {}
				local entry = bagSnapshot[slot]
				entry.id = itemId
				entry.name = itemName
				entry.count = itemCount or 1
				entry.equipLoc = equipLoc
			else
				sawIncompleteInfo = true
				bagSnapshot[slot] = nil
			end
		end
		if bagSnapshot then
			for slot = slotCount + 1, table.getn(bagSnapshot) do
				bagSnapshot[slot] = nil
			end
		end
	end
	for bag in pairs(dirty) do
		dirty[bag] = nil
	end

	SoulshardState.container = NecrosisConfig.SoulshardContainer
	local shardContainer = SoulshardState.container

	SoulshardState.count = 0
	SoulshardState.nextSlotIndex = 1
	for key in pairs(SoulshardState.slots) do
		SoulshardState.slots[key] = nil
	end

	ComponentState.infernal = 0
	ComponentState.demonic = 0

	for key, data in pairs(StoneInventory) do
		data.onHand = false
		data.location[1], data.location[2] = nil, nil
		if data.mode then
			data.mode = 1
		end
	end

	local stoneKeys = InventoryConfig:GetStoneKeys()
	local stonePatterns = InventoryConfig:EnsureStoneNamePatterns()

	for bag, bagSnapshot in pairs(snapshot) do
		for slot, entry in pairs(bagSnapshot) do
			if entry.id == SOUL_SHARD_ITEM_ID then
				SoulshardState.count = SoulshardState.count + (entry.count or 1)
				if bag == shardContainer then
					SoulshardState.slots[SoulshardState.nextSlotIndex] = slot
					SoulshardState.nextSlotIndex = SoulshardState.nextSlotIndex + 1
				end
			end
			if entry.name == NECROSIS_ITEM.InfernalStone then
				ComponentState.infernal = ComponentState.infernal + (entry.count or 1)
			elseif entry.name == NECROSIS_ITEM.DemonicStone then
				ComponentState.demonic = ComponentState.demonic + (entry.count or 1)
			end
			local recorded = false
			for _, stoneKey in ipairs(stoneKeys) do
				local pattern = stonePatterns[stoneKey]
				if pattern and entry.name and string.find(entry.name, pattern, 1, true) then
					Necrosis_RecordStoneInventory(stoneKey, bag, slot)
					recorded = true
					break
				end
			end
			if not recorded and Necrosis_IsOffhandItem(entry.equipLoc, bag, slot) then
				Necrosis_RecordStoneInventory("Itemswitch", bag, slot)
			end
		end
	end

	if sawIncompleteInfo then
		Necrosis_RequestBagScan(0.2, true)
	end

	refreshShardDialDisplay()

	if NecrosisConfig.ShowCount then
		local countType = NecrosisConfig.CountType
		if countType == 1 then
			Necrosis_UpdateShardCountNumeric(1, SoulshardState.count or 0, nil)
		elseif countType == 2 then
			Necrosis_UpdateShardCountNumeric(2, ComponentState.infernal or 0, ComponentState.demonic or 0)
		elseif countType == 3 then
			local display = ensureShardDisplay()
			if not display.timerActive then
				Necrosis_ClearShardCountTimer()
			end
		else
			Necrosis_ClearShardCountDisplay()
		end
	else
		Necrosis_ClearShardCountDisplay()
	end

	Necrosis_UpdateIcons()

	if type(Necrosis_EnsureSoulstoneBuffTimer) == "function" then
		Necrosis_EnsureSoulstoneBuffTimer()
	end

	if
		SoulshardState.count == GetContainerNumSlots(NecrosisConfig.SoulshardContainer)
		and NecrosisConfig.SoulshardSort
	then
		local message = Loc:GetMessage("Warning", "FullPouch")
		if message then
			Necrosis_Msg(message, "USER")
		end
	end
end

function Necrosis_UpdateSoulShardSorting(elapsed)
	SoulshardState.tidyAccumulator = SoulshardState.tidyAccumulator + elapsed
	if SoulshardState.tidyAccumulator >= 1 then
		local tidyOvershoot = floor(SoulshardState.tidyAccumulator)
		SoulshardState.tidyAccumulator = SoulshardState.tidyAccumulator - tidyOvershoot
		if SoulshardState.pendingMoves > 0 then
			Necrosis_SoulshardSwitch("MOVE")
		end
	end
end

function Necrosis_ProcessBagUpdates(curTime)
	local state = Necrosis_GetBagState()
	if SoulshardState.pendingSortCheck and not state.scanQueued then
		Necrosis_RequestBagScan(0)
	end
	if not state.scanQueued or state.processing then
		return
	end
	local nextScan = state.nextScanTime or 0
	if nextScan > 0 then
		curTime = curTime or GetTime()
		if curTime < nextScan then
			return
		end
	end
	Necrosis_ProcessBagScanQueue(curTime)
end

function Necrosis_HandleShardCount()
	if NecrosisConfig.CountType == 3 then
		local display = ensureShardDisplay()
		if not display.timerActive then
			Necrosis_ClearShardCountTimer()
		end
	end
end

function Necrosis_SoulshardSwitch(action)
	if action == "CHECK" then
		for container = 0, 4, 1 do
			BagIsSoulPouch[container + 1] = false
			local bagName = GetBagName(container)
			if bagName then
				for index = 1, 3, 1 do
					if bagName == NECROSIS_ITEM.SoulPouch[index] then
						BagIsSoulPouch[container + 1] = true
						break
					end
				end
			end
		end
		SoulshardState.pendingMoves = 0
		SoulshardState.nextSlotIndex = 1
		for key in pairs(SoulshardState.slots) do
			SoulshardState.slots[key] = nil
		end
		for bag = 0, 4, 1 do
			if BagIsSoulPouch[bag + 1] then
				for slot = 1, GetContainerNumSlots(bag), 1 do
					if IsSoulShardSlot(bag, slot) then
						SoulshardState.slots[SoulshardState.nextSlotIndex] = slot
						SoulshardState.nextSlotIndex = SoulshardState.nextSlotIndex + 1
					end
				end
			end
		end
		if SoulshardState.nextSlotIndex > 1 then
			for bag = 0, 4, 1 do
				if not BagIsSoulPouch[bag + 1] then
					for slot = 1, GetContainerNumSlots(bag), 1 do
						if IsSoulShardSlot(bag, slot) then
							SoulshardState.pendingMoves = SoulshardState.pendingMoves + 1
							PickupContainerItem(bag, slot)
							PickupContainerItem(
								NecrosisConfig.SoulshardContainer,
								SoulshardState.slots[SoulshardState.pendingMoves]
							)
							if CursorHasItem() then
								if bag == 0 then
									PutItemInBackpack()
								else
									PutItemInBag(19 + bag)
								end
							end
						end
					end
				end
			end
		end
	elseif action == "MOVE" then
		SoulshardState.pendingMoves = SoulshardState.pendingMoves - 1
		if SoulshardState.pendingMoves <= 0 then
			SoulshardState.pendingMoves = 0
			Necrosis_FlagBagDirty(-1)
			Necrosis_RequestBagScan(0, true)
			return
		end
	end
	if action == "CHECK" then
		Necrosis_FlagBagDirty(-1)
		Necrosis_RequestBagScan(0, true)
	end
end
function Necrosis_FindSlot(shardIndex, shardSlot)
	local full = true
	for slot = 1, GetContainerNumSlots(NecrosisConfig.SoulshardContainer), 1 do
		if not IsSoulShardSlot(NecrosisConfig.SoulshardContainer, slot) then
			PickupContainerItem(shardIndex, shardSlot)
			PickupContainerItem(NecrosisConfig.SoulshardContainer, slot)
			SoulshardState.slots[SoulshardState.nextSlotIndex] = slot
			SoulshardState.nextSlotIndex = SoulshardState.nextSlotIndex + 1
			if CursorHasItem() then
				if shardIndex == 0 then
					PutItemInBackpack()
				else
					PutItemInBag(19 + shardIndex)
				end
			end
			full = false
			break
		end
	end
	if full and NecrosisConfig.SoulshardDestroy then
		PickupContainerItem(shardIndex, shardSlot)
		if CursorHasItem() then
			DeleteCursorItem()
		end
	end
end

function Necrosis_UpdateIcons()
	if not LastCast or type(LastCast) ~= "table" then
		return
	end
	LastCast.Stone = LastCast.Stone or { id = 0, click = "LeftButton" }
	local mana = UnitMana("player")

	if LastCast.Stone.id == 0 then
		if StoneInventory.Felstone.onHand then
			LastCast.Stone.id = 1
		elseif StoneInventory.Wrathstone.onHand then
			LastCast.Stone.id = 2
		elseif StoneInventory.Voidstone.onHand then
			LastCast.Stone.id = 3
		elseif StoneInventory.Firestone.onHand then
			LastCast.Stone.id = 4
		end
	end

	if LastCast.Stone.id == 1 and StoneInventory.Felstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Felstone", 2)
	elseif LastCast.Stone.id == 2 and StoneInventory.Wrathstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Wrathstone", 2)
	elseif LastCast.Stone.id == 3 and StoneInventory.Voidstone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "Voidstone", 2)
	elseif LastCast.Stone.id == 4 and StoneInventory.Firestone.onHand then
		Necrosis_SetButtonTexture(NecrosisStoneMenuButton, "FirestoneButton", 2)
	else
		Necrosis_SetNormalTextureIfDifferent(
			NecrosisStoneMenuButton,
			"Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-01"
		)
	end

	-- Soulstone
	-----------------------------------------------

	-- Determine whether a Soulstone was used by checking timers
	local SoulstoneInUse = false
	local soulstoneTimerName = spellName(SpellIndex.SOULSTONE_RESURRECTION)
	if soulstoneTimerName then
		local timer = Timers:FindTimerByName(soulstoneTimerName)
		if timer and timer.TimeMax and timer.TimeMax > 0 then
			SoulstoneInUse = true
		end
	end

	-- If the stone was not used and none are in the inventory -> mode 1
	if not (StoneInventory.Soulstone.onHand or SoulstoneInUse) then
		StoneInventory.Soulstone.mode = 1
		SoulstoneWaiting = false
		SoulstoneCooldown = false
	end

	-- If the stone was not used and one is in the inventory
	if StoneInventory.Soulstone.onHand and not SoulstoneInUse then
		-- If the stone in the inventory still has a timer and we just relogged --> mode 4
		local start, duration =
			GetContainerItemCooldown(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
		if NecrosisRL and start > 0 and duration > 0 then
			local timeRemaining = floor(duration - GetTime() + start)
			if timeRemaining > 0 then
				local expiry = floor(start + duration)
				if Timers:HasService() then
					Timers:EnsureSpellIndexTimer(
						SpellIndex.SOULSTONE_RESURRECTION,
						"???",
						timeRemaining,
						spellType(SpellIndex.SOULSTONE_RESURRECTION),
						timeRemaining,
						expiry
					)
				end
			end
			StoneInventory.Soulstone.mode = 4
			NecrosisRL = false
			SoulstoneWaiting = false
			SoulstoneCooldown = true
		-- If the stone has no timer or we didn't just relog --> mode 2
		else
			StoneInventory.Soulstone.mode = 2
			NecrosisRL = false
			SoulstoneWaiting = false
			SoulstoneCooldown = false
		end
	end

	-- If the stone was consumed and none remain in the inventory --> mode 3
	if (not StoneInventory.Soulstone.onHand) and SoulstoneInUse then
		StoneInventory.Soulstone.mode = 3
		SoulstoneWaiting = true
		-- If the stone was just applied, announce it to the raid
		if SoulstoneState_Internal.pendingAdvice and NECROSIS_SOULSTONE_ALERT_MESSAGE then
			local alertMessages = NECROSIS_SOULSTONE_ALERT_MESSAGE
			local alertCount = table.getn(alertMessages)
			if alertCount > 0 then
				local tempnum = random(1, alertCount)
				if alertCount >= 2 then
					while tempnum == MessageState.rez do
						tempnum = random(1, alertCount)
					end
				end
				MessageState.rez = tempnum
				local lines = alertMessages[tempnum]
				local lineCount = table.getn(lines)
				for i = 1, lineCount, 1 do
					Necrosis_Msg(Necrosis_MsgReplace(lines[i], SoulstoneState_Internal.target), "WORLD")
				end
				SoulstoneState_Internal.pendingAdvice = false
			end
		end
	end

	-- If the stone was consumed but another is in the inventory
	if StoneInventory.Soulstone.onHand and SoulstoneInUse then
		SoulstoneState_Internal.pendingAdvice = false
		if not (SoulstoneWaiting or SoulstoneCooldown) then
			if Timers:HasService() then
				Timers:RemoveTimerByName(soulstoneTimerName)
			end
			StoneInventory.Soulstone.mode = 2
		else
			SoulstoneWaiting = false
			SoulstoneCooldown = true
			StoneInventory.Soulstone.mode = 4
		end
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisSoulstoneButton, "SoulstoneButton", StoneInventory.Soulstone.mode)

	-- Pierre de sort
	-----------------------------------------------

	if StoneInventory.Spellstone.onHand then
		StoneInventory.Spellstone.mode = 2
	else
		StoneInventory.Spellstone.mode = 1
	end

	Necrosis_SetButtonTexture(NecrosisSpellstoneButton, "SpellstoneButton", StoneInventory.Spellstone.mode)

	-- Pierre de vie
	-----------------------------------------------

	-- Mode "j'en ai une" (2) / "j'en ai pas" (1)
	if StoneInventory.Healthstone.onHand then
		StoneInventory.Healthstone.mode = 2
	else
		StoneInventory.Healthstone.mode = 1
	end

	-- Display the icon that matches the current mode
	Necrosis_SetButtonTexture(NecrosisHealthstoneButton, "HealthstoneButton", StoneInventory.Healthstone.mode)

	-- Demon button
	-----------------------------------------------
	local ManaPet = CachedManaPetState
	for index = 1, 6 do
		ManaPet[index] = "3"
	end

	-- Si cooldown de domination corrompue on grise
	local dominationId = spellId(15)
	if dominationId and not DominationUp then
		local start, duration = GetSpellCooldown(dominationId, "spell")
		if start > 0 and duration > 0 then
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 1)
		else
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
	end

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if spellHasId(SpellIndex.SUMMON_IMP) then
			if spellMana(SpellIndex.SUMMON_IMP) > mana then
				for i = 1, 6, 1 do
					ManaPet[i] = "1"
				end
			elseif spellHasId(SpellIndex.SUMMON_VOIDWALKER) then
				if spellMana(SpellIndex.SUMMON_VOIDWALKER) > mana then
					for i = 2, 6, 1 do
						ManaPet[i] = "1"
					end
				elseif spellHasId(SpellIndex.INFERNO) then
					if spellMana(SpellIndex.INFERNO) > mana then
						for i = 5, 6, 1 do
							ManaPet[i] = "1"
						end
					elseif spellHasId(SpellIndex.RITUAL_OF_DOOM) then
						if spellMana(SpellIndex.RITUAL_OF_DOOM) > mana then
							ManaPet[6] = "1"
						end
					end
				end
			end
		end
	end

	-- Grey out the button when no stone is available for the summon
	if SoulshardState.count == 0 then
		for i = 2, 4, 1 do
			ManaPet[i] = "1"
		end
	end
	if ComponentState.infernal == 0 then
		ManaPet[5] = "1"
	end
	if ComponentState.demonic == 0 then
		ManaPet[6] = "1"
	end

	-- Handle cooldown-driven button states prior to mana checks.
	if spellHasId(SpellIndex.SHADOW_WARD) then
		local available = not isSpellOnCooldownByIndex(SpellIndex.SHADOW_WARD)
		setMenuButtonState("NecrosisShadowWardButton", "ShadowWard", available)
	end

	if spellHasId(SpellIndex.AMPLIFY_CURSE) and not AmplifyUp then
		local available = not isSpellOnCooldownByIndex(SpellIndex.AMPLIFY_CURSE)
		setMenuButtonState("NecrosisAmplifyCurseButton", "Amplify", available)
	end

	-- Apply textures to the pet buttons
	local activePetIndex = getActivePetIndex(DemonState.type)
	applyPetMenuTextures(activePetIndex, ManaPet)

	-- Buff button
	-----------------------------------------------

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if MountState.available and not MountState.active then
			if spellHasId(SpellIndex.SUMMON_DREADSTEED) then
				if spellMana(SpellIndex.SUMMON_DREADSTEED) > mana or CombatState.inCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			else
				if spellMana(SpellIndex.SUMMON_FELSTEED) > mana or CombatState.inCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			end
		end
		if spellHasId(SpellIndex.ENSLAVE_DEMON_EFFECT) then
			if spellMana(SpellIndex.ENSLAVE_DEMON_EFFECT) > mana or SoulshardState.count == 0 then
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 1)
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 3)
			end
		end
		updateMenuButtons(MENU_BUTTON_DEFNS.buff, mana)
		if spellHasId(SpellIndex.RITUAL_OF_SUMMONING) then
			if spellMana(SpellIndex.RITUAL_OF_SUMMONING) > mana or SoulshardState.count == 0 then
				Necrosis_SetNormalTextureIfDifferent(
					NecrosisRitualOfSummoningButton,
					"Interface\\AddOns\\Necrosis\\UI\\TPButton-05"
				)
			else
				Necrosis_SetNormalTextureIfDifferent(
					NecrosisRitualOfSummoningButton,
					"Interface\\AddOns\\Necrosis\\UI\\TPButton-01"
				)
			end
		end
		if spellHasId(SpellIndex.DEMONIC_SACRIFICE) then
			if not UnitExists("Pet") then
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 1)
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu9, "Sacrifice", 3)
			end
		end
	end

	-- Curse button
	-----------------------------------------------

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		updateMenuButtons(MENU_BUTTON_DEFNS.curse, mana)
	end

	-- Timer button
	-----------------------------------------------
	if StoneInventory.Hearthstone.location[1] then
		local start, duration, enable =
			GetContainerItemCooldown(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		if duration > 20 and start > 0 then
			Necrosis_SetNormalTextureIfDifferent(
				NecrosisSpellTimerButton,
				"Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Cooldown"
			)
		else
			Necrosis_SetNormalTextureIfDifferent(
				NecrosisSpellTimerButton,
				"Interface\\AddOns\\Necrosis\\UI\\SpellTimerButton-Normal"
			)
		end
	end
end
