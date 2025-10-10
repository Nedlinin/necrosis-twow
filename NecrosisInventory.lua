------------------------------------------------------------------------------------------------------
-- Necrosis Inventory & Shard Logic
------------------------------------------------------------------------------------------------------

local floor = math.floor
local wipe_table = NecrosisUtils.WipeTable
local GetTime = GetTime
local GetItemInfo = GetItemInfo
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink

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

STONE_ITEM_KEYS = STONE_ITEM_KEYS
	or {
		"Soulstone",
		"Healthstone",
		"Spellstone",
		"Firestone",
		"Felstone",
		"Wrathstone",
		"Voidstone",
		"Hearthstone",
	}

STONE_NAME_PATTERNS = STONE_NAME_PATTERNS or {}
OFFHAND_PATTERNS = OFFHAND_PATTERNS or {}

local function Necrosis_BuildStoneNamePatterns()
	wipe_table(STONE_NAME_PATTERNS)
	for index = 1, table.getn(STONE_ITEM_KEYS), 1 do
		local key = STONE_ITEM_KEYS[index]
		local pattern = NECROSIS_ITEM[key]
		if pattern and type(pattern) == "string" then
			STONE_NAME_PATTERNS[key] = pattern
		end
	end
end

local function Necrosis_BuildOffhandPatterns()
	wipe_table(OFFHAND_PATTERNS)
	if NECROSIS_ITEM.Offhand and type(NECROSIS_ITEM.Offhand) == "string" then
		OFFHAND_PATTERNS[1] = NECROSIS_ITEM.Offhand
	end
end

local BagState

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
		if not equipLoc then
			local offhandPattern = OFFHAND_PATTERNS[1]
			if offhandPattern and (line3 == offhandPattern or line4 == offhandPattern) then
				equipLoc = "INVTYPE_HOLDABLE"
			end
		end
	end

	return itemName, itemCount, equipLoc
end

local function Necrosis_IsOffhandItem(equipLoc, container, slot)
	if equipLoc == "INVTYPE_HOLDABLE" then
		return true
	end
	local offhandPattern = OFFHAND_PATTERNS[1]
	if not offhandPattern then
		return false
	end
	local _, line3, line4 = Necrosis_GetTooltipLines(container, slot)
	return line3 == offhandPattern or line4 == offhandPattern
end

function Necrosis_RequestBagScan(delay)
	BagState = BagScanState or BagState or { pending = true, nextScanTime = 0 }
	delay = delay or 0
	if delay < 0 then
		delay = 0
	end
	local now = GetTime()
	local nextScan = now + delay
	if not BagState.pending or BagState.nextScanTime == 0 or nextScan < BagState.nextScanTime then
		BagState.nextScanTime = nextScan
	end
	BagState.pending = true
end

Necrosis_BuildStoneNamePatterns()
Necrosis_BuildOffhandPatterns()

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

function Necrosis_BagExplore()
	local previousShardCount = SoulshardState.count
	SoulshardState.count = 0
	ComponentState.infernal = 0
	ComponentState.demoniac = 0
	for key, data in pairs(StoneInventory) do
		data.onHand = false
		data.location[1], data.location[2] = nil, nil
		if data.mode then
			data.mode = 1
		end
	end

	SoulshardState.container = NecrosisConfig.SoulshardContainer
	local shardContainer = SoulshardState.container
	local needsRescan = false

	for container = 0, 4, 1 do
		local slotCount = GetContainerNumSlots(container)
		for slot = 1, slotCount, 1 do
			local itemName, itemCount, equipLoc = Necrosis_GetBagSlotInfo(container, slot)
			if not itemName then
				needsRescan = true
			end
			if container == shardContainer and (not itemName or itemName ~= NECROSIS_ITEM.Soulshard) then
				SoulshardState.slots[slot] = nil
			end
			if itemName then
				if itemName == NECROSIS_ITEM.Soulshard then
					SoulshardState.count = SoulshardState.count + itemCount
				end
				if itemName == NECROSIS_ITEM.InfernalStone then
					ComponentState.infernal = ComponentState.infernal + itemCount
				end
				if itemName == NECROSIS_ITEM.DemoniacStone then
					ComponentState.demoniac = ComponentState.demoniac + itemCount
				end
				local recorded = false
				for _, stoneKey in ipairs(STONE_ITEM_KEYS) do
					local pattern = STONE_NAME_PATTERNS[stoneKey]
					if pattern and string.find(itemName, pattern, 1, true) then
						Necrosis_RecordStoneInventory(stoneKey, container, slot)
						recorded = true
						break
					end
				end
				if not recorded and Necrosis_IsOffhandItem(equipLoc, container, slot) then
					Necrosis_RecordStoneInventory("Itemswitch", container, slot)
				end
			end
		end
	end

	BagState = BagState or BagScanState or { pending = false, nextScanTime = 0 }
	BagState.pending = false
	BagState.nextScanTime = 0
	if needsRescan then
		Necrosis_RequestBagScan(0.2)
	end

	if NecrosisConfig.Circle == 1 then
		local shardIndex = SoulshardState.count
		if shardIndex > 32 then
			shardIndex = 32
		end
		Necrosis_SetNormalTextureIfDifferent(
			NecrosisButton,
			"Interface\\AddOns\\Necrosis\\UI\\" .. NecrosisConfig.NecrosisColor .. "\\Shard" .. shardIndex
		)
	elseif StoneInventory.Soulstone.mode == 1 or StoneInventory.Soulstone.mode == 2 then
		local shardIndex = SoulshardState.count
		if shardIndex > 32 then
			shardIndex = 32
		end
		Necrosis_SetNormalTextureIfDifferent(
			NecrosisButton,
			"Interface\\AddOns\\Necrosis\\UI\\Bleu\\Shard" .. shardIndex
		)
	end

	if NecrosisConfig.ShowCount then
		if NecrosisConfig.CountType == 2 then
			NecrosisShardCount:SetText(ComponentState.infernal .. " / " .. ComponentState.demoniac)
		elseif NecrosisConfig.CountType == 1 then
			if SoulshardState.count < 10 then
				NecrosisShardCount:SetText("0" .. SoulshardState.count)
			else
				NecrosisShardCount:SetText(SoulshardState.count)
			end
		end
	else
		NecrosisShardCount:SetText("")
	end

	Necrosis_UpdateIcons()

	if
		SoulshardState.count > previousShardCount
		and SoulshardState.count == GetContainerNumSlots(NecrosisConfig.SoulshardContainer)
		and NecrosisConfig.SoulshardSort
	then
		Necrosis_Msg(NECROSIS_MESSAGE.Warning.FullPouch, "USER")
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
	BagState = BagState or BagScanState or { pending = false, nextScanTime = 0 }
	if SoulshardState.pendingSortCheck then
		SoulshardState.pendingSortCheck = false
		BagState.pending = false
		BagState.nextScanTime = 0
		Necrosis_SoulshardSwitch("CHECK")
		return
	end
	if not BagState.pending then
		return
	end
	local nextScan = BagState.nextScanTime or 0
	if nextScan > 0 then
		curTime = curTime or GetTime()
		if curTime < nextScan then
			return
		end
	end
	BagState.pending = false
	BagState.nextScanTime = 0
	Necrosis_BagExplore()
end

function Necrosis_HandleShardCount()
	if NecrosisConfig.CountType == 3 then
		NecrosisShardCount:SetText("")
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
					Necrosis_MoneyToggle()
					NecrosisTooltip:SetBagItem(bag, slot)
					local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText())
					if itemInfo == NECROSIS_ITEM.Soulshard then
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
						Necrosis_MoneyToggle()
						NecrosisTooltip:SetBagItem(bag, slot)
						local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText())
						if itemInfo == NECROSIS_ITEM.Soulshard then
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
			Necrosis_RequestBagScan(0)
			return
		end
	end
	if action == "CHECK" then
		Necrosis_RequestBagScan(0)
	end
end
function Necrosis_FindSlot(shardIndex, shardSlot)
	local full = true
	for slot = 1, GetContainerNumSlots(NecrosisConfig.SoulshardContainer), 1 do
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetBagItem(NecrosisConfig.SoulshardContainer, slot)
		local itemInfo = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(itemInfo, NECROSIS_ITEM.Soulshard) == nil then
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
	if SpellTimer then
		for index = 1, table.getn(SpellTimer), 1 do
			if (SpellTimer[index].Name == NECROSIS_SPELL_TABLE[11].Name) and SpellTimer[index].TimeMax > 0 then
				SoulstoneInUse = true
				break
			end
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
				SpellTimer, TimerTable = Necrosis_EnsureSpellIndexTimer(
					11,
					"???",
					timeRemaining,
					NECROSIS_SPELL_TABLE[11].Type,
					timeRemaining,
					expiry,
					SpellTimer,
					TimerTable
				)
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
		if SoulstoneAdvice and NECROSIS_SOULSTONE_ALERT_MESSAGE then
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
					Necrosis_Msg(Necrosis_MsgReplace(lines[i], SoulstoneTarget), "WORLD")
				end
				SoulstoneAdvice = false
			end
		end
	end

	-- If the stone was consumed but another is in the inventory
	if StoneInventory.Soulstone.onHand and SoulstoneInUse then
		SoulstoneAdvice = false
		if not (SoulstoneWaiting or SoulstoneCooldown) then
			SpellTimer, TimerTable = Necrosis_RemoveTimerByName(NECROSIS_SPELL_TABLE[11].Name, SpellTimer, TimerTable)
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
	local ManaPet = { "3", "3", "3", "3", "3", "3" }

	-- Si cooldown de domination corrompue on grise
	if NECROSIS_SPELL_TABLE[15].ID and not DominationUp then
		local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell")
		if start > 0 and duration > 0 then
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 1)
		else
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
	end

	-- Si cooldown de gardien de l'ombre on grise
	if NECROSIS_SPELL_TABLE[43].ID then
		local start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, "spell")
		if start2 > 0 and duration2 > 0 then
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
		else
			Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
		end
	end

	-- Gray out the button while Amplify Curse is on cooldown
	if NECROSIS_SPELL_TABLE[42].ID and not AmplifyUp then
		local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell")
		if start3 > 0 and duration3 > 0 then
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 1)
		else
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
		end
	end

	if mana ~= nil then
		-- Grey out the button when there is not enough mana
		if NECROSIS_SPELL_TABLE[3].ID then
			if NECROSIS_SPELL_TABLE[3].Mana > mana then
				for i = 1, 6, 1 do
					ManaPet[i] = "1"
				end
			elseif NECROSIS_SPELL_TABLE[4].ID then
				if NECROSIS_SPELL_TABLE[4].Mana > mana then
					for i = 2, 6, 1 do
						ManaPet[i] = "1"
					end
				elseif NECROSIS_SPELL_TABLE[8].ID then
					if NECROSIS_SPELL_TABLE[8].Mana > mana then
						for i = 5, 6, 1 do
							ManaPet[i] = "1"
						end
					elseif NECROSIS_SPELL_TABLE[30].ID then
						if NECROSIS_SPELL_TABLE[30].Mana > mana then
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
	if DemonType == NECROSIS_PET_LOCAL_NAME[1] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[2] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[3] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[4] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", ManaPet[5])
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[5] then
		Necrosis_SetButtonTexture(NecrosisPetMenu2, "Imp", ManaPet[1])
		Necrosis_SetButtonTexture(NecrosisPetMenu3, "Voidwalker", ManaPet[2])
		Necrosis_SetButtonTexture(NecrosisPetMenu4, "Succubus", ManaPet[3])
		Necrosis_SetButtonTexture(NecrosisPetMenu5, "Felhunter", ManaPet[4])
		Necrosis_SetButtonTexture(NecrosisPetMenu6, "Infernal", 2)
		Necrosis_SetButtonTexture(NecrosisPetMenu7, "Doomguard", ManaPet[6])
	elseif DemonType == NECROSIS_PET_LOCAL_NAME[6] then
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
			if NECROSIS_SPELL_TABLE[2].ID then
				if NECROSIS_SPELL_TABLE[2].Mana > mana or CombatState.inCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			else
				if NECROSIS_SPELL_TABLE[1].Mana > mana or CombatState.inCombat then
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
				else
					Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 3)
				end
			end
		end
		if NECROSIS_SPELL_TABLE[35].ID then
			if NECROSIS_SPELL_TABLE[35].Mana > mana or SoulshardState.count == 0 then
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 1)
			else
				Necrosis_SetButtonTexture(NecrosisPetMenu8, "Enslave", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[31].ID then
			if NECROSIS_SPELL_TABLE[31].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		elseif NECROSIS_SPELL_TABLE[36].ID then
			if NECROSIS_SPELL_TABLE[36].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu1, "ArmureDemo", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[32].ID then
			if NECROSIS_SPELL_TABLE[32].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu2, "Aqua", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[33].ID then
			if NECROSIS_SPELL_TABLE[33].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu3, "Invisible", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[34].ID then
			if NECROSIS_SPELL_TABLE[34].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu4, "Kilrogg", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[37].ID then
			if NECROSIS_SPELL_TABLE[37].Mana > mana or SoulshardState.count == 0 then
				Necrosis_SetNormalTextureIfDifferent(NecrosisBuffMenu5, "Interface\\AddOns\\Necrosis\\UI\\TPButton-05")
			else
				Necrosis_SetNormalTextureIfDifferent(NecrosisBuffMenu5, "Interface\\AddOns\\Necrosis\\UI\\TPButton-01")
			end
		end
		if NECROSIS_SPELL_TABLE[38].ID then
			if NECROSIS_SPELL_TABLE[38].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu7, "Lien", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[43].ID then
			if NECROSIS_SPELL_TABLE[43].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu8, "ShadowWard", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[9].ID then
			if NECROSIS_SPELL_TABLE[9].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 1)
			else
				Necrosis_SetButtonTexture(NecrosisBuffMenu9, "Banish", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[44].ID then
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
		if NECROSIS_SPELL_TABLE[23].ID then
			if NECROSIS_SPELL_TABLE[23].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu2, "Weakness", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[22].ID then
			if NECROSIS_SPELL_TABLE[22].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu3, "Agony", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[24].ID then
			if NECROSIS_SPELL_TABLE[24].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu4, "Reckless", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[25].ID then
			if NECROSIS_SPELL_TABLE[25].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu5, "Tongues", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[40].ID then
			if NECROSIS_SPELL_TABLE[40].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu6, "Exhaust", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[26].ID then
			if NECROSIS_SPELL_TABLE[26].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu7, "Elements", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[27].ID then
			if NECROSIS_SPELL_TABLE[27].Mana > mana then
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 1)
			else
				Necrosis_SetButtonTexture(NecrosisCurseMenu8, "Shadow", 3)
			end
		end
		if NECROSIS_SPELL_TABLE[16].ID then
			if NECROSIS_SPELL_TABLE[16].Mana > mana then
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
