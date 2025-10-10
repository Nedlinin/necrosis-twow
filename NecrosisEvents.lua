------------------------------------------------------------------------------------------------------
-- Necrosis Event Wiring
------------------------------------------------------------------------------------------------------

local floor = math.floor

local SHADOW_TRANCE_BUFF_FLAGS = "HELPFUL|HARMFUL|PASSIVE"
local ANTI_FEAR_TEXTURE_BASE = "Interface\\AddOns\\Necrosis\\UI\\AntiFear"
local ANTI_FEAR_TEXTURE_SUFFIXES = { "", "Immu", "Prot" }
local ANTI_FEAR_TEXTURE_VARIANTS = {}

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

NECROSIS_EVENT_HANDLERS = {
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
	if not NecrosisConfig.ShadowTranceAlert then
		return
	end

	Necrosis_UnitHasTrance()
	local buffId = ShadowState.buffId or -1
	local hasShadowTrance = buffId ~= -1

	if hasShadowTrance and not ShadowState.active then
		ShadowState.active = true
		ShadowState.remaining = nil
		if NECROSIS_NIGHTFALL_TEXT and NECROSIS_NIGHTFALL_TEXT.Message then
			Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.Message, "USER")
		end
		if NecrosisConfig.Sound and NECROSIS_SOUND and NECROSIS_SOUND.ShadowTrance then
			PlaySoundFile(NECROSIS_SOUND.ShadowTrance)
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
end

local function Necrosis_UpdateAntiFear(curTime)
	if not NecrosisConfig.AntiFearAlert then
		return
	end

	local status = 0
	if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
		if not UnitIsPlayer("target") then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_UNIT), 1 do
				if UnitCreatureType("target") == NECROSIS_ANTI_FEAR_UNIT[index] then
					status = 2
					break
				end
			end
		end
		if status == 0 then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Buff), 1 do
				if Necrosis_UnitHasBuff("target", NECROSIS_ANTI_FEAR_SPELL.Buff[index]) then
					status = 3
					break
				end
			end
		end
		if status == 0 then
			for index = 1, table.getn(NECROSIS_ANTI_FEAR_SPELL.Debuff), 1 do
				if Necrosis_UnitHasEffect("target", NECROSIS_ANTI_FEAR_SPELL.Debuff[index]) then
					status = 3
					break
				end
			end
		end
		if status == 0 and AntiFearState.currentTargetImmune then
			status = 1
		end
	end

	if status ~= 0 then
		if not AntiFearState.inUse then
			AntiFearState.inUse = true
			if NECROSIS_MESSAGE and NECROSIS_MESSAGE.Information and NECROSIS_MESSAGE.Information.FearProtect then
				Necrosis_Msg(NECROSIS_MESSAGE.Information.FearProtect, "USER")
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

function Necrosis_OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		Necrosis_In = true
		return
	elseif event == "PLAYER_LEAVING_WORLD" then
		Necrosis_In = false
		return
	end

	if (not Loaded) or not Necrosis_In or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	local handler = NECROSIS_EVENT_HANDLERS[event]
	if handler then
		handler(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
	end
end

-- Function executed on UI updates (roughly every 0.1 seconds)
function Necrosis_OnUpdate(self, elapsed)
	if (not Loaded) and UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		return
	end

	elapsed = elapsed or 0
	Necrosis_UpdateTimerEventRegistration()

	local curTime = GetTime()

	Necrosis_UpdateSoulShardSorting(elapsed)
	Necrosis_ProcessBagUpdates(curTime)
	Necrosis_UpdateTrackedBuffTimers(elapsed, curTime)
	Necrosis_UpdateMenus(curTime)
	Necrosis_UpdateShadowTrance(curTime)
	Necrosis_UpdateAntiFear(curTime)
	Necrosis_HandleShardCount()

	local shouldUpdate = Necrosis_ShouldUpdateSpellState(curTime)
	Necrosis_HandleTradingAndIcons(shouldUpdate)
	Necrosis_UpdateSpellTimers(curTime, shouldUpdate)
	Necrosis_UpdateTimerDisplay()
end
