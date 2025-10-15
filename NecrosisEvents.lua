------------------------------------------------------------------------------------------------------
-- Necrosis Event Wiring
------------------------------------------------------------------------------------------------------

local floor = math.floor
local wipe_table = NecrosisUtils.WipeTable

Necrosis = Necrosis or {}
Necrosis.Events = Necrosis.Events or {}

local Loc = Necrosis.Loc or {}

local Dispatcher = Necrosis.Events
Dispatcher.handlers = Dispatcher.handlers or {}

function Dispatcher:Register(eventName, handler)
	if not eventName or type(handler) ~= "function" then
		return
	end
	self.handlers[eventName] = handler
end

function Dispatcher:Get(eventName)
	if not eventName then
		return nil
	end
	return self.handlers[eventName]
end

function Dispatcher:Fire(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	local handler = self:Get(eventName)
	if handler then
		return handler(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	end
end

function Dispatcher:Iterate()
	return pairs(self.handlers)
end

-- Config cache to eliminate repeated table lookups in hot path
local configCache = {
	shadowTranceAlert = false,
	antiFearAlert = false,
	showSpellTimers = false,
	graphical = false,
	sound = false,
	diagnosticsEnabled = false,
}

function Necrosis_UpdateConfigCache()
	if not NecrosisConfig then
		return
	end
	configCache.shadowTranceAlert = NecrosisConfig.ShadowTranceAlert
	configCache.antiFearAlert = NecrosisConfig.AntiFearAlert
	configCache.showSpellTimers = NecrosisConfig.ShowSpellTimers
	configCache.graphical = NecrosisConfig.Graphical
	configCache.sound = NecrosisConfig.Sound
	configCache.diagnosticsEnabled = NecrosisConfig.DiagnosticsEnabled
end

local SHADOW_TRANCE_BUFF_FLAGS = "HELPFUL|HARMFUL|PASSIVE"
local ANTI_FEAR_TEXTURE_BASE = "Interface\\AddOns\\Necrosis\\UI\\AntiFear"
local ANTI_FEAR_TEXTURE_SUFFIXES = { "", "Immu", "Prot" }
local ANTI_FEAR_TEXTURE_VARIANTS = {}

local function wipe_array(t)
	if type(t) ~= "table" then
		return
	end
	for index = table.getn(t), 1, -1 do
		t[index] = nil
	end
end

for mode = 1, table.getn(ANTI_FEAR_TEXTURE_SUFFIXES) do
	local suffix = ANTI_FEAR_TEXTURE_SUFFIXES[mode] or ""
	local prefix = ANTI_FEAR_TEXTURE_BASE .. suffix
	ANTI_FEAR_TEXTURE_VARIANTS[mode] = {
		[1] = prefix .. "-01",
		[2] = prefix .. "-02",
	}
end

local function getAntiFearTexture(mode, variant)
	local textures = ANTI_FEAR_TEXTURE_VARIANTS[mode]
	if not textures then
		textures = ANTI_FEAR_TEXTURE_VARIANTS[1]
	end
	return textures[variant] or textures[2]
end

local function getState(key)
	return Necrosis.GetStateSlice(key)
end

local ShadowState = getState("shadowTrance")
local AntiFearState = getState("antiFear")
local TradeState = getState("trade")
local InitState = getState("initialization")
local CombatState = getState("combat")

AntiFearState.buffTextureSet = AntiFearState.buffTextureSet or {}
AntiFearState.debuffTextureSet = AntiFearState.debuffTextureSet or {}
AntiFearState.buffNameSet = AntiFearState.buffNameSet or {}
AntiFearState.debuffNameSet = AntiFearState.debuffNameSet or {}

local ANTI_FEAR_BUFF_TEXTURE_SET = {}
local ANTI_FEAR_DEBUFF_TEXTURE_SET = {}
local ANTI_FEAR_FALLBACK_BUFF_NAMES = {}
local ANTI_FEAR_FALLBACK_DEBUFF_NAMES = {}
local PRESET_ANTI_FEAR_TEXTURES = {
	["Fear Ward"] = "Interface\\Icons\\Spell_Holy_Excorcism",
	["Will of the Forsaken"] = "Interface\\Icons\\Spell_Shadow_Raisedead",
	["Berserker Rage"] = "Interface\\Icons\\Spell_Nature_AncestralGuardian",
	["Recklessness"] = "Interface\\Icons\\Ability_CriticalStrike",
	["Death Wish"] = "Interface\\Icons\\Spell_Shadow_DeathPact",
	["Bestial Wrath"] = "Interface\\Icons\\Ability_Druid_FerociousBite",
	["Ice Block"] = "Interface\\Icons\\Spell_Frost_Frost",
	["Divine Protection"] = "Interface\\Icons\\Spell_Holy_Restoration",
	["Divine Shield"] = "Interface\\Icons\\Spell_Holy_DivineIntervention",
	["Tremor Totem"] = "Interface\\Icons\\Spell_Nature_TremorTotem",
	["Curse of Recklessness"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
}

local function safeGetSpellTexture(identifier)
	if not identifier or identifier == "" then
		return nil
	end
	local ok, texture = pcall(GetSpellTexture, identifier)
	if ok then
		return texture
	end
	return nil
end

local function cache_has_texture(cache, lookup)
	if not cache or not lookup then
		return false
	end
	for texture in pairs(cache) do
		if lookup[texture] then
			return true
		end
	end
	return false
end

local function cache_has_name(cache, lookup)
	if not cache or not lookup then
		return false
	end
	for name in pairs(cache) do
		if lookup[name] then
			return true
		end
	end
	return false
end

local function addTextureForName(name, targetSet, fallbackSet)
	if not name then
		return
	end
	local texture = safeGetSpellTexture(name)
	if not texture then
		texture = PRESET_ANTI_FEAR_TEXTURES[name]
	end
	if texture then
		targetSet[texture] = true
	else
		fallbackSet[name] = true
	end
end

for _, name in ipairs(NECROSIS_ANTI_FEAR_SPELL.Buff) do
	addTextureForName(name, ANTI_FEAR_BUFF_TEXTURE_SET, ANTI_FEAR_FALLBACK_BUFF_NAMES)
end

for _, name in ipairs(NECROSIS_ANTI_FEAR_SPELL.Debuff) do
	addTextureForName(name, ANTI_FEAR_DEBUFF_TEXTURE_SET, ANTI_FEAR_FALLBACK_DEBUFF_NAMES)
end

AntiFearState.requireBuffNameCache = next(ANTI_FEAR_FALLBACK_BUFF_NAMES) ~= nil
AntiFearState.requireDebuffNameCache = next(ANTI_FEAR_FALLBACK_DEBUFF_NAMES) ~= nil

local function Necrosis_UpdateTargetAuraCacheInternal()
	AntiFearState.buffTextureSet = AntiFearState.buffTextureSet or {}
	AntiFearState.debuffTextureSet = AntiFearState.debuffTextureSet or {}
	AntiFearState.buffNameSet = AntiFearState.buffNameSet or {}
	AntiFearState.debuffNameSet = AntiFearState.debuffNameSet or {}
	local buffTextures = AntiFearState.buffTextureSet
	local debuffTextures = AntiFearState.debuffTextureSet
	local buffNames = AntiFearState.buffNameSet
	local debuffNames = AntiFearState.debuffNameSet
	wipe_table(buffTextures)
	wipe_table(debuffTextures)
	wipe_table(buffNames)
	wipe_table(debuffNames)

	if not UnitExists("target") then
		AntiFearState.targetGuid = nil
		AntiFearState.targetAuraSignature = (AntiFearState.targetAuraSignature or 0) + 1
		AntiFearState.cachedStatus = 0
		AntiFearState.statusDirty = false
		return
	end

	local requireBuffFallback = AntiFearState.requireBuffNameCache
	local requireDebuffFallback = AntiFearState.requireDebuffNameCache

	for index = 1, 32, 1 do
		local texture = UnitBuff("target", index)
		if not texture then
			break
		end
		buffTextures[texture] = true
		if requireBuffFallback and not ANTI_FEAR_BUFF_TEXTURE_SET[texture] then
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetUnitBuff("target", index)
			local name = NecrosisTooltipTextLeft1 and NecrosisTooltipTextLeft1:GetText()
			if name and name ~= "" then
				buffNames[name] = true
			end
		end
	end

	for index = 1, 16, 1 do
		local texture = UnitDebuff("target", index)
		if not texture then
			break
		end
		debuffTextures[texture] = true
		if requireDebuffFallback and not ANTI_FEAR_DEBUFF_TEXTURE_SET[texture] then
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetUnitDebuff("target", index)
			local name = NecrosisTooltipTextLeft1 and NecrosisTooltipTextLeft1:GetText()
			if name and name ~= "" then
				debuffNames[name] = true
			end
		end
	end

	if type(UnitGUID) == "function" then
		AntiFearState.targetGuid = UnitGUID("target")
	else
		AntiFearState.targetGuid = nil
	end
	AntiFearState.targetAuraSignature = (AntiFearState.targetAuraSignature or 0) + 1
	AntiFearState.statusDirty = true
end

function Necrosis_RebuildTargetAuraCache()
	Necrosis_UpdateTargetAuraCacheInternal()
end

local function Necrosis_UpdateShadowTranceState()
	local buffId = -1
	for index = 0, 24, 1 do
		local texture = GetPlayerBuffTexture(index)
		if not texture then
			break
		end
		if strfind(texture, "Spell_Shadow_Twilight") then
			buffId = index
			break
		end
	end
	ShadowState.buffId = buffId
	if buffId ~= -1 then
		local timeLeft = GetPlayerBuffTimeLeft(buffId) or 0
		if timeLeft > 0 then
			ShadowState.remaining = floor(timeLeft)
		else
			ShadowState.remaining = nil
		end
	else
		ShadowState.remaining = nil
	end
end

function Necrosis_RefreshShadowTranceState()
	Necrosis_UpdateShadowTranceState()
end

local function Necrosis_GetCachedTargetFearStatus()
	if not NecrosisConfig.AntiFearAlert then
		return 0
	end

	if AntiFearState.targetAuraSignature == nil and UnitExists("target") then
		Necrosis_UpdateTargetAuraCacheInternal()
	end

	if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
		AntiFearState.cachedStatus = 0
		AntiFearState.statusDirty = false
		return 0
	end

	if AntiFearState.statusDirty ~= false then
		local status = 0
		if not UnitIsPlayer("target") then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_UNIT), 1 do
				if UnitCreatureType("target") == NECROSIS_ANTI_FEAR_UNIT[index] then
					status = 2
					break
				end
			end
		end

		if status == 0 then
			if cache_has_texture(AntiFearState.buffTextureSet, ANTI_FEAR_BUFF_TEXTURE_SET) then
				status = 3
			elseif
				AntiFearState.requireBuffNameCache
				and cache_has_name(AntiFearState.buffNameSet, ANTI_FEAR_FALLBACK_BUFF_NAMES)
			then
				status = 3
			end
		end

		if status == 0 then
			if cache_has_texture(AntiFearState.debuffTextureSet, ANTI_FEAR_DEBUFF_TEXTURE_SET) then
				status = 3
			elseif
				AntiFearState.requireDebuffNameCache
				and cache_has_name(AntiFearState.debuffNameSet, ANTI_FEAR_FALLBACK_DEBUFF_NAMES)
			then
				status = 3
			end
		end

		if status == 0 and AntiFearState.currentTargetImmune then
			status = 1
		end

		AntiFearState.cachedStatus = status
		AntiFearState.statusDirty = false
	end

	return AntiFearState.cachedStatus or 0
end

local function Necrosis_OnSpellcastStartEvent(_, spellName)
	Necrosis_OnSpellcastStart(spellName)
end

local function Necrosis_OnSpellcastStopEvent()
	if type(Necrosis_SpellManagement) == "function" then
		Necrosis_SpellManagement()
	end
end

local function Necrosis_OnTradeRequestEvent()
	Necrosis_SetTradeRequest(true)
end

local function Necrosis_OnTradeCancelledEvent()
	Necrosis_SetTradeRequest(false)
end

local function Necrosis_OnSelfDamageEvent(_, message)
	Necrosis_HandleSelfFearDamage(message)
end

local function Necrosis_OnUnitPetEvent(_, unitId)
	if unitId == "player" then
		Necrosis_ChangeDemon()
	end
end

local function Necrosis_OnBuffEvent()
	Necrosis_SelfEffect("BUFF")
end

local function Necrosis_OnDebuffEvent()
	Necrosis_SelfEffect("DEBUFF")
end

local function Necrosis_OnPlayerAuraEvent(_, unitId)
	-- UNIT_AURA event handler
	-- This fires when auras (buffs/debuffs) change on a unit
	-- Currently handled primarily through other events (BUFF/DEBUFF messages)
	-- Could be extended for more responsive aura tracking in the future
	if unitId == "player" then
		-- Player aura changed - could update shadow trance, demon armor, etc.
		-- For now, this is handled through spell cast events
	elseif unitId == "target" then
		-- Target aura changed - update anti-fear cache
		Necrosis_RebuildTargetAuraCache()
	end
end

local defaultHandlers = {
	BAG_UPDATE = Necrosis_OnBagUpdate,
	SPELLCAST_START = Necrosis_OnSpellcastStartEvent,
	SPELLCAST_STOP = Necrosis_OnSpellcastStopEvent,
	SPELLCAST_FAILED = Necrosis_ClearSpellcastContext,
	SPELLCAST_INTERRUPTED = Necrosis_ClearSpellcastContext,
	TRADE_REQUEST = Necrosis_OnTradeRequestEvent,
	TRADE_SHOW = Necrosis_OnTradeRequestEvent,
	TRADE_REQUEST_CANCEL = Necrosis_OnTradeCancelledEvent,
	TRADE_CLOSED = Necrosis_OnTradeCancelledEvent,
	PLAYER_TARGET_CHANGED = Necrosis_OnTargetChanged,
	CHAT_MSG_SPELL_SELF_DAMAGE = Necrosis_OnSelfDamageEvent,
	CHAT_MSG_SPELL_SELF_BUFF = Necrosis_OnBuffEvent,
	LEARNED_SPELL_IN_TAB = Necrosis_OnSpellLearned,
	PLAYER_REGEN_ENABLED = Necrosis_OnCombatEnd,
	PLAYER_REGEN_DISABLED = function()
		CombatState.inCombat = true
	end,
	UNIT_PET = Necrosis_OnUnitPetEvent,
	CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = Necrosis_OnBuffEvent,
	CHAT_MSG_SPELL_AURA_GONE_SELF = Necrosis_OnDebuffEvent,
	CHAT_MSG_SPELL_BREAK_AURA = Necrosis_OnDebuffEvent,
	UNIT_AURA = Necrosis_OnPlayerAuraEvent,
}

for eventName, handler in pairs(defaultHandlers) do
	Dispatcher:Register(eventName, handler)
end

NECROSIS_EVENT_HANDLERS = Dispatcher.handlers

local function Necrosis_HandleTradingAndIcons(shouldUpdate)
	if not shouldUpdate then
		return
	end

	if TradeState.active then
		local countdown = TradeState.countdown or 0
		if countdown > 0 then
			countdown = countdown - 1
			TradeState.countdown = countdown
		end
		if countdown <= 0 then
			AcceptTrade()
			TradeState.active = false
			TradeState.countdown = 0
		end
	end

	Necrosis_UpdateIcons()
end

local function Necrosis_UpdateShadowTrance(curTime)
	if not configCache.shadowTranceAlert then
		return
	end

	local nextUpdate = ShadowState.nextUpdate or 0
	if curTime < nextUpdate then
		return
	end

	local buffId = ShadowState.buffId
	if buffId == nil then
		Necrosis_UpdateShadowTranceState()
		buffId = ShadowState.buffId or -1
	end

	local hasShadowTrance = buffId ~= -1

	if hasShadowTrance and not ShadowState.active then
		ShadowState.active = true
		ShadowState.remaining = nil
		if NECROSIS_NIGHTFALL_TEXT and NECROSIS_NIGHTFALL_TEXT.Message then
			Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.Message, "USER")
		end
		if configCache.sound and NECROSIS_SOUND and NECROSIS_SOUND.ShadowTrance then
			PlaySoundFile(NECROSIS_SOUND.ShadowTrance)
		end
		if NecrosisShadowTranceButton then
			if type(Necrosis_SetButtonTexture) == "function" then
				Necrosis_SetButtonTexture(NecrosisShadowTranceButton, "ShadowTrance-Icon", 3)
			else
				NecrosisShadowTranceButton:SetNormalTexture("Interface\\AddOns\\Necrosis\\UI\\ShadowTrance-Icon")
			end
			local normalTexture = NecrosisShadowTranceButton:GetNormalTexture()
			if normalTexture then
				normalTexture:SetAllPoints(NecrosisShadowTranceButton)
			end
			local pushedTexture = NecrosisShadowTranceButton:GetPushedTexture()
			if pushedTexture then
				pushedTexture:SetAllPoints(NecrosisShadowTranceButton)
			end
			local highlightTexture = NecrosisShadowTranceButton:GetHighlightTexture()
			if highlightTexture then
				highlightTexture:SetAllPoints(NecrosisShadowTranceButton)
				highlightTexture:SetBlendMode("ADD")
			end
		end
		ShowUIPanel(NecrosisShadowTranceButton)
	end

	if hasShadowTrance and ShadowState.active then
		local buffIndex = GetPlayerBuff(buffId, SHADOW_TRANCE_BUFF_FLAGS)
		if buffIndex and buffIndex ~= -1 then
			local timeLeft = GetPlayerBuffTimeLeft(buffIndex) or 0
			local seconds = floor(timeLeft)
			if seconds < 0 then
				seconds = 0
			end
			if seconds ~= ShadowState.remaining then
				ShadowState.remaining = seconds
				NecrosisShadowTranceTimer:SetText(seconds)
			end
		else
			if ShadowState.remaining ~= nil then
				ShadowState.remaining = nil
				NecrosisShadowTranceTimer:SetText("")
			end
		end
	elseif ShadowState.active then
		HideUIPanel(NecrosisShadowTranceButton)
		ShadowState.active = false
		if ShadowState.remaining ~= nil then
			ShadowState.remaining = nil
			NecrosisShadowTranceTimer:SetText("")
		end
	end

	local interval = ShadowState.active and 0.1 or 0.25
	ShadowState.nextUpdate = curTime + interval
end

local function Necrosis_UpdateAntiFear(curTime)
	local status = Necrosis_GetCachedTargetFearStatus()

	if not configCache.antiFearAlert then
		if AntiFearState.inUse then
			AntiFearState.inUse = false
			AntiFearState.blink1 = 0
			AntiFearState.blink2 = 0
			HideUIPanel(NecrosisAntiFearButton)
		end
		return
	end

	if status ~= 0 then
		if not AntiFearState.inUse then
			AntiFearState.inUse = true
			local message = Loc.GetMessage and Loc:GetMessage("Information", "FearProtect")
			if message then
				Necrosis_Msg(message, "USER")
			end
			if NecrosisConfig.Sound and NECROSIS_SOUND and NECROSIS_SOUND.Fear then
				PlaySoundFile(NECROSIS_SOUND.Fear)
			end
			Necrosis_SetNormalTextureIfDifferent(NecrosisAntiFearButton, getAntiFearTexture(status, 2))
			ShowUIPanel(NecrosisAntiFearButton)
			AntiFearState.blink1 = curTime + 0.6
			AntiFearState.blink2 = 2
		elseif curTime >= (AntiFearState.blink1 or 0) then
			if AntiFearState.blink2 == 1 then
				AntiFearState.blink2 = 2
			else
				AntiFearState.blink2 = 1
			end
			AntiFearState.blink1 = curTime + 0.4
			Necrosis_SetNormalTextureIfDifferent(
				NecrosisAntiFearButton,
				getAntiFearTexture(status, AntiFearState.blink2 or 2)
			)
		end
	elseif AntiFearState.inUse then
		AntiFearState.inUse = false
		AntiFearState.blink1 = 0
		AntiFearState.blink2 = 0
		HideUIPanel(NecrosisAntiFearButton)
	end
end

-- Flag to schedule spell setup for next OnUpdate tick
local spellSetupScheduled = false

function Necrosis_ScheduleSpellSetup()
	spellSetupScheduled = true
end

function Necrosis_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		InitState.inWorld = true
		return
	elseif event == "PLAYER_LEAVING_WORLD" then
		InitState.inWorld = false
		return
	end

	if (not Necrosis_IsLoaded()) or not InitState.inWorld or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	Dispatcher:Fire(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end

-- Function executed on UI updates (roughly every 0.1 seconds)
function Necrosis_OnUpdate(self, elapsed)
	if (not Necrosis_IsLoaded()) and UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	-- Execute scheduled spell setup after initialization completes
	if spellSetupScheduled then
		spellSetupScheduled = false
		Necrosis_SpellSetup()
		-- Rebuild menus and buttons now that spell data is loaded
		Necrosis_CreateMenu()
		Necrosis_ButtonSetup()
	end

	elapsed = elapsed or 0
	Necrosis_TrackUpdateDiagnostics(elapsed)

	local diagActive = configCache.diagnosticsEnabled
	local curTime = GetTime()

	if NecrosisTimerEventsDirty then
		local before = diagActive and debugprofilestop()
		Necrosis_UpdateTimerEventRegistration()
		if before then
			Necrosis_RecordHelperDiag("UpdateTimerEventRegistration", before)
		end
	end

	before = diagActive and debugprofilestop()
	Necrosis_UpdateSoulShardSorting(elapsed)
	if before then
		Necrosis_RecordHelperDiag("UpdateSoulShardSorting", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_ProcessBagUpdates(curTime)
	if before then
		Necrosis_RecordHelperDiag("ProcessBagUpdates", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_UpdateTrackedBuffTimers(elapsed, curTime)
	if before then
		Necrosis_RecordHelperDiag("UpdateTrackedBuffTimers", before)
	end

	if Necrosis_ShouldUpdateMenus() then
		local before = diagActive and debugprofilestop()
		Necrosis_UpdateMenus(curTime)
		if before then
			Necrosis_RecordHelperDiag("UpdateMenus", before)
		end
	end

	local before = diagActive and debugprofilestop()
	Necrosis_UpdateShadowTrance(curTime)
	if before then
		Necrosis_RecordHelperDiag("UpdateShadowTrance", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_UpdateAntiFear(curTime)
	if before then
		Necrosis_RecordHelperDiag("UpdateAntiFear", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_HandleShardCount()
	if before then
		Necrosis_RecordHelperDiag("HandleShardCount", before)
	end

	before = diagActive and debugprofilestop()
	local shouldUpdate = Necrosis_ShouldUpdateSpellState(curTime)
	if before then
		Necrosis_RecordHelperDiag("ShouldUpdateSpellState", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_HandleTradingAndIcons(shouldUpdate)
	if before then
		Necrosis_RecordHelperDiag("HandleTradingAndIcons", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	if before then
		Necrosis_RecordHelperDiag("UpdateSpellTimers", before)
	end

	before = diagActive and debugprofilestop()
	Necrosis_UpdateTimerDisplay()
	if before then
		Necrosis_RecordHelperDiag("UpdateTimerDisplay", before)
	end
end
