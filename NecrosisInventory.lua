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

local function getState(key)
	return Necrosis.GetStateSlice(key)
end

local function getInventory(key)
	return Necrosis.GetInventorySlice(key)
end

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

local SOUL_SHARD_ITEM_ID = 6265
local CachedManaPetState = { "3", "3", "3", "3", "3", "3" }

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
	ComponentState.demoniac = 0

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
			elseif entry.name == NECROSIS_ITEM.DemoniacStone then
				ComponentState.demoniac = ComponentState.demoniac + (entry.count or 1)
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

	local shardIndex = SoulshardState.count
	if shardIndex > 32 then
		shardIndex = 32
	end
	if NecrosisConfig.Circle == 1 then
		Necrosis_SetNormalTextureIfDifferent(
			NecrosisButton,
			"Interface\\AddOns\\Necrosis\\UI\\" .. NecrosisConfig.NecrosisColor .. "\\Shard" .. shardIndex
		)
	elseif StoneInventory.Soulstone.mode == 1 or StoneInventory.Soulstone.mode == 2 then
		Necrosis_SetNormalTextureIfDifferent(
			NecrosisButton,
			"Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard" .. shardIndex
		)
	end

	if NecrosisConfig.ShowCount then
		local countType = NecrosisConfig.CountType
		if countType == 1 then
			Necrosis_UpdateShardCountNumeric(1, SoulshardState.count or 0, nil)
		elseif countType == 2 then
			Necrosis_UpdateShardCountNumeric(2, ComponentState.infernal or 0, ComponentState.demoniac or 0)
		elseif countType == 3 then
			Necrosis_ClearShardCountTimer()
		else
			Necrosis_ClearShardCountDisplay()
		end
	else
		Necrosis_ClearShardCountDisplay()
	end

	Necrosis_UpdateIcons()

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
		Necrosis_ClearShardCountTimer()
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

	-- Si cooldown de gardien de l'ombre on grise
	local shadowWardId = spellId(43)
	if shadowWardId then
		local start2, duration2 = GetSpellCooldown(shadowWardId, "spell")
		if start2 > 0 and duration2 > 0 then
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
		else
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
		end
	end

	-- Gray out the button while Amplify Curse is on cooldown
	local amplifyId = spellId(42)
	if amplifyId and not AmplifyUp then
		local start3, duration3 = GetSpellCooldown(amplifyId, "spell")
		if start3 > 0 and duration3 > 0 then
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 1)
		else
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
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
	if ComponentState.demoniac == 0 then
		ManaPet[6] = "1"
	end

	-- Apply textures to the pet buttons
	if DemonState.type == NECROSIS_PET_LOCAL_NAME[1] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonState.type == NECROSIS_PET_LOCAL_NAME[2] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonState.type == NECROSIS_PET_LOCAL_NAME[3] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonState.type == NECROSIS_PET_LOCAL_NAME[4] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonState.type == NECROSIS_PET_LOCAL_NAME[5] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonState.type == NECROSIS_PET_LOCAL_NAME[6] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", 2)
	else
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	end

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
		if spellHasId(SpellIndex.DEMON_ARMOR) then
			if spellMana(SpellIndex.DEMON_ARMOR) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		elseif spellHasId(SpellIndex.DEMON_SKIN) then
			if spellMana(SpellIndex.DEMON_SKIN) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		end
		if spellHasId(SpellIndex.UNENDING_BREATH) then
			if spellMana(SpellIndex.UNENDING_BREATH) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 3)
			end
		end
		if spellHasId(SpellIndex.DETECT_INVISIBILITY) then
			if spellMana(SpellIndex.DETECT_INVISIBILITY) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 3)
			end
		end
		if spellHasId(SpellIndex.EYE_OF_KILROGG) then
			if spellMana(SpellIndex.EYE_OF_KILROGG) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 3)
			end
		end
		if spellHasId(SpellIndex.RITUAL_OF_SUMMONING) then
			if spellMana(SpellIndex.RITUAL_OF_SUMMONING) > mana or SoulshardState.count == 0 then
				Necrosis_SetNormalTextureIfDifferent(NecrosisBuffMenu5, "Interface\\AddOns\\Necrosis\\UI\\TPButton-05")
			else
				Necrosis_SetNormalTextureIfDifferent(NecrosisBuffMenu5, "Interface\\AddOns\\Necrosis\\UI\\TPButton-01")
			end
		end
		if spellHasId(SpellIndex.SOUL_LINK) then
			if spellMana(SpellIndex.SOUL_LINK) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 3)
			end
		end
		if spellHasId(SpellIndex.SHADOW_WARD) then
			if spellMana(SpellIndex.SHADOW_WARD) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
			end
		end
		if spellHasId(SpellIndex.BANISH) then
			if spellMana(SpellIndex.BANISH) > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 3)
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
		if spellHasId(SpellIndex.CURSE_OF_WEAKNESS) then
			if spellMana(SpellIndex.CURSE_OF_WEAKNESS) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_AGONY) then
			if spellMana(SpellIndex.CURSE_OF_AGONY) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_RECKLESSNESS) then
			if spellMana(SpellIndex.CURSE_OF_RECKLESSNESS) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_TONGUES) then
			if spellMana(SpellIndex.CURSE_OF_TONGUES) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_EXHAUSTION) then
			if spellMana(SpellIndex.CURSE_OF_EXHAUSTION) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_THE_ELEMENTS) then
			if spellMana(SpellIndex.CURSE_OF_THE_ELEMENTS) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_SHADOW) then
			if spellMana(SpellIndex.CURSE_OF_SHADOW) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 3)
			end
		end
		if spellHasId(SpellIndex.CURSE_OF_DOOM) then
			if spellMana(SpellIndex.CURSE_OF_DOOM) > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu9, "Doom", 3)
			end
		end
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
