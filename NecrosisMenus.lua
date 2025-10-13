------------------------------------------------------------------------------------------------------
-- Necrosis Menu Management
------------------------------------------------------------------------------------------------------

local function Necrosis_SetMenuAlpha(prefix, alpha)
	for index = 1, 9, 1 do
		local frame = getglobal(prefix .. index)
		if frame then
			frame:SetAlpha(alpha)
		end
	end
end

local MenuState = Necrosis.GetMenuState()
MenuState = MenuState or {}

local LastCast = Necrosis.GetLastCast()
local Spells = Necrosis.Spells
local SpellIndex = Spells.Index

local function Necrosis_HasSpell(spellIndex)
	return spellIndex and Spells:HasID(spellIndex)
end

local function Necrosis_ShouldAddMenuEntry(entry)
	if entry.condition then
		return entry.condition()
	end
	if entry.spell then
		return Necrosis_HasSpell(entry.spell)
	end
	if entry.spells then
		local requireAll = entry.check == "all"
		if requireAll then
			for index = 1, table.getn(entry.spells), 1 do
				if not Necrosis_HasSpell(entry.spells[index]) then
					return false
				end
			end
			return true
		end
		for index = 1, table.getn(entry.spells), 1 do
			if Necrosis_HasSpell(entry.spells[index]) then
				return true
			end
		end
		return false
	end
	return false
end

MenuManager = {}

function MenuManager:SetFramePrefixAlpha(prefix, alpha)
	if not prefix then
		return
	end
	Necrosis_SetMenuAlpha(prefix, alpha)
end

function MenuManager:SetStateAlpha(menuState, alpha)
	local frames = menuState and menuState.frames
	if not frames then
		return
	end
	for index = 1, table.getn(frames), 1 do
		local frame = frames[index]
		if frame then
			frame:SetAlpha(alpha)
		end
	end
end

function MenuManager:AddFrame(menuState, frameName, anchorButton, menuPos)
	if not menuState then
		return nil
	end
	local frame = getglobal(frameName)
	if not frame then
		return nil
	end
	frame:ClearAllPoints()
	local frames = menuState.frames or {}
	local previousIndex = table.getn(frames)
	local previous = previousIndex > 0 and frames[previousIndex] or nil
	if previous then
		local spacing = 0
		if menuPos and menuPos ~= 0 then
			spacing = (36 / menuPos) * 31
		end
		frame:SetPoint("CENTER", previous, "CENTER", spacing, 0)
	else
		frame:SetPoint("CENTER", anchorButton, "CENTER", 3000, 3000)
	end
	frame:Hide()
	menuState.frames = frames
	table.insert(menuState.frames, frame)
	return frame
end

function MenuManager:HideFrames(prefix, count)
	for index = 1, count, 1 do
		local frame = getglobal(prefix .. index)
		if frame then
			frame:Hide()
		end
	end
end

function MenuManager:ShowFrames(menuState)
	local frames = menuState and menuState.frames
	if not frames then
		return
	end
	for index = 1, table.getn(frames), 1 do
		ShowUIPanel(frames[index])
	end
end

function MenuManager:BuildMenu(definition)
	if not definition then
		return
	end
	local menuState = definition.state
	if not menuState then
		return
	end
	menuState.frames = {}
	self:HideFrames(definition.prefix, definition.count)
	local anchor = getglobal(definition.anchor)
	if not anchor then
		return
	end
	local menuPos = NecrosisConfig[definition.configKey] or 0
	for index = 1, table.getn(definition.entries), 1 do
		local entry = definition.entries[index]
		if Necrosis_ShouldAddMenuEntry(entry) then
			local frame = self:AddFrame(menuState, entry.frame, anchor, menuPos)
			if frame then
				if entry.texture then
					local texture = entry.texture
					Necrosis_SetButtonTexture(frame, texture.base or texture[1], texture.variant or texture[2])
				end
				if entry.onAdd then
					entry.onAdd(frame)
				end
			end
		end
	end
	self:ShowFrames(menuState)
end

function MenuManager:Toggle(menuState, button, options)
	if not menuState then
		return false
	end
	menuState.open = not menuState.open
	if not menuState.open then
		menuState.fading = false
		menuState.sticky = false
		Necrosis_SetNormalTextureIfDifferent(button, options.closedTexture)
		if menuState.frames and menuState.frames[1] then
			menuState.frames[1]:ClearAllPoints()
			menuState.frames[1]:SetPoint("CENTER", button, "CENTER", 3000, 3000)
		end
		if options.resetAlpha then
			self:SetStateAlpha(menuState, options.resetAlpha)
		end
		menuState.alpha = 1
		if options.onClose then
			options.onClose()
		end
		return false
	end

	menuState.fading = true
	Necrosis_SetNormalTextureIfDifferent(button, options.openTexture)
	if options.rightSticky and options.rightSticky() then
		menuState.sticky = true
	end
	if options.setAlpha then
		self:SetStateAlpha(menuState, options.setAlpha)
	end
	if options.onOpen then
		options.onOpen()
	end
	return true
end

function MenuManager:UpdateState(menuState, framePrefix, toggleFunc, curTime)
	if not menuState or not menuState.fading then
		return
	end

	if curTime >= menuState.fadeAt and menuState.alpha > 0 and not menuState.sticky then
		menuState.fadeAt = curTime + 0.1
		Necrosis_SetMenuAlpha(framePrefix, menuState.alpha)
		menuState.alpha = menuState.alpha - 0.1
	end

	if menuState.alpha <= 0 and type(toggleFunc) == "function" then
		toggleFunc()
	end
end

function MenuManager:UpdateAll(curTime)
	self:UpdateState(MenuState.Pet, "NecrosisPetMenu", Necrosis_PetMenu, curTime)
	self:UpdateState(MenuState.Buff, "NecrosisBuffMenu", Necrosis_BuffMenu, curTime)
	self:UpdateState(MenuState.Curse, "NecrosisCurseMenu", Necrosis_CurseMenu, curTime)
	self:UpdateState(MenuState.Stone, "NecrosisStoneMenu", Necrosis_StoneMenu, curTime)
end

local MENU_LAYOUT = {
	Pet = {
		state = MenuState.Pet,
		button = "NecrosisPetMenuButton",
		prefix = "NecrosisPetMenu",
		count = 9,
		offset = 36,
		configKey = "PetMenuPos",
		entries = {
			{ frame = "NecrosisPetMenu1", spells = { SpellIndex.FEL_DOMINATION } },
			{ frame = "NecrosisPetMenu2", spells = { SpellIndex.SUMMON_IMP } },
			{ frame = "NecrosisPetMenu3", spells = { SpellIndex.SUMMON_VOIDWALKER } },
			{ frame = "NecrosisPetMenu4", spells = { SpellIndex.SUMMON_SUCCUBUS } },
			{ frame = "NecrosisPetMenu5", spells = { SpellIndex.SUMMON_FELHUNTER } },
			{ frame = "NecrosisPetMenu6", spells = { SpellIndex.INFERNO } },
			{ frame = "NecrosisPetMenu7", spells = { SpellIndex.RITUAL_OF_DOOM } },
			{ frame = "NecrosisPetMenu8", spells = { SpellIndex.ENSLAVE_DEMON_EFFECT } },
			{ frame = "NecrosisPetMenu9", spells = { SpellIndex.DEMONIC_SACRIFICE } },
		},
	},
	Buff = {
		state = MenuState.Buff,
		button = "NecrosisBuffMenuButton",
		prefix = "NecrosisBuffMenu",
		count = 9,
		offset = 36,
		configKey = "BuffMenuPos",
		entries = {
			{ frame = "NecrosisBuffMenu1", spells = { SpellIndex.DEMON_ARMOR, SpellIndex.DEMON_SKIN } },
			{ frame = "NecrosisBuffMenu2", spells = { SpellIndex.UNENDING_BREATH } },
			{ frame = "NecrosisBuffMenu3", spells = { SpellIndex.DETECT_INVISIBILITY } },
			{ frame = "NecrosisBuffMenu4", spells = { SpellIndex.EYE_OF_KILROGG } },
			{ frame = "NecrosisBuffMenu5", spells = { SpellIndex.RITUAL_OF_SUMMONING } },
			{ frame = "NecrosisBuffMenu6", spells = { SpellIndex.SENSE_DEMONS } },
			{ frame = "NecrosisBuffMenu7", spells = { SpellIndex.SOUL_LINK } },
			{ frame = "NecrosisBuffMenu8", spells = { SpellIndex.SHADOW_WARD } },
			{ frame = "NecrosisBuffMenu9", spells = { SpellIndex.BANISH } },
		},
	},
	Curse = {
		state = MenuState.Curse,
		button = "NecrosisCurseMenuButton",
		prefix = "NecrosisCurseMenu",
		count = 9,
		offset = 36,
		configKey = "CurseMenuPos",
		entries = {
			{ frame = "NecrosisCurseMenu1", spells = { SpellIndex.AMPLIFY_CURSE } },
			{ frame = "NecrosisCurseMenu2", spells = { SpellIndex.CURSE_OF_WEAKNESS } },
			{ frame = "NecrosisCurseMenu3", spells = { SpellIndex.CURSE_OF_AGONY } },
			{ frame = "NecrosisCurseMenu4", spells = { SpellIndex.CURSE_OF_RECKLESSNESS } },
			{ frame = "NecrosisCurseMenu5", spells = { SpellIndex.CURSE_OF_TONGUES } },
			{ frame = "NecrosisCurseMenu6", spells = { SpellIndex.CURSE_OF_EXHAUSTION } },
			{ frame = "NecrosisCurseMenu7", spells = { SpellIndex.CURSE_OF_THE_ELEMENTS } },
			{ frame = "NecrosisCurseMenu8", spells = { SpellIndex.CURSE_OF_SHADOW } },
			{ frame = "NecrosisCurseMenu9", spells = { SpellIndex.CURSE_OF_DOOM } },
		},
	},
	Stone = {
		state = MenuState.Stone,
		button = "NecrosisStoneMenuButton",
		prefix = "NecrosisStoneMenu",
		count = 4,
		offset = 36,
		configKey = "StoneMenuPos",
		entries = {
			{
				frame = "NecrosisStoneMenu1",
				spells = { SpellIndex.CREATE_FELSTONE },
				texture = { base = "Felstone", variant = 2 },
			},
			{
				frame = "NecrosisStoneMenu2",
				spells = { SpellIndex.CREATE_WRATHSTONE },
				texture = { base = "Wrathstone", variant = 2 },
			},
			{
				frame = "NecrosisStoneMenu3",
				spells = { SpellIndex.CREATE_VOIDSTONE },
				texture = { base = "Voidstone", variant = 2 },
			},
			{
				frame = "NecrosisStoneMenu4",
				condition = function()
					return StoneIDInSpellTable[4] ~= 0
				end,
				texture = { base = "FirestoneButton", variant = 2 },
			},
		},
	},
}

function Necrosis_UpdateMenus(curTime)
	MenuManager:UpdateAll(curTime)
end

function Necrosis_CreateMenu()
	for _, layout in pairs(MENU_LAYOUT) do
		layout.state.frames = {}
	end

	for _, layout in pairs(MENU_LAYOUT) do
		MenuManager:BuildMenu({
			state = layout.state,
			prefix = layout.prefix,
			count = layout.count,
			anchor = layout.button,
			configKey = layout.configKey,
			entries = layout.entries,
		})
	end
end

function Necrosis_BuffMenu(button)
	if button == "MiddleButton" and LastCast.Buff ~= 0 then
		Necrosis_BuffCast(LastCast.Buff)
		return
	end
	local buffMenu = MenuState.Buff
	local opened = MenuManager:Toggle(buffMenu, NecrosisBuffMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\BuffMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	if not buffMenu.frames[1] then
		return
	end
	buffMenu.frames[1]:ClearAllPoints()
	buffMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisBuffMenuButton",
		"CENTER",
		((36 / NecrosisConfig.BuffMenuPos) * 31),
		26
	)
	MenuState.Pet.fadeAt = GetTime() + 3
	buffMenu.fadeAt = GetTime() + 6
	MenuState.Curse.fadeAt = GetTime() + 6
end

function Necrosis_CurseMenu(button)
	if button == "MiddleButton" and LastCast.Curse.id ~= 0 then
		Necrosis_CurseCast(LastCast.Curse.id, LastCast.Curse.click)
		return
	end
	local curseMenu = MenuState.Curse
	if not curseMenu.frames[1] then
		return
	end
	local opened = MenuManager:Toggle(curseMenu, NecrosisCurseMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\CurseMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	curseMenu.frames[1]:ClearAllPoints()
	curseMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisCurseMenuButton",
		"CENTER",
		((36 / NecrosisConfig.CurseMenuPos) * 31),
		-26
	)
	MenuState.Pet.fadeAt = GetTime() + 3
	MenuState.Buff.fadeAt = GetTime() + 6
	curseMenu.fadeAt = GetTime() + 6
end

function Necrosis_PetMenu(button)
	if button == "MiddleButton" and LastCast and LastCast.Demon and LastCast.Demon ~= 0 then
		Necrosis_PetCast(LastCast.Demon)
		return
	end
	local petMenu = MenuState.Pet
	if not petMenu.frames[1] then
		return
	end
	local opened = MenuManager:Toggle(petMenu, NecrosisPetMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\PetMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
	})
	if not opened then
		return
	end
	petMenu.frames[1]:ClearAllPoints()
	petMenu.frames[1]:SetPoint("CENTER", "NecrosisPetMenuButton", "CENTER", ((36 / NecrosisConfig.PetMenuPos) * 31), 26)
	MenuState.Pet.fadeAt = GetTime() + 3
end

function Necrosis_StoneMenu(button)
	local lastStone = (LastCast and LastCast.Stone) or { id = 0, click = "LeftButton" }
	if button == "MiddleButton" and lastStone.id ~= 0 then
		Necrosis_StoneCast(lastStone.id, lastStone.click)
		return
	end
	local stoneMenu = MenuState.Stone
	if not stoneMenu.frames[1] then
		return
	end
	local opened = MenuManager:Toggle(stoneMenu, NecrosisStoneMenuButton, {
		closedTexture = "Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-01",
		openTexture = "Interface\\AddOns\\Necrosis\\UI\\StoneMenuButton-02",
		rightSticky = function()
			return button == "RightButton"
		end,
		setAlpha = 1,
		onOpen = Necrosis_UpdateIcons,
		onClose = Necrosis_UpdateIcons,
	})
	if not opened then
		return
	end
	MenuManager:SetStateAlpha(stoneMenu, 1)
	stoneMenu.frames[1]:ClearAllPoints()
	stoneMenu.frames[1]:SetPoint(
		"CENTER",
		"NecrosisStoneMenuButton",
		"CENTER",
		((36 / NecrosisConfig.StoneMenuPos) * 31),
		-26
	)
	stoneMenu.fadeAt = GetTime() + 6
end
