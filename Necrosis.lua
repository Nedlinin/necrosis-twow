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

-- Default configuration
-- Loaded when no configuration is found or when the version changes
Default_NecrosisConfig = {
	Version = NecrosisData.Version,
	SoulshardContainer = 4,
	SoulshardSort = false,
	SoulshardDestroy = false,
	ShadowTranceAlert = true,
	ShowSpellTimers = true,
	AntiFearAlert = true,
	NecrosisLockServ = true,
	NecrosisAngle = 180,
	StonePosition = { true, true, true, true, true, true, true, true },
	NecrosisToolTip = true,
	NoDragAll = false,
	PetMenuPos = 34,
	BuffMenuPos = 34,
	CurseMenuPos = 34,
	StoneMenuPos = 34,
	ChatMsg = true,
	ChatType = true,
	NecrosisLanguage = GetLocale(),
	ShowCount = true,
	CountType = 1,
	ShadowTranceScale = 100,
	NecrosisButtonScale = 90,
	NecrosisColor = "Rose",
	Sound = true,
	SpellTimerPos = 1,
	SpellTimerJust = "LEFT",
	Circle = 1,
	Graphical = true,
	Yellow = true,
	SensListe = 1,
	DebugTimers = false,
	DiagnosticsEnabled = false,
	PetName = {
		[1] = " ",
		[2] = " ",
		[3] = " ",
		[4] = " ",
	},
	DominationUp = false,
	AmplifyUp = false,
	SM = false, -- short messages
	SteedSummon = false,
	DemonSummon = true,
	RitualMessage = true,
	BanishScale = 100,
}

NecrosisConfig = {}
local Debug = false
local function Necrosis_IsTimerDebugEnabled()
	if Debug then
		return true
	end
	if DEBUG_TIMER_EVENTS then
		return true
	end
	if type(NecrosisConfig) == "table" and NecrosisConfig.DebugTimers then
		return true
	end
	return false
end

function Necrosis_DebugPrint(...)
	if not Necrosis_IsTimerDebugEnabled() then
		return
	end
	local params = arg
	if not params or params.n == 0 then
		return
	end
	local parts = {}
	for index = 1, params.n do
		local value = params[index]
		if value == nil then
			parts[index] = "<nil>"
		else
			parts[index] = tostring(value)
		end
	end
	local message = table.concat(parts, " ")
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	else
		print(message)
	end
end

local Loaded = false

-- Detect mod initialization
local NecrosisRL = true

-- Initialize variables used by Necrosis to manage spell casts
local SpellCastName = nil
local SpellCastRank = nil
local SpellTargetName = nil
local SpellCastTime = 0

local TIMER_TYPE = NECROSIS_TIMER_TYPE
local InventoryConfig = NecrosisInventoryConfig

local function getTimerService()
	return NecrosisTimerService
end

local function getState(slice)
	return Necrosis.GetStateSlice(slice)
end

local function getInventory(slice)
	return Necrosis.GetInventorySlice(slice)
end

local LastCast = Necrosis.GetLastCast()
local SoulshardState = getState("soulshards")
local ComponentState = getState("components")
local CombatState = getState("combat")
local MountState = getState("mount")
local TradeState = getState("trade")
local AntiFearState = getState("antiFear")
local ShadowState = getState("shadowTrance")
local MessageState = getState("messages")
local StoneInventory = getInventory("stones")

-- Clears contents but preserves subtable objects
local function clear_tables(t)
	for k, v in pairs(t) do
		if type(v) == "table" then
			-- recurse: empty the subtable
			clear_tables(v)
		else
			-- remove only non-table values
			t[k] = nil
		end
	end
end

local UpdateDiagnostics = {
	lastLogTime = 0,
	frameCount = 0,
	elapsedTotal = 0,
	helpers = {},
}

local function Necrosis_LogDiagnostics(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

function Necrosis_RecordHelperDiag(name, beforeMem)
	if not (NecrosisConfig and NecrosisConfig.DiagnosticsEnabled) then
		return
	end
	local afterMem = gcinfo()
	local delta = afterMem - beforeMem
	local helper = UpdateDiagnostics.helpers[name]
	if not helper then
		helper = { calls = 0, mem = 0 }
		UpdateDiagnostics.helpers[name] = helper
	end
	helper.calls = helper.calls + 1
	helper.mem = helper.mem + delta
end

function Necrosis_TrackUpdateDiagnostics(elapsed)
	if not (NecrosisConfig and NecrosisConfig.DiagnosticsEnabled) then
		UpdateDiagnostics.lastLogTime = GetTime()
		UpdateDiagnostics.frameCount = 0
		UpdateDiagnostics.elapsedTotal = 0
		UpdateDiagnostics.helpers = {}
		return
	end

	elapsed = elapsed or 0
	local now = GetTime()
	if UpdateDiagnostics.lastLogTime == 0 then
		UpdateDiagnostics.lastLogTime = now
	end
	UpdateDiagnostics.frameCount = UpdateDiagnostics.frameCount + 1
	UpdateDiagnostics.elapsedTotal = UpdateDiagnostics.elapsedTotal + elapsed

	if (now - UpdateDiagnostics.lastLogTime) < 5 then
		return
	end

	local avgElapsed = 0
	if UpdateDiagnostics.frameCount > 0 then
		avgElapsed = UpdateDiagnostics.elapsedTotal / UpdateDiagnostics.frameCount
	end

	local memUsage = gcinfo()
	local pendingScan = BagState and BagState.pending and "true" or "false"
	local timerEngine = _G.TimerEngine
	local segmentCount = timerEngine and timerEngine.textSegments and table.getn(timerEngine.textSegments) or 0
	local service = getTimerService()
	local timerCount = service and service:GetTimerCount() or 0

	local message = string.format(
		"|cffff7f00Necrosis|r OnUpdate %d frames, avg %.3f ms, mem %.1f KB, bagPending=%s, segments=%d, timers=%d",
		UpdateDiagnostics.frameCount,
		avgElapsed * 1000,
		memUsage,
		pendingScan,
		segmentCount,
		timerCount
	)
	Necrosis_LogDiagnostics(message)

	for name, data in pairs(UpdateDiagnostics.helpers) do
		local avgMem = 0
		if data.calls > 0 then
			avgMem = data.mem / data.calls
		end
		Necrosis_LogDiagnostics(
			string.format("  - %s: calls=%d, total=%.3f KB, avg=%.3f KB", name, data.calls, data.mem, avgMem)
		)
	end

	UpdateDiagnostics.lastLogTime = now
	UpdateDiagnostics.frameCount = 0
	UpdateDiagnostics.elapsedTotal = 0
	UpdateDiagnostics.helpers = {}
end

local ICON_BASE_PATH = "Interface\\AddOns\\Necrosis\\UI\\"
local ACCENT_RING_TEXTURE = ICON_BASE_PATH .. "AccentRing"

local ICON_ACCENT_COLORS = {
	Agony = { 0.4656, 0.4655, 0.4655 },
	Amplify = { 0.2623, 0.2623, 0.2623 },
	Aqua = { 0.4678, 0.4678, 0.4678 },
	ArmureDemo = { 0.2955, 0.2952, 0.2953 },
	Banish = { 0.4772, 0.4775, 0.4783 },
	Domination = { 0.3429, 0.3429, 0.3429 },
	Doom = { 0.2978, 0.2977, 0.2977 },
	Doomguard = { 0.3490, 0.3490, 0.3490 },
	Elements = { 0.3217, 0.3216, 0.3216 },
	Enslave = { 0.3878, 0.3878, 0.3881 },
	Exhaust = { 0.3205, 0.3205, 0.3205 },
	Felhunter = { 0.2852, 0.2825, 0.2816 },
	Felstone = { 0.3590, 0.5627, 0.2030 },
	FirestoneButton = { 0.8148, 0.3459, 0.5506 },
	HealthstoneButton = { 0.2921, 0.7151, 0.2921 },
	Imp = { 0.3634, 0.3649, 0.3521 },
	Infernal = { 0.4980, 0.4980, 0.4980 },
	Invisible = { 0.5955, 0.5955, 0.5955 },
	Kilrogg = { 0.3402, 0.3402, 0.3402 },
	Lien = { 0.4047, 0.4047, 0.4047 },
	MountButton = { 0.3368, 0.3336, 0.3327 },
	Radar = { 0.3104, 0.3104, 0.3104 },
	Reckless = { 0.3942, 0.3941, 0.3941 },
	Sacrifice = { 0.3967, 0.3967, 0.3967 },
	Shadow = { 0.4189, 0.4188, 0.4188 },
	["ShadowTrance-Icon"] = { 0.4173, 0.2913, 0.4487 },
	ShadowWard = { 0.2620, 0.2620, 0.2620 },
	SoulstoneButton = { 0.5463, 0.2720, 0.5324 },
	SpellstoneButton = { 0.2844, 0.4891, 0.8284 },
	Succubus = { 0.3056, 0.3053, 0.3055 },
	Tongues = { 0.3034, 0.3034, 0.3034 },
	Voidstone = { 0.2820, 0.1570, 0.5112 },
	Voidwalker = { 0.1769, 0.1775, 0.1825 },
	Weakness = { 0.3441, 0.3440, 0.3440 },
	Wrathstone = { 0.5331, 0.1212, 0.1892 },
}

local HANDLED_ICON_BASES = {}
for name in pairs(ICON_ACCENT_COLORS) do
	HANDLED_ICON_BASES[name] = true
end
HANDLED_ICON_BASES.SoulstoneButton = true
HANDLED_ICON_BASES.SpellstoneButton = true
HANDLED_ICON_BASES.HealthstoneButton = true

local function Necrosis_AttachRing(button)
	if button.NecrosisAccentRing then
		button.NecrosisAccentRing:Show()
		return button.NecrosisAccentRing
	end
	local ring = button:CreateTexture(nil, "OVERLAY")
	ring:SetTexture(ACCENT_RING_TEXTURE)
	ring:SetAllPoints(button)
	ring:SetVertexColor(0.66, 0.66, 0.66)
	ring:SetBlendMode("ADD")
	button.NecrosisAccentRing = ring
	ring:Show()
	return ring
end

function Necrosis_SetNormalTextureIfDifferent(button, texturePath)
	if not button or not texturePath then
		return
	end
	if button.NecrosisCurrentTexture == texturePath then
		return
	end
	button.SetNormalTexture(button, texturePath)
	button.NecrosisCurrentTexture = texturePath
end

function Necrosis_SetButtonTexture(button, base, variant)
	if not button or not base then
		return
	end
	local numberVariant = tonumber(variant) or variant or 2
	if
		button.NecrosisIconBase == base
		and button.NecrosisTextureVariant
		and button.NecrosisTextureVariant == numberVariant
	then
		return
	end
	if not HANDLED_ICON_BASES[base] then
		local texturePath = ICON_BASE_PATH .. base .. "-0" .. numberVariant
		Necrosis_SetNormalTextureIfDifferent(button, texturePath)
		button.NecrosisIconBase = base
		button.NecrosisTextureVariant = numberVariant
		return
	end
	local texturePath = ICON_BASE_PATH .. base .. ".tga"
	Necrosis_SetNormalTextureIfDifferent(button, texturePath)
	local icon = button:GetNormalTexture()
	button.NecrosisIconBase = base
	button.NecrosisTextureVariant = numberVariant
	icon:SetVertexColor(1, 1, 1)
	local ring = Necrosis_AttachRing(button)
	if ring then
		ring:SetTexture(ACCENT_RING_TEXTURE)
		ring:SetAllPoints(button)
		ring:SetBlendMode("ADD")
		ring:Show()
	end
	if numberVariant == 1 then
		icon:SetVertexColor(0.35, 0.35, 0.35)
		ring:SetVertexColor(0.35, 0.35, 0.35)
	elseif numberVariant == 3 then
		ring:SetVertexColor(unpack(ICON_ACCENT_COLORS[base] or { 0.66, 0.66, 0.66 }))
	else
		ring:SetVertexColor(0.66, 0.66, 0.66)
	end
end

local MENU_BUTTON_COUNT = 9

local function Necrosis_OnBagUpdate()
	if NecrosisConfig.SoulshardSort then
		SoulshardState.pendingSortCheck = true
	end
	Necrosis_RequestBagScan(0)
end

local function Necrosis_HandleSelfBuffCast(spellIndex, activeSpellName, playerName, currentTime)
	if not spellIndex or not activeSpellName then
		return false
	end

	local data = NECROSIS_SPELL_TABLE[spellIndex]
	if not data or not data.Name then
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("Buff timer", "no spell data", spellIndex)
		end
		return false
	end

	if data.Name ~= activeSpellName then
		if DEBUG_TIMER_EVENTS then
			Necrosis_DebugPrint("Buff timer", "spell mismatch", activeSpellName or "nil", "!=", data.Name)
		end
		return false
	end

	local duration = data.Length or 0
	if duration <= 0 then
		return false
	end

	local expiry = floor(currentTime + duration)

	return Necrosis_TouchSelfBuffTimer(
		spellIndex,
		data.Name,
		playerName,
		duration,
		expiry,
		data.Type,
		duration,
		false,
		currentTime
	)
end

local function Necrosis_CountTableEntries(tbl)
	if type(tbl) ~= "table" then
		return 0
	end
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function Necrosis_PrintDiagnostic(line)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffNecrosis:|r " .. line)
	else
		print("Necrosis: " .. line)
	end
end

local function Necrosis_FormatTimerEntry(timer)
	if not timer then
		return "nil"
	end
	local remaining = 0
	if timer.TimeMax then
		remaining = timer.TimeMax - GetTime()
	end
	if remaining < 0 then
		remaining = 0
	end
	return string.format(
		"%s @ %s (%.1fs, type=%s)",
		timer.Name or "?",
		timer.Target or "-",
		remaining,
		tostring(timer.Type)
	)
end

function Necrosis_DumpDiagnostics()
	Necrosis_PrintDiagnostic("Diagnostics snapshot")
	Necrosis_PrintDiagnostic(
		string.format(
			"  Soulshards: count=%d, container=%d, pendingMoves=%d, sortCheck=%s",
			SoulshardState.count or 0,
			SoulshardState.container or -1,
			SoulshardState.pendingMoves or 0,
			tostring(SoulshardState.pendingSortCheck)
		)
	)
	Necrosis_PrintDiagnostic(
		string.format(
			"  Components: infernal=%d, demoniac=%d",
			ComponentState.infernal or 0,
			ComponentState.demoniac or 0
		)
	)
	local stoneKeys = (InventoryConfig and InventoryConfig:GetStoneKeys()) or {}
	for index = 1, table.getn(stoneKeys) do
		local key = stoneKeys[index]
		local data = StoneInventory[key]
		if data then
			local loc = "-"
			if type(data.location) == "table" and data.location[1] then
				loc = string.format("%d,%d", data.location[1] or -1, data.location[2] or -1)
			end
			Necrosis_PrintDiagnostic(
				string.format(
					"  Stone[%s]: onHand=%s, mode=%s, loc=%s",
					key,
					tostring(data.onHand),
					tostring(data.mode),
					loc
				)
			)
		end
	end
	if StoneInventory.Itemswitch then
		local data = StoneInventory.Itemswitch
		local loc = "-"
		if type(data.location) == "table" and data.location[1] then
			loc = string.format("%d,%d", data.location[1] or -1, data.location[2] or -1)
		end
		Necrosis_PrintDiagnostic(string.format("  Offhand swap: onHand=%s, loc=%s", tostring(data.onHand), loc))
	end
	if SoulstoneUsedOnTarget then
		Necrosis_PrintDiagnostic("  Soulstone queued for target notification")
	end

	local service = getTimerService()
	local timerCount = service and service:GetTimerCount() or 0
	if service and timerCount > 0 then
		Necrosis_PrintDiagnostic(string.format("  SpellTimers: %d entries", timerCount))
		service:IterateTimers(function(timer)
			if timer then
				Necrosis_PrintDiagnostic("    " .. Necrosis_FormatTimerEntry(timer))
			end
		end)
	else
		Necrosis_PrintDiagnostic("  SpellTimers: <nil>")
	end

	local function summarizeMenu(name, menu)
		if type(menu) ~= "table" then
			return string.format("  Menu[%s]: <nil>", name)
		end
		return string.format(
			"  Menu[%s]: alpha=%.2f, sticky=%s, fadeAt=%.2f, frames=%d",
			name,
			menu.alpha or 0,
			tostring(menu.sticky),
			menu.fadeAt or 0,
			Necrosis_CountTableEntries(menu.frames)
		)
	end

	if MenuState then
		Necrosis_PrintDiagnostic(summarizeMenu("Pet", MenuState.Pet))
		Necrosis_PrintDiagnostic(summarizeMenu("Buff", MenuState.Buff))
		Necrosis_PrintDiagnostic(summarizeMenu("Curse", MenuState.Curse))
		Necrosis_PrintDiagnostic(summarizeMenu("Stone", MenuState.Stone))
	end

	Necrosis_PrintDiagnostic(
		string.format(
			"  TradeState: requested=%s, active=%s, countdown=%d",
			tostring(TradeState.requested),
			tostring(TradeState.active),
			TradeState.countdown or 0
		)
	)
	Necrosis_PrintDiagnostic("Diagnostics complete")
end

function Necrosis_ToggleDiagnostics()
	NecrosisConfig.DiagnosticsEnabled = not NecrosisConfig.DiagnosticsEnabled
	if NecrosisConfig.DiagnosticsEnabled then
		Necrosis_PrintDiagnostic("Diagnostics enabled")
		Necrosis_DumpDiagnostics()
	else
		Necrosis_PrintDiagnostic("Diagnostics disabled")
	end
end

local function Necrosis_OnSpellcastStart(spellName)
	Necrosis_DebugPrint("SPELLCAST_START", spellName or "nil")
	SpellCastName = spellName
	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end

	local playerName = UnitName("player") or ""
	local now = GetTime()

	if not Necrosis_HandleSelfBuffCast(31, spellName, playerName, now) then
		Necrosis_HandleSelfBuffCast(36, spellName, playerName, now)
	end
end

local function Necrosis_ClearSpellcastContext()
	SpellCastName = nil
	SpellCastRank = nil
	SpellTargetName = nil
end

local function Necrosis_SetTradeRequest(active)
	TradeState.requested = active
end

function Necrosis_ShouldUpdateSpellState(curTime)
	if (curTime - SpellCastTime) < 1 then
		return false
	end
	SpellCastTime = curTime
	return true
end

local function Necrosis_OnTargetChanged()
	if NecrosisConfig.AntiFearAlert and AntiFearState.currentTargetImmune then
		AntiFearState.currentTargetImmune = false
	end
end

local function Necrosis_HandleSelfFearDamage(message)
	if not NecrosisConfig.AntiFearAlert or not message then
		return
	end
	for spell, creatureName in string.gfind(message, NECROSIS_ANTI_FEAR_SRCH) do
		if spell == NECROSIS_SPELL_TABLE[13].Name or spell == NECROSIS_SPELL_TABLE[19].Name then
			AntiFearState.currentTargetImmune = true
			break
		end
	end
end

local function Necrosis_OnSpellLearned()
	Necrosis_SpellSetup()
	Necrosis_CreateMenu()
	Necrosis_ButtonSetup()
end

local function Necrosis_OnCombatEnd()
	CombatState.inCombat = false
	local service = getTimerService()
	if service then
		service:RemoveCombatTimers()
	end
end

function Necrosis_OnLoad()
	Necrosis_Hook("UseAction", "Necrosis_UseAction", "before")
	Necrosis_Hook("CastSpell", "Necrosis_CastSpell", "before")
	Necrosis_Hook("CastSpellByName", "Necrosis_CastSpellByName", "before")

	if NecrosisButton then
		NecrosisButton:RegisterEvent("PLAYER_ENTERING_WORLD")
		NecrosisButton:RegisterEvent("PLAYER_LEAVING_WORLD")
		if type(NECROSIS_EVENT_HANDLERS) == "table" then
			for eventName in pairs(NECROSIS_EVENT_HANDLERS) do
				NecrosisButton:RegisterEvent(eventName)
			end
		end
		NecrosisButton:RegisterForDrag("LeftButton")
		NecrosisButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		NecrosisButton:SetFrameLevel(1)
	end
end

function Necrosis_LoadVariables()
	if Loaded or UnitClass("player") ~= NECROSIS_UNIT_WARLOCK then
		local variablesFrame = getglobal("Necrosis_Variable_Frame")
		if variablesFrame then
			variablesFrame:SetScript("OnUpdate", nil)
		end
		return
	end

	Necrosis_Initialize()
	Loaded = true
	DemonType = UnitCreatureFamily("pet")

	local variablesFrame = getglobal("Necrosis_Variable_Frame")
	if variablesFrame then
		variablesFrame:SetScript("OnUpdate", nil)
	end
end

------------------------------------------------------------------------------------------------------
-- NECROSIS FUNCTIONS "ON EVENT"
------------------------------------------------------------------------------------------------------

function Necrosis_ChangeDemon()
	local timerService = getTimerService()
	-- If the new demon is enslaved, start a five-minute timer
	if Necrosis_UnitHasEffect("pet", NECROSIS_SPELL_TABLE[10].Name) then
		if not DemonEnslaved then
			DemonEnslaved = true
			if timerService then
				timerService:EnsureSpellIndexTimer(10, nil, nil, nil, nil, nil)
			end
		end
	else
		-- When the enslaved demon breaks free, remove the timer and warn the Warlock
		if DemonEnslaved then
			DemonEnslaved = false
			if timerService then
				timerService:RemoveTimerByName(NECROSIS_SPELL_TABLE[10].Name)
			end
			if NecrosisConfig.Sound then
				PlaySoundFile(NECROSIS_SOUND.EnslaveEnd)
			end
			Necrosis_Msg(NECROSIS_MESSAGE.Information.EnslaveBreak, "USER")
		end
	end

	-- If the demon is not enslaved, assign its title and update its name in Necrosis
	DemonType = UnitCreatureFamily("pet")
	for i = 1, 4, 1 do
		if
			DemonType == NECROSIS_PET_LOCAL_NAME[i]
			and NecrosisConfig.PetName[i] == " "
			and UnitName("pet") ~= UNKNOWNOBJECT
		then
			NecrosisConfig.PetName[i] = UnitName("pet")
			NecrosisLocalization()
			break
		end
	end

	return
end

-- events: CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS, CHAT_MSG_SPELL_AURA_GONE_SELF, and CHAT_MSG_SPELL_BREAK_AURA
-- Handles buffs and debuffs appearing on the Warlock
-- Based on the combat log
function Necrosis_SelfEffect(action)
	Necrosis_DebugPrint("SelfEffect", action, arg1 or "nil")
	local timerService = getTimerService()
	if action == "BUFF" then
		-- Insert a timer when the Warlock gains Demon Sacrifice
		if arg1 == NECROSIS_TRANSLATION.SacrificeGain and timerService then
			timerService:EnsureSpellIndexTimer(17, nil, nil, nil, nil, nil)
		end
		-- Update the mount button when the Warlock mounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			MountState.active = true
			if
				NecrosisConfig.SteedSummon
				and MountState.notify
				and NecrosisConfig.ChatMsg
				and NECROSIS_PET_MESSAGE[6]
				and not NecrosisConfig.SM
			then
				local mountMessages = NECROSIS_PET_MESSAGE[6]
				local messageCount = table.getn(mountMessages)
				if messageCount > 0 then
					local tempnum = random(1, messageCount)
					if messageCount >= 2 then
						while tempnum == MessageState.steed do
							tempnum = random(1, messageCount)
						end
					end
					MessageState.steed = tempnum
					local lines = mountMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY")
					end
					MountState.notify = false
				end
			end
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 2)
		end
		-- Update the Corrupted Domination button when active and start the cooldown timer
		if string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = true
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 2)
		end
		-- Update the Amplify Curse button when active and start the cooldown timer
		if string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = true
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 2)
		end
		-- Track Demon Armor/Skin on the player
		local playerName = UnitName("player") or ""
		if NECROSIS_SPELL_TABLE[31].Name and string.find(arg1, NECROSIS_SPELL_TABLE[31].Name) then
			local skip = Necrosis_WasBuffRecentlyRefreshed(NECROSIS_SPELL_TABLE[31].Name)
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("SelfEffect", "Demon Armor aura", "skip=", skip)
			end
			if not skip and timerService then
				timerService:EnsureSpellIndexTimer(31, playerName, nil, nil, nil, nil)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Armor timer (log)")
				end
			end
			LastRefreshedBuffName = nil
		elseif NECROSIS_SPELL_TABLE[36].Name and string.find(arg1, NECROSIS_SPELL_TABLE[36].Name) then
			local skip = Necrosis_WasBuffRecentlyRefreshed(NECROSIS_SPELL_TABLE[36].Name)
			if DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("SelfEffect", "Demon Skin aura", "skip=", skip)
			end
			if not skip and timerService then
				timerService:EnsureSpellIndexTimer(36, playerName, nil, nil, nil, nil)
				if DEBUG_TIMER_EVENTS then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Skin timer (log)")
				end
			end
			LastRefreshedBuffName = nil
		else
			local trackedConfig = Necrosis_FindTrackedBuffConfigByName(arg1)
			if trackedConfig and not trackedConfig.spellIndex then
				Necrosis_RefreshSelfBuffTimer(trackedConfig, playerName, GetTime())
				LastRefreshedBuffName = nil
			end
		end
	else
		-- Update the mount button when the Warlock dismounts
		if string.find(arg1, NECROSIS_SPELL_TABLE[1].Name) or string.find(arg1, NECROSIS_SPELL_TABLE[2].Name) then
			MountState.active = false
			MountState.notify = true
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
		end
		-- Change the Domination button when the Warlock is no longer under its effect
		if string.find(arg1, NECROSIS_SPELL_TABLE[15].Name) and NECROSIS_SPELL_TABLE[15].ID ~= nil then
			DominationUp = false
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
		-- Change the Amplify Curse button when the Warlock leaves its effect
		if string.find(arg1, NECROSIS_SPELL_TABLE[42].Name) and NECROSIS_SPELL_TABLE[42].ID ~= nil then
			AmplifyUp = false
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
		end
		-- Remove tracked buff timers when they fade
		if not Necrosis_RemoveTrackedBuffTimerForMessage(arg1) and timerService then
			if NECROSIS_SPELL_TABLE[31].Name and string.find(arg1, NECROSIS_SPELL_TABLE[31].Name) then
				timerService:RemoveTimerByName(NECROSIS_SPELL_TABLE[31].Name)
			elseif NECROSIS_SPELL_TABLE[36].Name and string.find(arg1, NECROSIS_SPELL_TABLE[36].Name) then
				timerService:RemoveTimerByName(NECROSIS_SPELL_TABLE[36].Name)
			end
		end
	end
	return
end

-- event : SPELLCAST_STOP
-- Handles everything related to spells after they finish casting
function Necrosis_SpellManagement()
	local SortActif = false
	local timerService = getTimerService()
	Necrosis_DebugPrint(
		"Necrosis_SpellManagement",
		"SpellCastName=",
		SpellCastName or "nil",
		"Target=",
		SpellTargetName or "nil"
	)
	if SpellCastName then
		-- If the spell was Soulstone Resurrection, start its timer
		if SpellCastName == NECROSIS_SPELL_TABLE[11].Name then
			if SpellTargetName == UnitName("player") then
				SpellTargetName = ""
			end
			-- If messaging is enabled and the stone is used on the targeted player, broadcast the alert!
			if (NecrosisConfig.ChatMsg or NecrosisConfig.SM) and SoulstoneUsedOnTarget then
				SoulstoneTarget = SpellTargetName
				SoulstoneAdvice = true
			end
			if timerService then
				timerService:EnsureSpellIndexTimer(11, SpellTargetName, nil, nil, nil, nil)
			end
		-- If the spell was Ritual of Summoning, send an informational message to players
		elseif
			(SpellCastName == NECROSIS_TRANSLATION.SummoningRitual)
			and (NecrosisConfig.ChatMsg or NecrosisConfig.SM)
			and NecrosisConfig.RitualMessage
			and NECROSIS_INVOCATION_MESSAGES
		then
			local ritualMessages = NECROSIS_INVOCATION_MESSAGES
			local ritualCount = table.getn(ritualMessages)
			if ritualCount > 0 then
				local tempnum = random(1, ritualCount)
				if ritualCount >= 2 then
					while tempnum == MessageState.tp do
						tempnum = random(1, ritualCount)
					end
				end
				MessageState.tp = tempnum
				local lines = ritualMessages[tempnum]
				local lineCount = table.getn(lines)
				for i = 1, lineCount, 1 do
					Necrosis_Msg(Necrosis_MsgReplace(lines[i], SpellTargetName), "WORLD")
				end
			end
		elseif StoneIDInSpellTable[5] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Name then -- Create Felstone
			LastCast.Stone.id = 1
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[6] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Name then -- Create Wrathstone
			LastCast.Stone.id = 2
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[7] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Name then -- Create Voidstone
			LastCast.Stone.id = 3
			LastCast.Stone.click = "LeftButton"
		elseif StoneIDInSpellTable[4] ~= 0 and SpellCastName == NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Name then -- Create Firestone
			LastCast.Stone.id = 4
			LastCast.Stone.click = "LeftButton"
		-- For other spells, attempt to create a timer if applicable
		elseif SpellCastName == NECROSIS_SPELL_TABLE[31].Name or SpellCastName == NECROSIS_SPELL_TABLE[36].Name then
			local playerName = UnitName("player") or ""
			local spellIndex = SpellCastName == NECROSIS_SPELL_TABLE[31].Name and 31 or 36
			local duration = NECROSIS_SPELL_TABLE[spellIndex].Length or 0
			local expiry = floor(GetTime() + duration)
			local updated = false
			if timerService then
				updated = timerService:UpdateTimerEntry(
					SpellCastName,
					playerName,
					duration,
					expiry,
					NECROSIS_SPELL_TABLE[spellIndex].Type
				)
			end
			if not updated then
				if timerService and timerService.EnsureSpellIndexTimer then
					timerService:EnsureSpellIndexTimer(spellIndex, playerName, nil, nil, nil, nil)
				end
			elseif DEBUG_TIMER_EVENTS then
				Necrosis_DebugPrint("Timer refreshed", SpellCastName, duration)
			end
		else
			for spell = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if SpellCastName == NECROSIS_SPELL_TABLE[spell].Name and not (spell == 10) then
					-- If the timer already exists on the target, refresh it
					local spellData = NECROSIS_SPELL_TABLE[spell]
					if spellData.Type ~= 4 and spell ~= 16 then
						if not (spell == 9 and Necrosis_UnitHasEffect("target", SpellCastName)) then
							local refreshDuration = spellData.Length
							if spell == 9 and SpellCastRank == 1 then
								refreshDuration = 20
							end
							local refreshed = false
							if timerService then
								refreshed = timerService:UpdateTimer(SpellCastName, SpellTargetName, function(timer)
									timer.Time = refreshDuration
									timer.TimeMax = floor(GetTime() + refreshDuration)
									return true
								end)
							end
							if refreshed then
								SortActif = true
							end
						end
					end

					if spell == 9 then
						if timerService then
							timerService:IterateTimers(function(timer, index)
								if timer.Name == SpellCastName and timer.Target ~= SpellTargetName then
									timerService:RemoveTimerByIndex(index)
									SortActif = false
									return false
								end
							end)
						end
					end

					if spell == 13 then
						if timerService then
							timerService:IterateTimers(function(timer, index)
								if timer.Name == SpellCastName then
									timerService:RemoveTimerByIndex(index)
									SortActif = false
									return false
								end
							end)
						end
					end

					if (spellData.Type == 4) or (spell == 16) then
						if timerService then
							timerService:IterateTimers(function(timer, index)
								if NECROSIS_SPELL_TABLE[16] and timer.Name == NECROSIS_SPELL_TABLE[16].Name then
									timerService:UpdateTimer(timer.Name, timer.Target, function(updateTarget)
										updateTarget.Target = ""
										return false
									end)
								end
								if timer.Type == 4 and timer.Target == SpellTargetName then
									timerService:RemoveTimerByIndex(index)
									return false
								end
							end)
						end
						SortActif = false
					end

					if not SortActif and spellData.Type ~= 0 then
						if spell == 9 then
							if SpellCastRank == 1 then
								spellData.Length = 20
							else
								spellData.Length = 30
							end
						end

						if timerService then
							timerService:EnsureSpellIndexTimer(spell, SpellTargetName, nil, nil, nil, nil)
						end
						break
					end
				end
			end
		end
	end
	SpellCastName = nil
	SpellCastRank = nil
	return
end

------------------------------------------------------------------------------------------------------
-- INTERFACE FUNCTIONS -- XML LINKS
------------------------------------------------------------------------------------------------------

-- Right-clicking Necrosis toggles both configuration panels
function Necrosis_Toggle(button)
	if button == "LeftButton" then
		if NECROSIS_SPELL_TABLE[41].ID then
			CastSpell(NECROSIS_SPELL_TABLE[41].ID, "spell")
		end
		return
	elseif NecrosisGeneralFrame:IsVisible() then
		HideUIPanel(NecrosisGeneralFrame)
		return
	else
		if NecrosisConfig.SM then
			Necrosis_Msg("!!! Short Messages : <brightGreen>On", "USER")
		end
		ShowUIPanel(NecrosisGeneralFrame)
		NecrosisGeneralTab_OnClick(1)
		return
	end
end

-- Function that lets Necrosis elements be moved on screen
function Necrosis_OnDragStart(button)
	if button == "NecrosisIcon" then
		GameTooltip:Hide()
	end
	button:StartMoving()
end

-- Function that stops moving Necrosis elements on screen
function Necrosis_OnDragStop(button)
	if button == "NecrosisIcon" then
		Necrosis_BuildTooltip("OVERALL")
	end
	button:StopMovingOrSizing()
end

-- Function that toggles between graphical and text timers
function Necrosis_HideGraphTimer()
	local service = getTimerService()
	for i = 1, 50, 1 do
		local elements = { "Text", "Bar", "Texture", "OutText" }
		if NecrosisConfig.Graphical then
			if service and service.timerSlots and service.timerSlots[i] then
				for j = 1, 4, 1 do
					frameName = "NecrosisTimer" .. i .. elements[j]
					frameItem = getglobal(frameName)
					frameItem:Show()
				end
			end
		else
			for j = 1, 4, 1 do
				frameName = "NecrosisTimer" .. i .. elements[j]
				frameItem = getglobal(frameName)
				frameItem:Hide()
			end
		end
	end
end

-- Function that manages tooltips
function Necrosis_BuildTooltip(button, type, anchor)
	-- If tooltips are disabled, exit immediately!
	if not NecrosisConfig.NecrosisToolTip then
		return
	end

	-- Check whether Fel Domination, Shadow Ward, or Curse Amplification are active (for tooltips)
	local start, duration, start2, duration2, start3, duration3
	if NECROSIS_SPELL_TABLE[15].ID then
		start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, BOOKTYPE_SPELL)
	else
		start = 1
		duration = 1
	end
	if NECROSIS_SPELL_TABLE[43].ID then
		start2, duration2 = GetSpellCooldown(NECROSIS_SPELL_TABLE[43].ID, BOOKTYPE_SPELL)
	else
		start2 = 1
		duration2 = 1
	end
	if NECROSIS_SPELL_TABLE[42].ID then
		start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, BOOKTYPE_SPELL)
	else
		start3 = 1
		duration3 = 1
	end

	-- Create the tooltips....
	GameTooltip:SetOwner(button, anchor)
	GameTooltip:SetText(NecrosisTooltipData[type].Label)
	-- ..... for the main button
	if type == "Main" then
		GameTooltip:AddLine(NecrosisTooltipData.Main.Soulshard .. SoulshardState.count)
		GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone .. ComponentState.infernal)
		GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone .. ComponentState.demoniac)
		GameTooltip:AddLine(
			NecrosisTooltipData.Main.Soulstone .. NecrosisTooltipData[type].Stone[StoneInventory.Soulstone.onHand]
		)
		GameTooltip:AddLine(
			NecrosisTooltipData.Main.Healthstone .. NecrosisTooltipData[type].Stone[StoneInventory.Healthstone.onHand]
		)
		-- Display the demon's name, show if it is enslaved, or "None" when no demon is present
		if DemonType then
			GameTooltip:AddLine(NecrosisTooltipData.Main.CurrentDemon .. DemonType)
		elseif DemonEnslaved then
			GameTooltip:AddLine(NecrosisTooltipData.Main.EnslavedDemon)
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.NoCurrentDemon)
		end
	-- ..... for the stone buttons
	elseif string.find(type, "stone") then
		-- Soulstone
		if type == "Soulstone" then
			-- On affiche le nom de la pierre et l'action que produira le clic sur le bouton
			-- Also grab the cooldown
			if StoneInventory.Soulstone.mode == 1 or StoneInventory.Soulstone.mode == 3 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText())
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Soulstone.mode])
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		-- Pierre de vie
		elseif type == "Spellstone" then
			-- Idem
			if StoneInventory.Spellstone.mode == 1 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Spellstone.mode])
			local itemName = tostring(NecrosisTooltipTextLeft7:GetText())
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		elseif type == "Healthstone" then
			-- Idem
			if StoneInventory.Healthstone.mode == 1 then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			NecrosisTooltip:SetBagItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
			local itemName = tostring(NecrosisTooltipTextLeft6:GetText())
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[StoneInventory.Healthstone.mode])
			if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
				GameTooltip:AddLine(itemName)
			end
		-- Pierre de feu
		elseif type == "Firestone" then
			local stoneMode = StoneInventory.Firestone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[4] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[4]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Firestone.onHand and StoneInventory.Firestone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Firestone.location[1], StoneInventory.Firestone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Felstone" then
			local stoneMode = StoneInventory.Felstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[5] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[5]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Felstone.onHand and StoneInventory.Felstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Felstone.location[1], StoneInventory.Felstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Wrathstone" then
			local stoneMode = StoneInventory.Wrathstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[6] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[6]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Wrathstone.onHand and StoneInventory.Wrathstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Wrathstone.location[1], StoneInventory.Wrathstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		elseif type == "Voidstone" then
			local stoneMode = StoneInventory.Voidstone.onHand and 2 or 1
			if stoneMode == 1 and StoneIDInSpellTable[7] ~= 0 and NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]] then
				GameTooltip:AddLine(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[7]].Mana .. " Mana")
			end
			Necrosis_MoneyToggle()
			if StoneInventory.Voidstone.onHand and StoneInventory.Voidstone.location[1] then
				NecrosisTooltip:SetBagItem(StoneInventory.Voidstone.location[1], StoneInventory.Voidstone.location[2])
			end
			GameTooltip:AddLine(NecrosisTooltipData[type].Text[stoneMode])
		end
	-- ..... for the timer button
	elseif type == "SpellTimer" then
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetBagItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		local itemName = tostring(NecrosisTooltipTextLeft5:GetText())
		GameTooltip:AddLine(NecrosisTooltipData[type].Text)
		if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
			GameTooltip:AddLine(NECROSIS_TRANSLATION.Hearth .. " - " .. itemName)
		else
			GameTooltip:AddLine(NecrosisTooltipData[type].Right .. GetBindLocation())
		end

	-- ..... for the Shadow Trance button
	elseif type == "ShadowTrance" then
		local rank = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "Rank")
		GameTooltip:SetText(NecrosisTooltipData[type].Label .. "          |CFF808080Rank " .. rank .. "|r")
	-- ..... for the other buffs and demons, the mana cost...
	elseif type == "Enslave" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[35].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		end
	elseif type == "Mount" then
		if NECROSIS_SPELL_TABLE[2].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[2].Mana .. " Mana")
		elseif NECROSIS_SPELL_TABLE[1].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[1].Mana .. " Mana")
		end
	elseif type == "Armor" then
		if NECROSIS_SPELL_TABLE[31].ID then
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[31].Mana .. " Mana")
		else
			GameTooltip:AddLine(NECROSIS_SPELL_TABLE[36].Mana .. " Mana")
		end
	elseif type == "Invisible" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[33].Mana .. " Mana")
	elseif type == "Aqua" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[32].Mana .. " Mana")
	elseif type == "Kilrogg" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[34].Mana .. " Mana")
	elseif type == "Banish" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[9].Mana .. " Mana")
	elseif type == "Weakness" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[23].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Agony" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[22].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Reckless" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[24].Mana .. " Mana")
	elseif type == "Tongues" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[25].Mana .. " Mana")
	elseif type == "Exhaust" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[40].Mana .. " Mana")
		if not (start3 > 0 and duration3 > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.AmplifyCooldown)
		end
	elseif type == "Elements" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[26].Mana .. " Mana")
	elseif type == "Shadow" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[27].Mana .. " Mana")
	elseif type == "Doom" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[16].Mana .. " Mana")
	elseif type == "Amplify" then
		if start3 > 0 and duration3 > 0 then
			local seconde = duration3 - (GetTime() - start3)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)) .. " sec"
			else
				minute = tostring(floor(seconde / 60))
				seconde = mod(seconde, 60)
				if seconde <= 9 then
					time = "0" .. tostring(floor(seconde))
				else
					time = tostring(floor(seconde))
				end
				affiche = minute .. ":" .. time
			end
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "TP" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[37].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		end
	elseif type == "SoulLink" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[38].Mana .. " Mana")
	elseif type == "ShadowProtection" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[43].Mana .. " Mana")
		if start2 > 0 and duration2 > 0 then
			local seconde = duration2 - (GetTime() - start2)
			local affiche
			affiche = tostring(floor(seconde)) .. " sec"
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "Domination" then
		if start > 0 and duration > 0 then
			local seconde = duration - (GetTime() - start)
			local affiche, minute, time
			if seconde <= 59 then
				affiche = tostring(floor(seconde)) .. " sec"
			else
				minute = tostring(floor(seconde / 60))
				seconde = mod(seconde, 60)
				if seconde <= 9 then
					time = "0" .. tostring(floor(seconde))
				else
					time = tostring(floor(seconde))
				end
				affiche = minute .. ":" .. time
			end
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif type == "Imp" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[3].Mana .. " Mana")
		if not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Void" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[4].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Succubus" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[5].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Fel" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[6].Mana .. " Mana")
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. NecrosisTooltipData.Main.Soulshard .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			GameTooltip:AddLine(NecrosisTooltipData.DominationCooldown)
		end
	elseif type == "Infernal" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[8].Mana .. " Mana")
		if ComponentState.infernal == 0 then
			GameTooltip:AddLine(
				"|c00FF4444" .. NecrosisTooltipData.Main.InfernalStone .. ComponentState.infernal .. "|r"
			)
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.InfernalStone .. ComponentState.infernal)
		end
	elseif type == "Doomguard" then
		GameTooltip:AddLine(NECROSIS_SPELL_TABLE[30].Mana .. " Mana")
		if ComponentState.demoniac == 0 then
			GameTooltip:AddLine(
				"|c00FF4444" .. NecrosisTooltipData.Main.DemoniacStone .. ComponentState.demoniac .. "|r"
			)
		else
			GameTooltip:AddLine(NecrosisTooltipData.Main.DemoniacStone .. ComponentState.demoniac)
		end
	elseif (type == "Buff") and LastCast.Buff ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_SPELL_TABLE[LastCast.Buff].Name)
	elseif (type == "Curse") and LastCast.Curse.id ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_SPELL_TABLE[LastCast.Curse.id].Name)
	elseif (type == "Pet") and LastCast.Demon ~= 0 then
		GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. NECROSIS_PET_LOCAL_NAME[(LastCast.Demon - 2)])
	elseif (type == "Stone") and LastCast.Stone.id ~= 0 then
		local stoneName = ""
		local stoneOnHand = false
		if LastCast.Stone.id == 1 and StoneInventory.Felstone.onHand then
			stoneName = NECROSIS_ITEM.Felstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 2 and StoneInventory.Wrathstone.onHand then
			stoneName = NECROSIS_ITEM.Wrathstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 3 and StoneInventory.Voidstone.onHand then
			stoneName = NECROSIS_ITEM.Voidstone
			stoneOnHand = true
		elseif LastCast.Stone.id == 4 and StoneInventory.Firestone.onHand then
			stoneName = NECROSIS_ITEM.Firestone
			stoneOnHand = true
		end
		if stoneOnHand then
			GameTooltip:AddLine(NecrosisTooltipData.LastSpell .. stoneName)
		end
	end
	-- And tada, show it!
	GameTooltip:Show()
end

-- Function that refreshes Necrosis buttons and reports Soulstone button state

------------------------------------------------------------------------------------------------------
-- STONE AND SHARD FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Remember where you stored your belongings!

-- Function that inventories demonology items: stones, shards, summoning reagents

-- Function that locates and tidies shards inside bags

-- While moving shards, find new slots for the displaced items :)

------------------------------------------------------------------------------------------------------
-- SPELL FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Show or hide spell buttons each time a new spell is learned
function Necrosis_ButtonSetup()
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_NoDrag()
		Necrosis_UpdateButtonsScale()
	else
		HideUIPanel(NecrosisPetMenuButton)
		HideUIPanel(NecrosisBuffMenuButton)
		HideUIPanel(NecrosisCurseMenuButton)
		HideUIPanel(NecrosisStoneMenuButton)
		HideUIPanel(NecrosisMountButton)
		HideUIPanel(NecrosisSpellstoneButton)
		HideUIPanel(NecrosisHealthstoneButton)
		HideUIPanel(NecrosisSoulstoneButton)
		if NecrosisConfig.StonePosition[StonePos.Healthstone] and StoneIDInSpellTable[2] ~= 0 then
			ShowUIPanel(NecrosisHealthstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Spellstone] and StoneIDInSpellTable[3] ~= 0 then
			ShowUIPanel(NecrosisSpellstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Soulstone] and StoneIDInSpellTable[1] ~= 0 then
			ShowUIPanel(NecrosisSoulstoneButton)
		end
		if NecrosisConfig.StonePosition[StonePos.BuffMenu] and next(MenuState.Buff.frames) then
			ShowUIPanel(NecrosisBuffMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.Mount] and MountState.available then
			ShowUIPanel(NecrosisMountButton)
		end
		if NecrosisConfig.StonePosition[StonePos.PetMenu] and next(MenuState.Pet.frames) then
			ShowUIPanel(NecrosisPetMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.CurseMenu] and next(MenuState.Curse.frames) then
			ShowUIPanel(NecrosisCurseMenuButton)
		end
		if NecrosisConfig.StonePosition[StonePos.StoneMenu] and next(MenuState.Stone.frames) then
			ShowUIPanel(NecrosisStoneMenuButton)
		end
	end
end

-- My favorite function! It lists the Warlock's known spells and sorts them by rank.
-- For stones, select the highest known rank
function Necrosis_SpellSetup()
	local StoneType = {
		NECROSIS_ITEM.Soulstone,
		NECROSIS_ITEM.Healthstone,
		NECROSIS_ITEM.Spellstone,
		NECROSIS_ITEM.Firestone,
		NECROSIS_ITEM.Felstone,
		NECROSIS_ITEM.Wrathstone,
		NECROSIS_ITEM.Voidstone,
	}
	local StoneMaxRank = { 0, 0, 0, 0, 0, 0, 0 }

	local CurrentStone = {
		ID = {},
		Name = {},
		subName = {},
	}

	local currentSpellIndexByName = {}
	local CurrentSpells = {
		ID = {},
		Name = {},
		subName = {},
	}

	local spellID = 1
	local Invisible = 0
	local InvisibleID = 0

	-- Iterate through every spell the Warlock knows
	while true do
		local spellName, subSpellName = GetSpellName(spellID, BOOKTYPE_SPELL)

		if not spellName then
			do
				break
			end
		end

		-- For spells with numbered ranks, compare each rank one by one
		-- Keep the highest rank
		if string.find(subSpellName, NECROSIS_TRANSLATION.Rank) then
			local rank = tonumber(strsub(subSpellName, 6, strlen(subSpellName)))
			local existingIndex = currentSpellIndexByName[spellName]
			if existingIndex then
				if CurrentSpells.subName[existingIndex] < rank then
					CurrentSpells.ID[existingIndex] = spellID
					CurrentSpells.subName[existingIndex] = rank
				end
			else
				local newIndex = table.getn(CurrentSpells.Name) + 1
				CurrentSpells.ID[newIndex] = spellID
				CurrentSpells.Name[newIndex] = spellName
				CurrentSpells.subName[newIndex] = rank
				currentSpellIndexByName[spellName] = newIndex
			end
		end

		-- Test Detect Invisibility's rank
		if spellName == NECROSIS_TRANSLATION.GreaterInvisible then
			Invisible = 3
			InvisibleID = spellID
		elseif spellName == NECROSIS_TRANSLATION.Invisible and Invisible ~= 3 then
			Invisible = 2
			InvisibleID = spellID
		elseif spellName == NECROSIS_TRANSLATION.LesserInvisible and Invisible ~= 3 and Invisible ~= 2 then
			Invisible = 1
			InvisibleID = spellID
		end

		-- Stones do not have numbered ranks; the rank is part of the spell name
		-- Pour chaque type de pierre, on va donc faire....
		for stoneID = 1, table.getn(StoneType), 1 do
			-- If the spell is the summon for this stone type and we have not
			-- and we have not already assigned its maximum rank
			if
				(string.find(spellName, StoneType[stoneID]))
				and StoneMaxRank[stoneID] ~= table.getn(NECROSIS_STONE_RANK)
			then
				-- Extract the end of the stone name that encodes its rank
				local stoneSuffix = string.sub(spellName, string.len(NECROSIS_CREATE[stoneID]) + 1)
				-- Next, find which rank it corresponds to
				for rankID = 1, table.getn(NECROSIS_STONE_RANK), 1 do
					-- If the suffix matches a stone size, record the rank!
					if string.lower(stoneSuffix) == string.lower(NECROSIS_STONE_RANK[rankID]) then
						-- Once we know the stone and its rank, check whether it is the strongest
						-- and if so, record it
						if rankID > StoneMaxRank[stoneID] then
							StoneMaxRank[stoneID] = rankID
							CurrentStone.Name[stoneID] = spellName
							CurrentStone.subName[stoneID] = NECROSIS_STONE_RANK[rankID]
							CurrentStone.ID[stoneID] = spellID
						end
						break
					end
				end
			end
		end

		spellID = spellID + 1
	end

	-- Insert the stones of the highest rank into the table
	for stoneID = 1, table.getn(StoneType), 1 do
		if StoneMaxRank[stoneID] ~= 0 then
			table.insert(NECROSIS_SPELL_TABLE, {
				ID = CurrentStone.ID[stoneID],
				Name = CurrentStone.Name[stoneID],
				Rank = 0,
				CastTime = 0,
				Length = 0,
				Type = 0,
			})
			StoneIDInSpellTable[stoneID] = table.getn(NECROSIS_SPELL_TABLE)
		end
	end
	-- Refresh the spell list with the new ranks
	for spell = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		local name = NECROSIS_SPELL_TABLE[spell].Name
		local index = currentSpellIndexByName[name]
		if index then
			if
				NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[1]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[2]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[3]
				and NECROSIS_SPELL_TABLE[spell].ID ~= StoneIDInSpellTable[4]
			then
				NECROSIS_SPELL_TABLE[spell].ID = CurrentSpells.ID[index]
				NECROSIS_SPELL_TABLE[spell].Rank = CurrentSpells.subName[index]
			end
		end
	end

	-- Update each spell duration based on its rank
	for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if index == 9 then -- si Bannish
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 10 + 10
			end
		end
		if index == 13 then -- si Fear
			if NECROSIS_SPELL_TABLE[index].ID ~= nil then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 5 + 5
			end
		end
		if index == 14 then -- si Corruption
			if NECROSIS_SPELL_TABLE[index].ID ~= nil and NECROSIS_SPELL_TABLE[index].Rank <= 2 then
				NECROSIS_SPELL_TABLE[index].Length = NECROSIS_SPELL_TABLE[index].Rank * 3 + 9
			end
		end
	end

	for spellID = 1, MAX_SPELLS, 1 do
		local spellName, subSpellName = GetSpellName(spellID, "spell")
		if spellName then
			for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
				if NECROSIS_SPELL_TABLE[index].Name == spellName then
					Necrosis_MoneyToggle()
					NecrosisTooltip:SetSpell(spellID, 1)
					local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
					if not NECROSIS_SPELL_TABLE[index].ID then
						NECROSIS_SPELL_TABLE[index].ID = spellID
					end
					NECROSIS_SPELL_TABLE[index].Mana = tonumber(ManaCost)
				end
			end
		end
	end
	MountState.available = not not (NECROSIS_SPELL_TABLE[1].ID or NECROSIS_SPELL_TABLE[2].ID)

	-- Insert the highest known rank of Detect Invisibility
	if Invisible >= 1 then
		NECROSIS_SPELL_TABLE[33].ID = InvisibleID
		NECROSIS_SPELL_TABLE[33].Rank = 0
		NECROSIS_SPELL_TABLE[33].CastTime = 0
		NECROSIS_SPELL_TABLE[33].Length = 0
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetSpell(InvisibleID, 1)
		local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
		NECROSIS_SPELL_TABLE[33].Mana = tonumber(ManaCost)
	end
end

-- Function that extracts spell attributes
-- F(type=string, string, int) -> Spell=table
function Necrosis_FindSpellAttribute(type, attribute, array)
	for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		if string.find(NECROSIS_SPELL_TABLE[index][type], attribute) then
			return NECROSIS_SPELL_TABLE[index][array]
		end
	end
	return nil
end

-- Function to cast Shadow Bolt from the Shadow Trance button
-- The shard must use the highest rank
function Necrosis_CastShadowBolt()
	local spellID = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "ID")
	if spellID then
		CastSpell(spellID, "spell")
	else
		Necrosis_Msg(NECROSIS_NIGHTFALL_TEXT.NoBoltSpell, "USER")
	end
end

------------------------------------------------------------------------------------------------------
-- MISCELLANEOUS FUNCTIONS
------------------------------------------------------------------------------------------------------

-- Function that determines whether a unit is affected by an effect
-- F(string, string)->bool
function Necrosis_UnitHasEffect(unit, effect)
	local index = 1
	while UnitDebuff(unit, index) do
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetUnitDebuff(unit, index)
		local DebuffName = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(DebuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

-- Function to check the presence of a buff on the unit.
-- Strictly identical to UnitHasEffect, but as WoW distinguishes Buff and DeBuff, so we have to.
function Necrosis_UnitHasBuff(unit, effect)
	local index = 1
	while UnitBuff(unit, index) do
		-- Here we'll cheat a little. checking a buff or debuff return the internal spell name, and not the name we give at start
		-- So we use an API widget that will use the internal name to return the known name.
		-- For example, the "Curse of Agony" spell is internaly known as "Spell_Shadow_CurseOfSargeras". Much easier to use the first one than the internal one.
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetUnitBuff(unit, index)
		local BuffName = tostring(NecrosisTooltipTextLeft1:GetText())
		if string.find(BuffName, effect) then
			return true
		end
		index = index + 1
	end
	return false
end

-- Detects when the player gains Nightfall / Shadow Trance
function Necrosis_UnitHasTrance()
	local ID = -1
	for buffID = 0, 24, 1 do
		local buffTexture = GetPlayerBuffTexture(buffID)
		if buffTexture == nil then
			break
		end
		if strfind(buffTexture, "Spell_Shadow_Twilight") then
			ID = buffID
			break
		end
	end
	ShadowState.buffId = ID
end

-- Function handling button click actions for Necrosis
function Necrosis_UseItem(type, button)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetBagItem("player", 17)
	local rightHand = tostring(NecrosisTooltipTextLeft1:GetText())
	local timerService = getTimerService()

	-- Function that uses a hearthstone from the inventory
	-- if one is in the inventory and it was a right-click
	if type == "Hearthstone" and button == "RightButton" then
		if StoneInventory.Hearthstone.onHand then
			-- use it
			UseContainerItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		-- or, if none are in the inventory, show an error message
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHearthStone, "USER")
		end
	end

	-- When clicking the Soulstone button
	-- Update the button to indicate the current mode
	if type == "Soulstone" then
		Necrosis_UpdateIcons()
		-- If mode = 2 (stone in inventory, none in use)
		-- alors on l'utilise
		if StoneInventory.Soulstone.mode == 2 then
			-- If a player is targeted, cast on them (with alert message)
			-- If no player is targeted, cast on the Warlock (without a message)
			if UnitIsPlayer("target") then
				SoulstoneUsedOnTarget = true
			else
				SoulstoneUsedOnTarget = false
				TargetUnit("player")
			end
			UseContainerItem(StoneInventory.Soulstone.location[1], StoneInventory.Soulstone.location[2])
			-- Now that timers persist across the session, we no longer reset when relogging
			NecrosisRL = false
			-- And there we go, refresh the button display :)
			Necrosis_UpdateIcons()
		-- if no Soulstone is in the inventory, create the highest-rank Soulstone :)
		elseif (StoneInventory.Soulstone.mode == 1) or (StoneInventory.Soulstone.mode == 3) then
			if StoneIDInSpellTable[1] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[1]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSoulStoneSpell, "USER")
			end
		end
	-- When clicking the Healthstone button:
	elseif type == "Healthstone" then
		-- or there is one in the inventory
		if StoneInventory.Healthstone.onHand then
			-- If a friendly player is targeted, give them the stone
			-- Otherwise use it
			if TradeState.requested then
				PickupContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
				ClickTradeButton(1)
				TradeState.requested = false
				TradeState.active = true
				TradeState.countdown = 3
				return
			elseif
				UnitExists("target")
				and UnitIsPlayer("target")
				and (not UnitCanAttack("player", "target"))
				and UnitName("target") ~= UnitName("player")
			then
				PickupContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
				if CursorHasItem() then
					DropItemOnUnit("target")
					TradeState.active = true
					TradeState.countdown = 3
				end
				return
			end
			if UnitHealth("player") == UnitHealthMax("player") then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.FullHealth, "USER")
			else
				SpellStopCasting()
				UseContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])

				-- Inserts a timer for the Healthstone if not already present
				local HealthstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Healthstone) then
					HealthstoneInUse = true
				end
				if not HealthstoneInUse and timerService then
					timerService:EnsureNamedTimer(
						NECROSIS_COOLDOWN.Healthstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil
					)
				end

				-- Healthstone shares its cooldown with Spellstone, so we add both timers at the same time, but only if Spellstone is known
				local SpellstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
					SpellstoneInUse = true
				end
				if not SpellstoneInUse and StoneIDInSpellTable[3] ~= 0 and timerService then
					timerService:EnsureNamedTimer(
						NECROSIS_COOLDOWN.Spellstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil
					)
				end
			end
		-- or, if none are in the inventory, create the highest rank stone
		else
			if StoneIDInSpellTable[2] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[2]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoHealthStoneSpell, "USER")
			end
		end
	-- When clicking the Spellstone button
	elseif type == "Spellstone" then
		if StoneInventory.Spellstone.onHand then
			local start, duration, enabled =
				GetContainerItemCooldown(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			if start > 0 then
				Necrosis_Msg(NECROSIS_MESSAGE.Error.SpellStoneIsOnCooldown, "USER")
			else
				SpellStopCasting()
				UseContainerItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])

				local SpellstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
					SpellstoneInUse = true
				end
				if not SpellstoneInUse and timerService then
					timerService:EnsureNamedTimer(
						NECROSIS_COOLDOWN.Spellstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil
					)
				end

				local HealthstoneInUse = false
				if Necrosis_TimerExists(NECROSIS_COOLDOWN.Healthstone) then
					HealthstoneInUse = true
				end
				if not HealthstoneInUse and StoneIDInSpellTable[2] ~= 0 and timerService then
					timerService:EnsureNamedTimer(
						NECROSIS_COOLDOWN.Healthstone,
						120,
						TIMER_TYPE.SELF_BUFF,
						nil,
						120,
						nil
					)
				end
			end
		else
			if StoneIDInSpellTable[3] ~= 0 then
				CastSpell(NECROSIS_SPELL_TABLE[StoneIDInSpellTable[3]].ID, "spell")
			else
				Necrosis_Msg(NECROSIS_MESSAGE.Error.NoSpellStoneSpell, "USER")
			end
		end

	-- When clicking the mount button
	elseif type == "Mount" then
		-- Or it is the epic mount
		if NECROSIS_SPELL_TABLE[2].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[2].ID, "spell")
			Necrosis_OnUpdate()
		-- Either it is the normal mount
		elseif NECROSIS_SPELL_TABLE[1].ID ~= nil then
			CastSpell(NECROSIS_SPELL_TABLE[1].ID, "spell")
			Necrosis_OnUpdate()
		-- (Or it is nothing at all :) )
		else
			Necrosis_Msg(NECROSIS_MESSAGE.Error.NoRiding, "USER")
		end
	end
end

-- Function that swaps the equipped off-hand item with one from the inventory
function Necrosis_SwitchOffHand(type)
	if type == "Spellstone" then
		if StoneInventory.Spellstone.mode == 3 then
			if StoneInventory.Itemswitch.onHand then
				Necrosis_Msg(
					"Equipe "
						.. GetContainerItemLink(
							StoneInventory.Itemswitch.location[1],
							StoneInventory.Itemswitch.location[2]
						)
						.. NECROSIS_MESSAGE.SwitchMessage
						.. GetInventoryItemLink("player", 17),
					"USER"
				)
				PickupInventoryItem(17)
				PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			end
			return
		else
			PickupContainerItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			PickupInventoryItem(17)
			if Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) and timerService then
				timerService:RemoveTimerByName(NECROSIS_COOLDOWN.Spellstone)
			end
			if timerService then
				timerService:EnsureNamedTimer(NECROSIS_COOLDOWN.Spellstone, 120, TIMER_TYPE.SELF_BUFF, nil, 120, nil)
			end
			return
		end
	end
	if (type == "OffHand") and UnitClass("player") == NECROSIS_UNIT_WARLOCK then
		if StoneInventory.Itemswitch.location[1] ~= nil and StoneInventory.Itemswitch.location[2] ~= nil then
			PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			PickupInventoryItem(17)
		end
	end
end

function Necrosis_MoneyToggle()
	for index = 1, 10 do
		local text = getglobal("NecrosisTooltipTextLeft" .. index)
		text:SetText(nil)
		text = getglobal("NecrosisTooltipTextRight" .. index)
		text:SetText(nil)
	end
	NecrosisTooltip:Hide()
	NecrosisTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

function Necrosis_GameTooltip_ClearMoney()
	-- Intentionally empty; don't clear money while we use hidden tooltips
end

-- Function that positions the buttons around Necrosis (and scales the interface)
function Necrosis_UpdateButtonsScale()
	local NBRScale = (100 + (NecrosisConfig.NecrosisButtonScale - 85)) / 100
	if NecrosisConfig.NecrosisButtonScale <= 95 then
		NBRScale = 1.1
	end
	if NecrosisConfig.NecrosisLockServ then
		Necrosis_ClearAllPoints()
		HideUIPanel(NecrosisPetMenuButton)
		HideUIPanel(NecrosisBuffMenuButton)
		HideUIPanel(NecrosisCurseMenuButton)
		HideUIPanel(NecrosisStoneMenuButton)
		HideUIPanel(NecrosisMountButton)
		HideUIPanel(NecrosisSpellstoneButton)
		HideUIPanel(NecrosisHealthstoneButton)
		HideUIPanel(NecrosisSoulstoneButton)
		local indexScale = -36
		for index = 1, 8, 1 do
			if NecrosisConfig.StonePosition[index] then
				if index == StonePos.Healthstone and StoneIDInSpellTable[2] ~= 0 then
					NecrosisHealthstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisHealthstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Spellstone and StoneIDInSpellTable[3] ~= 0 then
					NecrosisSpellstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisSpellstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Soulstone and StoneIDInSpellTable[1] ~= 0 then
					NecrosisSoulstoneButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisSoulstoneButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.BuffMenu and next(MenuState.Buff.frames) then
					NecrosisBuffMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisBuffMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.Mount and MountState.available then
					NecrosisMountButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisMountButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.PetMenu and next(MenuState.Pet.frames) then
					NecrosisPetMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisPetMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.CurseMenu and next(MenuState.Curse.frames) then
					NecrosisCurseMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisCurseMenuButton)
					indexScale = indexScale + 36
				end
				if index == StonePos.StoneMenu and next(MenuState.Stone.frames) then
					NecrosisStoneMenuButton:SetPoint(
						"CENTER",
						"NecrosisButton",
						"CENTER",
						((40 * NBRScale) * cos(NecrosisConfig.NecrosisAngle - indexScale)),
						((40 * NBRScale) * sin(NecrosisConfig.NecrosisAngle - indexScale))
					)
					ShowUIPanel(NecrosisStoneMenuButton)
					indexScale = indexScale + 36
				end
			end
		end
	end
end

-- (XML) function that restores default button anchors
function Necrosis_ClearAllPoints()
	NecrosisSpellstoneButton:ClearAllPoints()
	NecrosisHealthstoneButton:ClearAllPoints()
	NecrosisSoulstoneButton:ClearAllPoints()
	NecrosisMountButton:ClearAllPoints()
	NecrosisPetMenuButton:ClearAllPoints()
	NecrosisBuffMenuButton:ClearAllPoints()
	NecrosisCurseMenuButton:ClearAllPoints()
	NecrosisStoneMenuButton:ClearAllPoints()
end

-- (XML) function to extend the main button's NoDrag() property to every child button
function Necrosis_NoDrag()
	NecrosisSpellstoneButton:RegisterForDrag("")
	NecrosisHealthstoneButton:RegisterForDrag("")
	NecrosisSoulstoneButton:RegisterForDrag("")
	NecrosisMountButton:RegisterForDrag("")
	NecrosisPetMenuButton:RegisterForDrag("")
	NecrosisBuffMenuButton:RegisterForDrag("")
	NecrosisCurseMenuButton:RegisterForDrag("")
	NecrosisStoneMenuButton:RegisterForDrag("")
end

-- (XML) counterpart of the function above
function Necrosis_Drag()
	NecrosisSpellstoneButton:RegisterForDrag("LeftButton")
	NecrosisHealthstoneButton:RegisterForDrag("LeftButton")
	NecrosisSoulstoneButton:RegisterForDrag("LeftButton")
	NecrosisMountButton:RegisterForDrag("LeftButton")
	NecrosisPetMenuButton:RegisterForDrag("LeftButton")
	NecrosisBuffMenuButton:RegisterForDrag("LeftButton")
	NecrosisCurseMenuButton:RegisterForDrag("LeftButton")
	NecrosisStoneMenuButton:RegisterForDrag("LeftButton")
end

-- Handle casts triggered from the buff menu
function Necrosis_BuffCast(type)
	local TargetEnemy = false
	if UnitCanAttack("player", "target") and type ~= 9 then
		TargetUnit("player")
		TargetEnemy = true
	end
	-- If the Warlock has Demon Skin but not Demon Armor
	if not NECROSIS_SPELL_TABLE[type].ID then
		CastSpell(NECROSIS_SPELL_TABLE[36].ID, "spell")
	else
		if (type ~= 44) or (type == 44 and UnitExists("Pet")) then
			CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
		end
	end
	LastCast.Buff = type
	if TargetEnemy then
		TargetLastTarget()
	end
	MenuState.Buff.alpha = 1
	MenuState.Buff.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the curse menu
function Necrosis_CurseCast(type, click)
	if (UnitIsFriend("player", "target")) and (not UnitCanAttack("player", "target")) then
		AssistUnit("target")
	end
	if (UnitCanAttack("player", "target")) and (UnitName("target") ~= nil) then
		if type == 23 or type == 22 or type == 40 then
			if (click == "RightButton") and (NECROSIS_SPELL_TABLE[42].ID ~= nil) then
				local start3, duration3 = GetSpellCooldown(NECROSIS_SPELL_TABLE[42].ID, "spell")
				if not (start3 > 0 and duration3 > 0) then
					CastSpell(NECROSIS_SPELL_TABLE[42].ID, "spell")
					SpellStopCasting(NECROSIS_SPELL_TABLE[42].Name)
				end
			end
		end
		CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
		LastCast.Curse.id = type
		LastCast.Curse.click = click
		if (click == "MiddleButton") and (UnitExists("Pet")) then
			PetAttack()
		end
	end
	MenuState.Curse.alpha = 1
	MenuState.Curse.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the stone menu
local StoneCastDefinitions = {
	[1] = { inventoryKey = "Felstone", stoneIndex = 5 },
	[2] = { inventoryKey = "Wrathstone", stoneIndex = 6 },
	[3] = { inventoryKey = "Voidstone", stoneIndex = 7 },
	[4] = { inventoryKey = "Firestone", stoneIndex = 4 },
}

function Necrosis_StoneCast(type, click)
	local definition = StoneCastDefinitions[type]
	if not definition then
		return
	end

	local stoneData = StoneInventory[definition.inventoryKey]
	if stoneData and stoneData.onHand then
		SpellStopCasting()
		UseContainerItem(stoneData.location[1], stoneData.location[2])
		return
	end

	local stoneSpellIndex = nil
	if definition.stoneIndex then
		stoneSpellIndex = StoneIDInSpellTable[definition.stoneIndex]
	end
	local stoneSpell = nil
	if stoneSpellIndex and stoneSpellIndex ~= 0 then
		stoneSpell = NECROSIS_SPELL_TABLE[stoneSpellIndex]
	end
	if not stoneSpell or not stoneSpell.ID then
		local errorTable = NECROSIS_MESSAGE and NECROSIS_MESSAGE.Error
		if errorTable then
			local messageKey = "No" .. definition.inventoryKey .. "Spell"
			local message = errorTable[messageKey]
			if message then
				Necrosis_Msg(message, "USER")
			end
		end
	else
		if stoneSpell.Mana and stoneSpell.Mana > UnitMana("player") then
			local errorTable = NECROSIS_MESSAGE and NECROSIS_MESSAGE.Error
			if errorTable and errorTable.NoMana then
				Necrosis_Msg(errorTable.NoMana, "USER")
			end
			return
		end
		CastSpell(stoneSpell.ID, "spell")
		LastCast.Stone.id = type
		LastCast.Stone.click = click
	end

	MenuState.Stone.alpha = 1
	MenuState.Stone.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the demon menu
function Necrosis_PetCast(type, click)
	if type == 8 and ComponentState.infernal == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.InfernalStoneNotPresent, "USER")
		return
	elseif type == 30 and ComponentState.demoniac == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.DemoniacStoneNotPresent, "USER")
		return
	elseif type ~= 15 and type ~= 3 and type ~= 8 and type ~= 30 and SoulshardState.count == 0 then
		Necrosis_Msg(NECROSIS_MESSAGE.Error.SoulShardNotPresent, "USER")
		return
	end
	if type == 3 or type == 4 or type == 5 or type == 6 then
		LastCast.Demon = type
		if (click == "RightButton") and (NECROSIS_SPELL_TABLE[15].ID ~= nil) then
			local start, duration = GetSpellCooldown(NECROSIS_SPELL_TABLE[15].ID, "spell")
			if not (start > 0 and duration > 0) then
				CastSpell(NECROSIS_SPELL_TABLE[15].ID, "spell")
				SpellStopCasting(NECROSIS_SPELL_TABLE[15].Name)
			end
		end
		if NecrosisConfig.DemonSummon and NecrosisConfig.ChatMsg and not NecrosisConfig.SM then
			if NecrosisConfig.PetName[(type - 2)] == " " and NECROSIS_PET_MESSAGE[5] then
				local genericMessages = NECROSIS_PET_MESSAGE[5]
				local genericCount = table.getn(genericMessages)
				if genericCount > 0 then
					local tempnum = random(1, genericCount)
					if genericCount >= 2 then
						while tempnum == MessageState.pet do
							tempnum = random(1, genericCount)
						end
					end
					MessageState.pet = tempnum
					local lines = genericMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i]), "SAY")
					end
				end
			elseif NECROSIS_PET_MESSAGE[(type - 2)] then
				local specificMessages = NECROSIS_PET_MESSAGE[(type - 2)]
				local specificCount = table.getn(specificMessages)
				if specificCount > 0 then
					local tempnum = random(1, specificCount)
					if specificCount >= 2 then
						while tempnum == MessageState.pet do
							tempnum = random(1, specificCount)
						end
					end
					MessageState.pet = tempnum
					local lines = specificMessages[tempnum]
					local lineCount = table.getn(lines)
					for i = 1, lineCount, 1 do
						Necrosis_Msg(Necrosis_MsgReplace(lines[i], nil, type - 2), "SAY")
					end
				end
			end
		end
	end
	CastSpell(NECROSIS_SPELL_TABLE[type].ID, "spell")
	MenuState.Pet.alpha = 1
	MenuState.Pet.fadeAt = GetTime() + 3
end

-- Function that shows the different configuration pages
local NecrosisGeneralTabs = {
	{
		button = "NecrosisGeneralTab1",
		panelName = "NecrosisShardMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu1",
	},
	{
		button = "NecrosisGeneralTab2",
		panelName = "NecrosisMessageMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu2",
	},
	{
		button = "NecrosisGeneralTab3",
		panelName = "NecrosisButtonMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu3",
	},
	{
		button = "NecrosisGeneralTab4",
		panelName = "NecrosisTimerMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu4",
	},
	{
		button = "NecrosisGeneralTab5",
		panelName = "NecrosisGraphOptionMenu",
		icon = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
		labelKey = "Menu5",
	},
}

function NecrosisGeneralTab_OnClick(id)
	for index = 1, table.getn(NecrosisGeneralTabs), 1 do
		local tabDefinition = NecrosisGeneralTabs[index]
		local tabButton = getglobal(tabDefinition.button)
		if tabButton then
			tabButton:SetChecked(index == id and 1 or nil)
		end
		if tabDefinition.panelName then
			local panel = getglobal(tabDefinition.panelName)
			if panel then
				HideUIPanel(panel)
			end
		end
	end

	local config = NecrosisGeneralTabs[id]
	if not config then
		return
	end

	if config.panelName then
		local panel = getglobal(config.panelName)
		if panel then
			ShowUIPanel(panel)
		end
	end

	if config.icon then
		NecrosisGeneralIcon:SetTexture(config.icon)
	end

	if config.labelKey and NECROSIS_CONFIGURATION then
		local label = NECROSIS_CONFIGURATION[config.labelKey]
		if label then
			NecrosisGeneralPageText:SetText(label)
		end
	end
end

-- To support timers on instant spells I had to take inspiration from Cosmos
-- I did not want the mod to depend on Sea, so I reimplemented its helpers
-- Apparently the stand-alone version of ShardTracker did the same :) :)
Necrosis_Hook = function(orig, new, type)
	if not type then
		type = "before"
	end
	if not Hx_Hooks then
		Hx_Hooks = {}
	end
	if not Hx_Hooks[orig] then
		Hx_Hooks[orig] = {}
		Hx_Hooks[orig].before = {}
		Hx_Hooks[orig].before.n = 0
		Hx_Hooks[orig].after = {}
		Hx_Hooks[orig].after.n = 0
		Hx_Hooks[orig].hide = {}
		Hx_Hooks[orig].hide.n = 0
		Hx_Hooks[orig].replace = {}
		Hx_Hooks[orig].replace.n = 0
		Hx_Hooks[orig].orig = getglobal(orig)
	else
		for key, value in Hx_Hooks[orig][type] do
			if value == getglobal(new) then
				return
			end
		end
	end
	Necrosis_Push(Hx_Hooks[orig][type], getglobal(new))
	setglobal(orig, function(...)
		Necrosis_HookHandler(orig, arg)
	end)
end

Necrosis_HookHandler = function(name, arg)
	local called = false
	local continue = true
	local retval
	for key, value in Hx_Hooks[name].hide do
		if type(value) == "function" then
			if not value(unpack(arg)) then
				continue = false
			end
			called = true
		end
	end
	if not continue then
		return
	end
	for key, value in Hx_Hooks[name].before do
		if type(value) == "function" then
			value(unpack(arg))
			called = true
		end
	end
	continue = false
	local replacedFunction = false
	for key, value in Hx_Hooks[name].replace do
		if type(value) == "function" then
			replacedFunction = true
			if value(unpack(arg)) then
				continue = true
			end
			called = true
		end
	end
	if continue or not replacedFunction then
		retval = Hx_Hooks[name].orig(unpack(arg))
	end
	for key, value in Hx_Hooks[name].after do
		if type(value) == "function" then
			value(unpack(arg))
			called = true
		end
	end
	if not called then
		setglobal(name, Hx_Hooks[name].orig)
		Hx_Hooks[name] = nil
	end
	return retval
end

function Necrosis_Push(table, val)
	if not table or not table.n then
		return nil
	end
	table.n = table.n + 1
	table[table.n] = val
end

function Necrosis_UseAction(id, number, onSelf)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetAction(id)
	local tip = tostring(NecrosisTooltipTextLeft1:GetText())
	if tip then
		SpellCastName = tip
		SpellTargetName = UnitName("target")
		if not SpellTargetName then
			SpellTargetName = ""
		end
	end
end

function Necrosis_CastSpell(spellId, spellbookTabNum)
	local Name, Rank = GetSpellName(spellId, spellbookTabNum)
	if Rank ~= nil then
		local _, _, Rank2 = string.find(Rank, "(%d+)")
		SpellCastRank = tonumber(Rank2)
	end
	SpellCastName = Name

	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end
end

function Necrosis_CastSpellByName(Spell)
	local _, _, Name = string.find(Spell, "(.+)%(")
	local _, _, Rank = string.find(Spell, "([%d]+)")

	if Rank ~= nil then
		local _, _, Rank2 = string.find(Rank, "(%d+)")
		SpellCastRank = tonumber(Rank2)
	end

	if not Name then
		_, _, Name = string.find(Spell, "(.+)")
	end
	SpellCastName = Name

	SpellTargetName = UnitName("target")
	if not SpellTargetName then
		SpellTargetName = ""
	end
end

function NecrosisTimer(timerName, durationSeconds)
	local targetName = UnitName("target")
	local timerType = TIMER_TYPE.CUSTOM
	if not targetName then
		targetName = ""
		timerType = TIMER_TYPE.SELF_BUFF
	end
	local service = getTimerService()
	if service then
		service:InsertCustomTimer(timerName, durationSeconds, timerType, targetName, durationSeconds)
	end
end

function NecrosisSpellCast(name)
	if string.find(name, "coa") then
		SpellCastName = NECROSIS_SPELL_TABLE[22].Name
		SpellTargetName = UnitName("target")
		if not SpellTargetName then
			SpellTargetName = ""
		end
		CastSpell(NECROSIS_SPELL_TABLE[22].ID, "spell")
	end
end
