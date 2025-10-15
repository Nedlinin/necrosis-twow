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
	if type(NecrosisConfig) == "table" and (NecrosisConfig.DebugTimers or NecrosisConfig.DiagnosticsEnabled) then
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

local wipe_table = NecrosisUtils and NecrosisUtils.WipeTable
local function wipe_helper_table(t)
	if not t then
		return
	end
	if wipe_table then
		wipe_table(t)
	else
		for key in pairs(t) do
			t[key] = nil
		end
	end
end

local function trim_string(value)
	if not value then
		return nil
	end
	return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function normalize_spell_name(name)
	if not name or name == "" then
		return name
	end
	local trimmed = string.gsub(name, "%s*%(.*%)$", "")
	return trim_string(trimmed)
end

-- Define helper functions for state access BEFORE using them
local function getState(slice)
	return Necrosis.GetStateSlice(slice)
end

local function getInventory(slice)
	return Necrosis.GetInventorySlice(slice)
end

-- Initialize state accessors (using state system from NecrosisState.lua)
local DemonState = getState("demon")
local BuffState = getState("buffs")
local SoulstoneState_Internal = getState("soulstone")
local InitState = getState("initialization")

-- Note: 'Loaded' remains a local flag for this module's initialization lifecycle
-- It tracks whether Necrosis_LoadVariables has been called, independent of state system
local Loaded = false

-- Expose Loaded for external checks (NecrosisEvents.lua needs this)
function Necrosis_IsLoaded()
	return Loaded
end

-- Initialize variables used by Necrosis to manage spell casts
local SpellCastName = nil
local SpellCastRank = nil
local SpellTargetName = nil
local SpellCastTime = 0

local TIMER_TYPE = NECROSIS_TIMER_TYPE
local InventoryConfig = NecrosisInventoryConfig
local Timers = Necrosis.Timers
local Spells = Necrosis.Spells
local Loc = Necrosis.Loc
local SpellIndex = Spells.Index

local function getTimerService()
	return NecrosisTimerService
end

local function hasSpell(index)
	return Spells:HasID(index)
end

local function getSpellId(index)
	return Spells:GetID(index)
end

local function getSpellNameByIndex(index)
	return Spells:GetName(index)
end

local function getSpellMana(index)
	return Spells:GetMana(index)
end

local function getSpellType(index)
	return Spells:GetType(index)
end

local function getSpellLength(index)
	return Spells:GetLength(index)
end

local function castSpellByIndex(index)
	local spellId = getSpellId(index)
	if spellId then
		CastSpell(spellId, "spell")
		return true
	end
	return false
end

local function getTooltipData(section)
	return Loc:GetTooltip(section) or {}
end

local function getTooltipField(section, key)
	if section ~= nil then
		local tooltip = Loc:GetTooltip(section)
		if type(tooltip) == "table" then
			return tooltip[key]
		end
		return nil
	end
	return Loc:GetTooltipNested(nil, { key })
end

local function getTooltipNested(section, keys)
	return Loc:GetTooltipNested(section, keys)
end

local function getMessage(section, key)
	return Loc:GetMessage(section, key)
end

local function getMessageNested(path)
	return Loc:GetMessageNested(path)
end

local function sendMessage(section, key, channel)
	local text = getMessage(section, key)
	if text then
		Necrosis_Msg(text, channel or "USER")
	end
end

-- State accessors already defined earlier in the file (lines ~145-150)
-- These are used throughout the module

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

NecrosisSpellTimersEnabled = NecrosisSpellTimersEnabled ~= false
NecrosisTimerEventsDirty = true

function Necrosis_FlagTimerEventRegistrationUpdate()
	NecrosisTimerEventsDirty = true
end

local function Necrosis_UpdateTimerFeatureState(enabled)
	enabled = not not enabled
	if NecrosisSpellTimersEnabled == enabled then
		return
	end
	NecrosisSpellTimersEnabled = enabled
	if enabled then
		if NecrosisSpellTimerButton then
			ShowUIPanel(NecrosisSpellTimerButton)
		end
		if type(Timers) == "table" and Timers.MarkTextDirty then
			Timers:MarkTextDirty()
		end
		if type(Necrosis_MarkTrackedBuffsDirty) == "function" then
			Necrosis_MarkTrackedBuffsDirty()
		end
	else
		if type(Timers) == "table" and Timers.RemoveAllTimers then
			Timers:RemoveAllTimers()
		end
		if NecrosisListSpells then
			NecrosisListSpells:SetText("")
		end
		if NecrosisSpellTimerButton then
			HideUIPanel(NecrosisSpellTimerButton)
		end
	end
	Necrosis_FlagTimerEventRegistrationUpdate()
	if type(Necrosis_HideGraphTimer) == "function" then
		Necrosis_HideGraphTimer()
	end
	if type(Necrosis_UpdateTimerEventRegistration) == "function" then
		Necrosis_UpdateTimerEventRegistration()
	end
	if type(Necrosis_UpdateTimerDisplay) == "function" then
		Necrosis_UpdateTimerDisplay()
	end
end

function Necrosis_HandleSpellTimerPreference()
	local enabled = NecrosisConfig and NecrosisConfig.ShowSpellTimers
	Necrosis_UpdateTimerFeatureState(enabled and true or false)
end

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
	lastMemUsage = 0,
}

local function Necrosis_LogDiagnostics(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

function Necrosis_RecordHelperDiag(name, beforeTime)
	if not (NecrosisConfig and NecrosisConfig.DiagnosticsEnabled) then
		return
	end
	local afterTime = debugprofilestop()
	local delta = afterTime - beforeTime
	local helper = UpdateDiagnostics.helpers[name]
	if not helper then
		helper = { calls = 0, time = 0 }
		UpdateDiagnostics.helpers[name] = helper
	end
	helper.calls = helper.calls + 1
	helper.time = helper.time + delta
end

function Necrosis_TrackUpdateDiagnostics(elapsed)
	if not (NecrosisConfig and NecrosisConfig.DiagnosticsEnabled) then
		UpdateDiagnostics.lastLogTime = GetTime()
		UpdateDiagnostics.frameCount = 0
		UpdateDiagnostics.elapsedTotal = 0
		wipe_helper_table(UpdateDiagnostics.helpers)
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
	local memDelta = memUsage - UpdateDiagnostics.lastMemUsage
	local pendingScan = BagState and BagState.pending and "true" or "false"
	local timerEngine = _G.TimerEngine
	local segmentCount = timerEngine and timerEngine.textSegments and table.getn(timerEngine.textSegments) or 0
	local timerCount = Timers:GetTimerCount()

	local message = string.format(
		"|cffff7f00Necrosis|r OnUpdate %d frames, avg %.3f ms, mem %.1f KB (%+.1f), bagPending=%s, segments=%d, timers=%d",
		UpdateDiagnostics.frameCount,
		avgElapsed * 1000,
		memUsage,
		memDelta,
		pendingScan,
		segmentCount,
		timerCount
	)
	Necrosis_LogDiagnostics(message)

	for name, data in pairs(UpdateDiagnostics.helpers) do
		local avgTime = 0
		if data.calls > 0 then
			avgTime = data.time / data.calls
		end
		Necrosis_LogDiagnostics(
			string.format("  - %s: calls=%d, total=%.3f ms, avg=%.3f ms", name, data.calls, data.time, avgTime)
		)
	end

	UpdateDiagnostics.lastLogTime = now
	UpdateDiagnostics.frameCount = 0
	UpdateDiagnostics.elapsedTotal = 0
	UpdateDiagnostics.lastMemUsage = memUsage
	wipe_helper_table(UpdateDiagnostics.helpers)
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

function Necrosis_OnBagUpdate(_, bagId)
	if NecrosisConfig.SoulshardSort then
		SoulshardState.pendingSortCheck = true
	end
	Necrosis_FlagBagDirty(bagId)
	Necrosis_RequestBagScan(0)
end

local function Necrosis_HandleSelfBuffCast(spellIndex, activeSpellName, playerName, currentTime)
	if not spellIndex or not activeSpellName then
		return false
	end

	local data = Spells:Get(spellIndex)
	if not data or not data.Name then
		if Necrosis_IsTimerDebugEnabled() then
			Necrosis_DebugPrint("BuffCast", "no spell data", spellIndex)
		end
		return false
	end

	local debugEnabled = Necrosis_IsTimerDebugEnabled()
	local normalizedDataName = normalize_spell_name(data.Name)
	local normalizedActive = normalize_spell_name(activeSpellName)
	if normalizedActive ~= normalizedDataName then
		local fallback = normalize_spell_name(SpellCastName)
		if fallback == normalizedDataName then
			normalizedActive = fallback
			if debugEnabled then
				Necrosis_DebugPrint("BuffCast", "adjust", activeSpellName or "nil", "=>", fallback or "nil")
			end
		else
			if debugEnabled then
				Necrosis_DebugPrint(
					"BuffCast",
					"mismatch",
					normalizedActive or activeSpellName or "nil",
					"!=",
					normalizedDataName
				)
			end
			return false
		end
	end

	local duration = data.Length or 0
	if duration <= 0 then
		if debugEnabled then
			Necrosis_DebugPrint("BuffCast", normalizedDataName, "missing duration")
		end
		return false
	end

	local expiry = floor(currentTime + duration)

	if debugEnabled then
		Necrosis_DebugPrint(
			"BuffCast",
			normalizedDataName,
			string.format("duration=%d", duration),
			string.format("expiry=%d", expiry)
		)
	end

	local ensured = Necrosis_TouchSelfBuffTimer(
		spellIndex,
		data.Name,
		playerName,
		duration,
		expiry,
		data.Type,
		duration,
		nil,
		currentTime
	)

	if debugEnabled then
		Necrosis_DebugPrint("BuffCast", normalizedDataName, ensured and "ensure" or "skip")
	end

	return ensured
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

	local timerCount = Timers:GetTimerCount()
	if timerCount > 0 then
		Necrosis_PrintDiagnostic(string.format("  SpellTimers: %d entries", timerCount))
		Timers:IterateTimers(function(timer)
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

function Necrosis_OnSpellcastStart(spellName)
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

function Necrosis_ClearSpellcastContext()
	SpellCastName = nil
	SpellCastRank = nil
	SpellTargetName = nil
end

function Necrosis_SetTradeRequest(active)
	TradeState.requested = active
end

function Necrosis_ShouldUpdateSpellState(curTime)
	if (curTime - SpellCastTime) < 1 then
		return false
	end
	SpellCastTime = curTime
	return true
end

function Necrosis_OnTargetChanged()
	if NecrosisConfig.AntiFearAlert and AntiFearState.currentTargetImmune then
		AntiFearState.currentTargetImmune = false
	end
	if type(Necrosis_RebuildTargetAuraCache) == "function" then
		Necrosis_RebuildTargetAuraCache()
	end
	AntiFearState.statusDirty = true
end

function Necrosis_HandleSelfFearDamage(message)
	if not NecrosisConfig.AntiFearAlert or not message then
		return
	end
	local fearName = Spells:GetName(13)
	local banishName = Spells:GetName(19)
	for spell, creatureName in string.gfind(message, NECROSIS_ANTI_FEAR_SRCH) do
		if spell == fearName or spell == banishName then
			AntiFearState.currentTargetImmune = true
			AntiFearState.statusDirty = true
			break
		end
	end
end

function Necrosis_OnSpellLearned()
	Necrosis_SpellSetup()
	Necrosis_CreateMenu()
	Necrosis_ButtonSetup()
end

function Necrosis_OnCombatEnd()
	CombatState.inCombat = false
	Timers:RemoveCombatTimers()
end

-- Hook system - must be defined before Necrosis_OnLoad which uses it
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

-- Helper function used by hook handlers - must be defined before Necrosis_UseAction
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

function Necrosis_OnLoad()
	Necrosis_Hook("UseAction", "Necrosis_UseAction", "before")
	Necrosis_Hook("CastSpell", "Necrosis_CastSpell", "before")
	Necrosis_Hook("CastSpellByName", "Necrosis_CastSpellByName", "before")

	if NecrosisButton then
		NecrosisButton:RegisterEvent("PLAYER_ENTERING_WORLD")
		NecrosisButton:RegisterEvent("PLAYER_LEAVING_WORLD")
		local events = Necrosis.Events
		if events and events.Iterate then
			for eventName in events:Iterate() do
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
	DemonState.type = UnitCreatureFamily("pet")

	-- Schedule spell refresh for next frame to ensure spellbook is loaded
	Necrosis_ScheduleSpellSetup()

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
	local enslaveName = Spells:GetName(10)
	-- If the new demon is enslaved, start a five-minute timer
	if enslaveName and Necrosis_UnitHasEffect("pet", enslaveName) then
		if not DemonState.enslaved then
			DemonState.enslaved = true
			if timerService then
				Timers:EnsureSpellIndexTimer(SpellIndex.ENSLAVE_DEMON, nil, nil, nil, nil, nil)
			end
		end
	else
		-- When the enslaved demon breaks free, remove the timer and warn the Warlock
		if DemonState.enslaved then
			DemonState.enslaved = false
			if timerService then
				Timers:RemoveTimerByName(enslaveName)
			end
			if NecrosisConfig.Sound then
				PlaySoundFile(NECROSIS_SOUND.EnslaveEnd)
			end
			local message = Loc:GetMessage("Information", "EnslaveBreak")
			if message then
				Necrosis_Msg(message, "USER")
			end
		end
	end

	-- If the demon is not enslaved, assign its title and update its name in Necrosis
	DemonState.type = UnitCreatureFamily("pet")
	for i = 1, 4, 1 do
		if
			DemonState.type == NECROSIS_PET_LOCAL_NAME[i]
			and NecrosisConfig.PetName[i] == " "
			and UnitName("pet") ~= UNKNOWNOBJECT
		then
			NecrosisConfig.PetName[i] = UnitName("pet")
			NecrosisLocalization()
			Necrosis_RefreshTimerNames()
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
	local felsteedName = Spells:GetName(1)
	local dreadsteedName = Spells:GetName(2)
	local dominationName = Spells:GetName(15)
	local amplifyName = Spells:GetName(42)
	local demonArmorName = Spells:GetName(31)
	local demonSkinName = Spells:GetName(36)
	if action == "BUFF" then
		-- Insert a timer when the Warlock gains Demon Sacrifice
		if arg1 == NECROSIS_TRANSLATION.SacrificeGain and timerService then
			Timers:EnsureSpellIndexTimer(SpellIndex.SACRIFICE, nil, nil, nil, nil, nil)
		end
		-- Update the mount button when the Warlock mounts
		if
			(felsteedName and string.find(arg1, felsteedName))
			or (dreadsteedName and string.find(arg1, dreadsteedName))
		then
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
		if dominationName and Spells:HasID(15) and string.find(arg1, dominationName) then
			BuffState.dominationUp = true
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 2)
		end
		-- Update the Amplify Curse button when active and start the cooldown timer
		if amplifyName and Spells:HasID(42) and string.find(arg1, amplifyName) then
			BuffState.amplifyUp = true
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 2)
		end
		-- Track Demon Armor/Skin on the player
		local playerName = UnitName("player") or ""
		if demonArmorName and string.find(arg1, demonArmorName) then
			if timerService then
				Timers:EnsureSpellIndexTimer(SpellIndex.DEMON_ARMOR, playerName, nil, nil, nil, nil)
				if Necrosis_IsTimerDebugEnabled() then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Armor timer (log)")
				end
			end
			BuffState.lastRefreshed = nil
		elseif demonSkinName and string.find(arg1, demonSkinName) then
			if timerService then
				Timers:EnsureSpellIndexTimer(SpellIndex.DEMON_SKIN, playerName, nil, nil, nil, nil)
				if Necrosis_IsTimerDebugEnabled() then
					Necrosis_DebugPrint("SelfEffect", "Inserted Demon Skin timer (log)")
				end
			end
			BuffState.lastRefreshed = nil
		else
			local trackedConfig = Necrosis_FindTrackedBuffConfigByName(arg1)
			if trackedConfig and not trackedConfig.spellIndex then
				local debugTimersEnabled = Necrosis_IsTimerDebugEnabled()
				Necrosis_RefreshSelfBuffTimer(trackedConfig, playerName, GetTime(), nil, debugTimersEnabled)
				BuffState.lastRefreshed = nil
			end
		end
	else
		-- Update the mount button when the Warlock dismounts
		if
			(felsteedName and string.find(arg1, felsteedName))
			or (dreadsteedName and string.find(arg1, dreadsteedName))
		then
			MountState.active = false
			MountState.notify = true
			Necrosis_SetButtonTexture(NecrosisMountButton, "MountButton", 1)
		end
		-- Change the Domination button when the Warlock is no longer under its effect
		if dominationName and Spells:HasID(15) and string.find(arg1, dominationName) then
			BuffState.dominationUp = false
			Necrosis_SetButtonTexture(NecrosisPetMenu1, "Domination", 3)
		end
		-- Change the Amplify Curse button when the Warlock leaves its effect
		if amplifyName and Spells:HasID(42) and string.find(arg1, amplifyName) then
			BuffState.amplifyUp = false
			Necrosis_SetButtonTexture(NecrosisCurseMenu1, "Amplify", 3)
		end
		-- Remove tracked buff timers when they fade
		if not Necrosis_RemoveTrackedBuffTimerForMessage(arg1) and timerService then
			if demonArmorName and string.find(arg1, demonArmorName) then
				Timers:RemoveTimerByName(demonArmorName)
			elseif demonSkinName and string.find(arg1, demonSkinName) then
				Timers:RemoveTimerByName(demonSkinName)
			end
		end
	end
	return
end

-- Menu IDs for TurtleWoW stones (used in LastCast.Stone.id)
-- Must be defined before StoneCastDefinitions uses it
local STONE_MENU_ID = {
	FELSTONE = 1,
	WRATHSTONE = 2,
	VOIDSTONE = 3,
	FIRESTONE = 4,
}

-- Stone cast definitions table - must be defined before Necrosis_SpellManagement uses it
local StoneCastDefinitions = {
	[STONE_MENU_ID.FELSTONE] = { inventoryKey = "Felstone", stoneIndex = 5 },
	[STONE_MENU_ID.WRATHSTONE] = { inventoryKey = "Wrathstone", stoneIndex = 6 },
	[STONE_MENU_ID.VOIDSTONE] = { inventoryKey = "Voidstone", stoneIndex = 7 },
	[STONE_MENU_ID.FIRESTONE] = { inventoryKey = "Firestone", stoneIndex = 4 },
}

-- Helper function to detect stone creation spells - must be before Necrosis_SpellManagement
local function handleStoneCreation(stoneName)
	-- Find the config entry by matching inventoryKey
	local menuId, config = nil, nil
	for id, def in pairs(StoneCastDefinitions) do
		if def.inventoryKey == stoneName then
			menuId = id
			config = def
			break
		end
	end

	if not config then
		return false
	end

	if StoneIDInSpellTable[config.stoneIndex] == 0 then
		return false
	end

	local spellName = Spells:GetName(StoneIDInSpellTable[config.stoneIndex])
	if SpellCastName == spellName then
		LastCast.Stone.id = menuId
		LastCast.Stone.click = "LeftButton"
		return true
	end
	return false
end

-- Forward declaration for handleSelfBuffTimer (defined later in file)
local handleSelfBuffTimer

-- event : SPELLCAST_STOP
-- Handles everything related to spells after they finish casting
function Necrosis_SpellManagement()
	local SortActif = false
	local timerService = getTimerService()
	local soulstoneName = Spells:GetName(11)
	local demonArmorName = Spells:GetName(31)
	local demonSkinName = Spells:GetName(36)
	local shadowWardName = Spells:GetName(43)
	Necrosis_DebugPrint(
		"Necrosis_SpellManagement",
		"SpellCastName=",
		SpellCastName or "nil",
		"Target=",
		SpellTargetName or "nil"
	)
	if SpellCastName then
		-- If the spell was Soulstone Resurrection, start its timer
		if SpellCastName == soulstoneName then
			if SpellTargetName == UnitName("player") then
				SpellTargetName = ""
			end
			-- If messaging is enabled and the stone is used on the targeted player, broadcast the alert!
			if (NecrosisConfig.ChatMsg or NecrosisConfig.SM) and SoulstoneUsedOnTarget then
				SoulstoneState_Internal.target = SpellTargetName
				SoulstoneState_Internal.pendingAdvice = true
			end
			if timerService then
				Timers:EnsureSpellIndexTimer(SpellIndex.SOULSTONE_RESURRECTION, SpellTargetName, nil, nil, nil, nil)
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
		-- Check TurtleWoW stone creation (Felstone, Wrathstone, Voidstone, Firestone)
		else
			local stoneHandled = false
			for _, stoneConfig in pairs(StoneCastDefinitions) do
				if handleStoneCreation(stoneConfig.inventoryKey) then
					stoneHandled = true
					break
				end
			end
			-- For other spells, continue to general spell timer logic
			if not stoneHandled then
				if SpellCastName == demonArmorName or SpellCastName == demonSkinName then
					local playerName = UnitName("player") or ""
					local now = GetTime()
					local armorIndex = SpellIndex and SpellIndex.DEMON_ARMOR or 31
					local skinIndex = SpellIndex and SpellIndex.DEMON_SKIN or 36
					local spellIndex = SpellCastName == demonArmorName and armorIndex or skinIndex
					local castName = SpellCastName
					if not castName or castName == "" then
						castName = spellIndex == armorIndex and demonArmorName or demonSkinName
					end
					-- Try the self-buff handler first
					local handled = Necrosis_HandleSelfBuffCast(spellIndex, castName, playerName, now)
					if not handled then
						handleSelfBuffTimer(spellIndex, castName, playerName)
					end
				elseif shadowWardName and SpellCastName == shadowWardName then
					handleSelfBuffTimer(SpellIndex.SHADOW_WARD, shadowWardName, UnitName("player") or "")
				else
					if timerService then
						Spells:Iterate(function(spellData, spell)
							if
								not spellData
								or not spellData.Name
								or SpellCastName ~= spellData.Name
								or spell == 10
							then
								return true
							end

							if spellData.Type ~= 4 and spell ~= 16 then
								if not (spell == 9 and Necrosis_UnitHasEffect("target", SpellCastName)) then
									local refreshDuration = spellData.Length
									if spell == 9 and SpellCastRank == 1 then
										refreshDuration = 20
									end
									local refreshed = Timers:UpdateTimer(SpellCastName, SpellTargetName, function(timer)
										timer.Time = refreshDuration
										timer.TimeMax = floor(GetTime() + refreshDuration)
										return true
									end)
									if refreshed then
										SortActif = true
									end
								end
							end

							if spell == 9 then
								Timers:IterateTimers(function(timer, index)
									if timer.Name == SpellCastName and timer.Target ~= SpellTargetName then
										Timers:RemoveTimerByIndex(index)
										SortActif = false
										return false
									end
								end)
							end

							if spell == 13 then
								Timers:IterateTimers(function(timer, index)
									if timer.Name == SpellCastName then
										Timers:RemoveTimerByIndex(index)
										SortActif = false
										return false
									end
								end)
							end

							if (spellData.Type == 4) or (spell == 16) then
								local banishData = Spells:Get(SpellIndex.CURSE_OF_DOOM)
								local banishName = banishData and banishData.Name
								Timers:IterateTimers(function(timer, index)
									if banishName and timer.Name == banishName then
										Timers:UpdateTimer(timer.Name, timer.Target, function(updateTarget)
											updateTarget.Target = ""
											return false
										end)
									end
									if timer.Type == 4 and timer.Target == SpellTargetName then
										Timers:RemoveTimerByIndex(index)
										return false
									end
								end)
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

								Timers:EnsureSpellIndexTimer(spell, SpellTargetName, nil, nil, nil, nil)
								return false
							end

							return true
						end)
					end
				end -- close: if not stoneHandled
			end -- close: else (stone creation check)
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
		local demonButtonId = getSpellId(41)
		if demonButtonId then
			CastSpell(demonButtonId, "spell")
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
	local timerSlots = Timers:GetTimerSlots()
	for i = 1, 50, 1 do
		local elements = { "Text", "Bar", "Texture", "OutText" }
		if NecrosisConfig.Graphical then
			if timerSlots and timerSlots[i] then
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

------------------------------------------------------------------------------------------------------
-- TOOLTIP HELPER FUNCTIONS
-- Extracted common patterns to reduce duplication and improve maintainability
------------------------------------------------------------------------------------------------------

-- Build a lookup table from stone name to its index in StoneIDInSpellTable
-- This is derived from SpellScanContext.StoneType which is the authoritative source
-- Will be initialized after SpellScanContext is defined
local STONE_NAME_TO_INDEX

-- Tooltip line numbers for reading cooldown text from NecrosisTooltip
local TOOLTIP_COOLDOWN_LINE = {
	DEFAULT = 6, -- Most stones use line 6
	SPELLSTONE = 7, -- Spellstone uses line 7
	NONE = nil, -- Stones without cooldown display (Firestone, TurtleWoW stones)
}

-- Stone tooltip configuration: maps stone name to its properties
local STONE_TOOLTIP_CONFIG = {
	Soulstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.DEFAULT },
	Healthstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.DEFAULT },
	Spellstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.SPELLSTONE },
	Firestone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.NONE },
	Felstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.NONE },
	Wrathstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.NONE },
	Voidstone = { cooldownLine = TOOLTIP_COOLDOWN_LINE.NONE },
}

-- Helper: Add mana cost line to tooltip if available
local function addManaCostTooltip(spellIndex)
	if not spellIndex then
		return
	end
	local mana = getSpellMana(spellIndex)
	if mana then
		GameTooltip:AddLine(mana .. " Mana")
	end
end

-- Helper: Add stone cooldown information from bag item
local function addStoneCooldownFromBag(bag, slot, tooltipLine)
	if not bag or not slot or not tooltipLine then
		return
	end
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetBagItem(bag, slot)
	-- Get the cooldown text from the appropriate tooltip line
	local tooltipText = getglobal("NecrosisTooltipTextLeft" .. tooltipLine)
	if tooltipText then
		local itemName = tostring(tooltipText:GetText())
		if itemName and string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
			GameTooltip:AddLine(itemName)
		end
	end
end

-- Helper: Build stone tooltip (handles both creation and use modes)
-- Parameters:
--   stoneType: "Soulstone", "Healthstone", etc.
--   stoneTableIndex: index in StoneIDInSpellTable (use STONE_INDEX constants)
--   tooltipLineForCooldown: which tooltip line to read cooldown from (use TOOLTIP_COOLDOWN_LINE constants)
--   tooltipText: the localized tooltip text table
--   stoneMode: 1=create, 2=use, 3=soulstone special mode
local function buildStoneTooltip(stoneType, stoneTableIndex, tooltipLineForCooldown, tooltipText, stoneMode)
	local stoneData = StoneInventory[stoneType]
	if not stoneData then
		return
	end

	-- If in creation mode, show mana cost
	if stoneMode == 1 or (stoneType == "Soulstone" and stoneMode == 3) then
		local spellIndex = StoneIDInSpellTable[stoneTableIndex]
		addManaCostTooltip(spellIndex)
	end

	-- Show stone tooltip text based on mode
	if type(tooltipText) == "table" then
		local value = tooltipText[stoneMode]
		if value then
			GameTooltip:AddLine(value)
		end
	end

	-- If stone exists, check for cooldown
	if stoneData.onHand and stoneData.location[1] then
		addStoneCooldownFromBag(stoneData.location[1], stoneData.location[2], tooltipLineForCooldown)
	end
end

------------------------------------------------------------------------------------------------------
-- TOOLTIP MAIN FUNCTION
------------------------------------------------------------------------------------------------------

-- Function that manages tooltips
function Necrosis_BuildTooltip(button, tooltipType, anchor)
	-- If tooltips are disabled, exit immediately!
	if not NecrosisConfig.NecrosisToolTip then
		return
	end

	-- Check whether Fel Domination, Shadow Ward, or Curse Amplification are active (for tooltips)
	local start, duration = 1, 1
	local start2, duration2 = 1, 1
	local start3, duration3 = 1, 1
	local dominationId = getSpellId(15)
	if dominationId then
		start, duration = GetSpellCooldown(dominationId, BOOKTYPE_SPELL)
	end
	local shadowWardId = getSpellId(43)
	if shadowWardId then
		start2, duration2 = GetSpellCooldown(shadowWardId, BOOKTYPE_SPELL)
	end
	local amplifyId = getSpellId(42)
	if amplifyId then
		start3, duration3 = GetSpellCooldown(amplifyId, BOOKTYPE_SPELL)
	end

	local tooltip = getTooltipData(tooltipType)
	local mainTooltip = getTooltipData("Main")
	local tooltipText = tooltip.Text
	local function addTooltipText(index)
		if _G.type(tooltipText) == "table" then
			local value = tooltipText[index]
			if value then
				GameTooltip:AddLine(value)
			end
		end
	end
	local amplifyCooldownText = getTooltipField(nil, "AmplifyCooldown")
	local dominationCooldownText = getTooltipField(nil, "DominationCooldown")
	local lastSpellPrefix = getTooltipField(nil, "LastSpell") or ""

	-- Create the tooltips....
	GameTooltip:SetOwner(button, anchor)
	GameTooltip:SetText(tooltip.Label or "")
	-- ..... for the main button
	if tooltipType == "Main" then
		GameTooltip:AddLine((mainTooltip.Soulshard or "") .. SoulshardState.count)
		GameTooltip:AddLine((mainTooltip.InfernalStone or "") .. ComponentState.infernal)
		GameTooltip:AddLine((mainTooltip.DemoniacStone or "") .. ComponentState.demoniac)
		local stoneText = tooltip.Stone or {}
		GameTooltip:AddLine((mainTooltip.Soulstone or "") .. tostring(stoneText[StoneInventory.Soulstone.onHand] or ""))
		GameTooltip:AddLine(
			(mainTooltip.Healthstone or "") .. tostring(stoneText[StoneInventory.Healthstone.onHand] or "")
		)
		-- Display the demon's name, show if it is enslaved, or "None" when no demon is present
		if DemonState.type then
			GameTooltip:AddLine((mainTooltip.CurrentDemon or "") .. DemonState.type)
		elseif DemonState.enslaved then
			GameTooltip:AddLine(mainTooltip.EnslavedDemon or "")
		else
			GameTooltip:AddLine(mainTooltip.NoCurrentDemon or "")
		end
	-- ..... for the stone buttons
	elseif string.find(tooltipType, "stone") then
		-- Unified stone tooltip handler using configuration
		local stoneConfig = STONE_TOOLTIP_CONFIG[tooltipType]
		if stoneConfig then
			local stoneIndex = STONE_NAME_TO_INDEX[tooltipType]
			local stoneData = StoneInventory[tooltipType]

			-- Determine stone mode:
			-- - If stone has .mode property (Soulstone/Healthstone/Spellstone), use it
			-- - Otherwise use .onHand to determine mode (TurtleWoW stones: onHand=true → mode 2, else mode 1)
			local stoneMode = (stoneData and stoneData.mode) or (stoneData and stoneData.onHand and 2 or 1) or 1

			buildStoneTooltip(tooltipType, stoneIndex, stoneConfig.cooldownLine, tooltipText, stoneMode)
		end
	-- ..... for the timer button
	elseif tooltipType == "SpellTimer" then
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetBagItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		local itemName = tostring(NecrosisTooltipTextLeft5:GetText())
		if type(tooltipText) == "string" then
			GameTooltip:AddLine(tooltipText)
		end
		if string.find(itemName, NECROSIS_TRANSLATION.Cooldown) then
			GameTooltip:AddLine(NECROSIS_TRANSLATION.Hearth .. " - " .. itemName)
		else
			GameTooltip:AddLine((tooltip.Right or "") .. GetBindLocation())
		end

	-- ..... for the Shadow Trance button
	elseif tooltipType == "ShadowTrance" then
		local rank = Necrosis_FindSpellAttribute("Name", NECROSIS_NIGHTFALL.BoltName, "Rank")
		GameTooltip:SetText((tooltip.Label or "") .. "          |CFF808080Rank " .. rank .. "|r")
	-- ..... for the other buffs and demons, the mana cost...
	elseif tooltipType == "Enslave" then
		addManaCostTooltip(SpellIndex.ENSLAVE_DEMON_EFFECT)
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.Soulshard or "") .. SoulshardState.count .. "|r")
		end
	elseif tooltipType == "Mount" then
		if hasSpell(SpellIndex.SUMMON_DREADSTEED) then
			addManaCostTooltip(SpellIndex.SUMMON_DREADSTEED)
		elseif hasSpell(SpellIndex.SUMMON_FELSTEED) then
			addManaCostTooltip(SpellIndex.SUMMON_FELSTEED)
		end
	elseif tooltipType == "Armor" then
		if hasSpell(SpellIndex.DEMON_ARMOR) then
			addManaCostTooltip(SpellIndex.DEMON_ARMOR)
		else
			addManaCostTooltip(SpellIndex.DEMON_SKIN)
		end
	elseif tooltipType == "Invisible" then
		addManaCostTooltip(SpellIndex.DETECT_INVISIBILITY)
	elseif tooltipType == "Aqua" then
		addManaCostTooltip(SpellIndex.UNENDING_BREATH)
	elseif tooltipType == "Kilrogg" then
		addManaCostTooltip(SpellIndex.EYE_OF_KILROGG)
	elseif tooltipType == "Banish" then
		addManaCostTooltip(SpellIndex.BANISH)
	elseif tooltipType == "Weakness" then
		addManaCostTooltip(SpellIndex.CURSE_OF_WEAKNESS)
		if not (start3 > 0 and duration3 > 0) then
			if amplifyCooldownText then
				GameTooltip:AddLine(amplifyCooldownText)
			end
		end
	elseif tooltipType == "Agony" then
		addManaCostTooltip(SpellIndex.CURSE_OF_AGONY)
		if not (start3 > 0 and duration3 > 0) then
			if amplifyCooldownText then
				GameTooltip:AddLine(amplifyCooldownText)
			end
		end
	elseif tooltipType == "Reckless" then
		addManaCostTooltip(SpellIndex.CURSE_OF_RECKLESSNESS)
	elseif tooltipType == "Tongues" then
		addManaCostTooltip(SpellIndex.CURSE_OF_TONGUES)
	elseif tooltipType == "Exhaust" then
		addManaCostTooltip(SpellIndex.CURSE_OF_EXHAUSTION)
		if not (start3 > 0 and duration3 > 0) then
			if amplifyCooldownText then
				GameTooltip:AddLine(amplifyCooldownText)
			end
		end
	elseif tooltipType == "Elements" then
		addManaCostTooltip(SpellIndex.CURSE_OF_THE_ELEMENTS)
	elseif tooltipType == "Shadow" then
		addManaCostTooltip(SpellIndex.CURSE_OF_SHADOW)
	elseif tooltipType == "Doom" then
		addManaCostTooltip(SpellIndex.CURSE_OF_DOOM)
	elseif tooltipType == "Amplify" then
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
	elseif tooltipType == "TP" then
		addManaCostTooltip(SpellIndex.RITUAL_OF_SUMMONING)
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.Soulshard or "") .. SoulshardState.count .. "|r")
		end
	elseif tooltipType == "SoulLink" then
		addManaCostTooltip(SpellIndex.SOUL_LINK)
	elseif tooltipType == "ShadowProtection" then
		addManaCostTooltip(SpellIndex.SHADOW_WARD)
		if start2 > 0 and duration2 > 0 then
			local seconde = duration2 - (GetTime() - start2)
			local affiche
			affiche = tostring(floor(seconde)) .. " sec"
			GameTooltip:AddLine("Cooldown : " .. affiche)
		end
	elseif tooltipType == "Domination" then
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
	elseif tooltipType == "Imp" then
		addManaCostTooltip(SpellIndex.SUMMON_IMP)
		if not (start > 0 and duration > 0) then
			if dominationCooldownText then
				GameTooltip:AddLine(dominationCooldownText)
			end
		end
	elseif tooltipType == "Void" then
		addManaCostTooltip(SpellIndex.SUMMON_VOIDWALKER)
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.Soulshard or "") .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			if dominationCooldownText then
				GameTooltip:AddLine(dominationCooldownText)
			end
		end
	elseif tooltipType == "Succubus" then
		addManaCostTooltip(SpellIndex.SUMMON_SUCCUBUS)
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.Soulshard or "") .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			if dominationCooldownText then
				GameTooltip:AddLine(dominationCooldownText)
			end
		end
	elseif tooltipType == "Fel" then
		addManaCostTooltip(SpellIndex.SUMMON_FELHUNTER)
		if SoulshardState.count == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.Soulshard or "") .. SoulshardState.count .. "|r")
		elseif not (start > 0 and duration > 0) then
			if dominationCooldownText then
				GameTooltip:AddLine(dominationCooldownText)
			end
		end
	elseif tooltipType == "Infernal" then
		addManaCostTooltip(SpellIndex.INFERNO)
		if ComponentState.infernal == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.InfernalStone or "") .. ComponentState.infernal .. "|r")
		else
			GameTooltip:AddLine((mainTooltip.InfernalStone or "") .. ComponentState.infernal)
		end
	elseif tooltipType == "Doomguard" then
		addManaCostTooltip(SpellIndex.RITUAL_OF_DOOM)
		if ComponentState.demoniac == 0 then
			GameTooltip:AddLine("|c00FF4444" .. (mainTooltip.DemoniacStone or "") .. ComponentState.demoniac .. "|r")
		else
			GameTooltip:AddLine((mainTooltip.DemoniacStone or "") .. ComponentState.demoniac)
		end
	elseif (type == "Buff") and LastCast.Buff ~= 0 then
		local spellName = getSpellNameByIndex(LastCast.Buff)
		if spellName then
			GameTooltip:AddLine(lastSpellPrefix .. spellName)
		end
	elseif (type == "Curse") and LastCast.Curse.id ~= 0 then
		local spellName = getSpellNameByIndex(LastCast.Curse.id)
		if spellName then
			GameTooltip:AddLine(lastSpellPrefix .. spellName)
		end
	elseif (type == "Pet") and LastCast.Demon ~= 0 then
		GameTooltip:AddLine(lastSpellPrefix .. NECROSIS_PET_LOCAL_NAME[(LastCast.Demon - 2)])
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
			GameTooltip:AddLine(lastSpellPrefix .. stoneName)
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
--
-- OPTIMIZED: Single-pass algorithm with reusable tables to minimize allocations
local SpellScanContext = {
	-- Reusable tables (allocated once, cleared and reused each scan)
	currentSpellIndexByName = {},
	CurrentSpells = {
		ID = {},
		Name = {},
		subName = {},
	},
	CurrentStone = {
		ID = {},
		Name = {},
		subName = {},
	},
	StoneMaxRank = { 0, 0, 0, 0, 0, 0, 0 },
	-- Stone types (constant, allocated once)
	StoneType = {
		NECROSIS_ITEM.Soulstone,
		NECROSIS_ITEM.Healthstone,
		NECROSIS_ITEM.Spellstone,
		NECROSIS_ITEM.Firestone,
		NECROSIS_ITEM.Felstone,
		NECROSIS_ITEM.Wrathstone,
		NECROSIS_ITEM.Voidstone,
	},
}

-- Now that SpellScanContext is defined, build the stone name lookup table
-- NOTE: This must be called AFTER NecrosisLocalization() has run to ensure NECROSIS_ITEM is defined
local function buildStoneNameToIndexLookup()
	local lookup = {}
	local stoneTypes = SpellScanContext.StoneType
	if not stoneTypes then
		return lookup
	end
	for index = 1, table.getn(stoneTypes) do
		local stoneName = stoneTypes[index]
		if stoneName then
			lookup[stoneName] = index
		end
	end
	return lookup
end

-- Initialize the lookup table LAZILY (will be built in Necrosis_SpellSetup after localization)
-- Do NOT initialize here as NECROSIS_ITEM may not be defined yet
if not STONE_NAME_TO_INDEX then
	STONE_NAME_TO_INDEX = {}
end

-- Refresh timer display names after language change
-- This updates spell names in active timers to match the new language
-- Clear all active timers (used when language changes)
-- This is simpler and more reliable than trying to update timer names in-place
-- Timers will rebuild naturally as spells are cast and buffs refresh
function Necrosis_ClearAllTimers()
	local timerService = getTimerService()
	if not timerService then
		return
	end

	-- Clear all timers
	if timerService.timers then
		wipe_table(timerService.timers)
	end
	if timerService.timerSlots then
		wipe_table(timerService.timerSlots)
	end
	if timerService.graphical then
		timerService.graphical.activeCount = 0
		if timerService.graphical.names then
			wipe_table(timerService.graphical.names)
		end
		if timerService.graphical.expiryTimes then
			wipe_table(timerService.graphical.expiryTimes)
		end
		if timerService.graphical.initialDurations then
			wipe_table(timerService.graphical.initialDurations)
		end
		if timerService.graphical.displayLines then
			wipe_table(timerService.graphical.displayLines)
		end
		if timerService.graphical.slotIds then
			wipe_table(timerService.graphical.slotIds)
		end
	end

	-- Mark display as needing rebuild
	if type(Timers) == "table" and type(Timers.MarkTextDirty) == "function" then
		Timers:MarkTextDirty()
	end

	Necrosis_DebugPrint("Necrosis_ClearAllTimers: All timers cleared for language change")
end

function Necrosis_SpellSetup()
	-- Invalidate spell name cache since spell table is being rebuilt
	if type(Necrosis_InvalidateSpellNameCache) == "function" then
		Necrosis_InvalidateSpellNameCache()
	end

	-- Build stone name lookup if not already done (must happen AFTER NecrosisLocalization())
	if not STONE_NAME_TO_INDEX or not next(STONE_NAME_TO_INDEX) then
		STONE_NAME_TO_INDEX = buildStoneNameToIndexLookup()
	end

	-- Reuse tables from context (clear without deallocating)
	local ctx = SpellScanContext
	local currentSpellIndexByName = ctx.currentSpellIndexByName
	local CurrentSpells = ctx.CurrentSpells
	local CurrentStone = ctx.CurrentStone
	local StoneMaxRank = ctx.StoneMaxRank
	local StoneType = ctx.StoneType

	-- Clear previous scan results
	wipe_table(currentSpellIndexByName)
	wipe_table(CurrentSpells.ID)
	wipe_table(CurrentSpells.Name)
	wipe_table(CurrentSpells.subName)
	wipe_table(CurrentStone.ID)
	wipe_table(CurrentStone.Name)
	wipe_table(CurrentStone.subName)
	for i = 1, 7 do
		StoneMaxRank[i] = 0
		-- Clear old stone references - we'll rebuild them
		StoneIDInSpellTable[i] = 0
	end

	local spellID = 1
	local Invisible = 0
	local InvisibleID = 0

	-- SINGLE PASS: Iterate through every spell the Warlock knows
	while true do
		local spellName, subSpellName = GetSpellName(spellID, BOOKTYPE_SPELL)

		if not spellName then
			break
		end

		-- For spells with numbered ranks, compare each rank one by one
		-- Keep the highest rank
		if subSpellName and string.find(subSpellName, NECROSIS_TRANSLATION.Rank) then
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
		else
			-- For rank-less spells, check if they match any spell table entry
			-- This handles spells like "Summon Felsteed" and "Summon Dreadsteed"
			if not currentSpellIndexByName[spellName] then
				for tableIndex = 1, table.getn(NECROSIS_SPELL_TABLE) do
					local tableEntry = NECROSIS_SPELL_TABLE[tableIndex]
					if tableEntry and tableEntry.Name == spellName then
						local newIndex = table.getn(CurrentSpells.Name) + 1
						CurrentSpells.ID[newIndex] = spellID
						CurrentSpells.Name[newIndex] = spellName
						CurrentSpells.subName[newIndex] = 0
						currentSpellIndexByName[spellName] = newIndex
						break
					end
				end
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

	-- Insert or update the stones of the highest rank into the table
	for stoneID = 1, table.getn(StoneType), 1 do
		if StoneMaxRank[stoneID] ~= 0 then
			-- Check if we already have a slot for this stone type
			-- (from NECROSIS_SPELL_TEMPLATE or previous scan)
			local existingIndex = nil
			for idx = 1, table.getn(NECROSIS_SPELL_TABLE) do
				local entry = NECROSIS_SPELL_TABLE[idx]
				if entry and entry.Name == CurrentStone.Name[stoneID] then
					existingIndex = idx
					break
				end
			end

			if existingIndex then
				-- Update existing entry
				local entry = NECROSIS_SPELL_TABLE[existingIndex]
				entry.ID = CurrentStone.ID[stoneID]
				entry.Name = CurrentStone.Name[stoneID]
				entry.Rank = 0
				entry.CastTime = 0
				entry.Length = 0
				entry.Type = 0
				StoneIDInSpellTable[stoneID] = existingIndex
			else
				-- Insert new entry
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
	end

	-- Refresh the spell list with the new ranks
	local totalSpellCount = table.getn(NECROSIS_SPELL_TABLE)
	for spell = 1, totalSpellCount, 1 do
		local spellData = Spells:Get(spell)
		local name = spellData and spellData.Name
		local index = currentSpellIndexByName[name]
		if spellData and index then
			local spellId = spellData.ID
			if
				spellId ~= StoneIDInSpellTable[1]
				and spellId ~= StoneIDInSpellTable[2]
				and spellId ~= StoneIDInSpellTable[3]
				and spellId ~= StoneIDInSpellTable[4]
			then
				spellData.ID = CurrentSpells.ID[index]
				spellData.Rank = CurrentSpells.subName[index]
			end
		end
	end

	-- Update each spell duration based on its rank
	for index = 1, totalSpellCount, 1 do
		local spellData = Spells:Get(index)
		if index == 9 then -- si Bannish
			if spellData and spellData.ID ~= nil then
				spellData.Length = spellData.Rank * 10 + 10
			end
		end
		if index == 13 then -- si Fear
			if spellData and spellData.ID ~= nil then
				spellData.Length = spellData.Rank * 5 + 5
			end
		end
		if index == 14 then -- si Corruption
			if spellData and spellData.ID ~= nil and spellData.Rank <= 2 then
				spellData.Length = spellData.Rank * 3 + 9
			end
		end
		if index == 43 then -- Shadow Ward (30 second buff duration)
			if spellData and spellData.ID ~= nil then
				spellData.Length = 30
			end
		end
	end

	-- Rebuild tracked buffs now that spell durations are updated
	if type(Necrosis_RebuildDefaultTrackedBuffs) == "function" then
		Necrosis_RebuildDefaultTrackedBuffs()
	end

	-- OPTIMIZED: Extract mana costs inline (no second full scan)
	-- We still need to scan spell book again, but we can early-exit once all known spells are found
	local spellsToFind = {}
	for index = 1, totalSpellCount, 1 do
		local spellData = Spells:Get(index)
		if spellData and spellData.Name then
			spellsToFind[spellData.Name] = index
		end
	end

	local foundCount = 0
	local totalToFind = Necrosis_CountTableEntries(spellsToFind)

	for spellID = 1, MAX_SPELLS, 1 do
		if foundCount >= totalToFind then
			break -- Early exit: all spells found
		end

		local spellName, subSpellName = GetSpellName(spellID, "spell")
		if spellName then
			local index = spellsToFind[spellName]
			if index then
				local spellData = Spells:Get(index)
				if spellData then
					Necrosis_MoneyToggle()
					NecrosisTooltip:SetSpell(spellID, 1)
					local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
					if not spellData.ID then
						spellData.ID = spellID
					end
					spellData.Mana = tonumber(ManaCost)
					spellsToFind[spellName] = nil -- Mark as found
					foundCount = foundCount + 1
				end
			end
		end
	end

	MountState.available = not not (hasSpell(SpellIndex.SUMMON_FELSTEED) or hasSpell(SpellIndex.SUMMON_DREADSTEED))

	-- Insert the highest known rank of Detect Invisibility
	if Invisible >= 1 then
		local detectData = Spells:Get(SpellIndex.DETECT_INVISIBILITY)
		if detectData then
			detectData.ID = InvisibleID
			detectData.Rank = 0
			detectData.CastTime = 0
			detectData.Length = 0
		end
		Necrosis_MoneyToggle()
		NecrosisTooltip:SetSpell(InvisibleID, 1)
		local _, _, ManaCost = string.find(NecrosisTooltipTextLeft2:GetText(), "(%d+)")
		if detectData then
			detectData.Mana = tonumber(ManaCost)
		end
	end
end

-- Function that extracts spell attributes
-- F(fieldName=string, string, string) -> any
function Necrosis_FindSpellAttribute(fieldName, attribute, resultKey)
	for index = 1, table.getn(NECROSIS_SPELL_TABLE), 1 do
		local spellData = Spells:Get(index)
		if spellData then
			local value = spellData[fieldName]
			if type(value) == "string" and string.find(value, attribute) then
				return spellData[resultKey]
			end
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
-- SPELL CAST HANDLERS
-- Decomposed from Necrosis_SpellManagement for clarity and maintainability
------------------------------------------------------------------------------------------------------

-- Helper: Create or update a self-buff timer (for Demon Armor, Shadow Ward, etc.)
handleSelfBuffTimer = function(spellIndex, spellName, playerName)
	local timerService = getTimerService()
	if not timerService then
		return
	end

	local spellData = Spells:Get(spellIndex)
	if not spellData then
		return
	end

	local duration = spellData.Length or 0
	local expiry = duration > 0 and floor(GetTime() + duration) or nil
	local timerType = spellData.Type

	-- Try to update existing timer first
	local updated = Timers:UpdateTimerEntry(spellName, playerName, duration, expiry, timerType, duration)
	if not updated then
		-- Create new timer if no existing one
		Timers:EnsureSpellIndexTimer(spellIndex, playerName, duration, timerType, duration, expiry)
	elseif DEBUG_TIMER_EVENTS then
		Necrosis_DebugPrint("Timer refreshed", spellName, duration)
	end
end

------------------------------------------------------------------------------------------------------
-- STONE OPERATION HELPERS
-- Extracted common stone operations to reduce duplication
------------------------------------------------------------------------------------------------------

-- Helper: Create a stone by casting its spell
-- Returns: true if cast succeeded, false if failed
local function createStone(stoneIndex, errorMessageKey)
	local spellIndex = StoneIDInSpellTable[stoneIndex]
	if spellIndex ~= 0 and castSpellByIndex(spellIndex) then
		return true
	else
		sendMessage("Error", errorMessageKey)
		return false
	end
end

-- Helper: Use a stone from inventory
-- Returns: true if used, false if not available
local function useStoneFromInventory(stoneData)
	if not stoneData or not stoneData.onHand then
		return false
	end
	UseContainerItem(stoneData.location[1], stoneData.location[2])
	return true
end

-- Helper: Check if stone is on cooldown
-- Returns: true if on cooldown, false if ready
local function isStoneOnCooldown(stoneData)
	if not stoneData or not stoneData.onHand then
		return false
	end
	local start, duration, enabled = GetContainerItemCooldown(stoneData.location[1], stoneData.location[2])
	return start > 0
end

-- Helper: Add timer for stone usage (with optional shared cooldown)
local function addStoneCooldownTimer(timerName, sharedTimerName, spellIndexToCheck)
	local timerService = getTimerService()
	if not timerService then
		return
	end

	-- Add primary timer if not already exists
	if not Necrosis_TimerExists(timerName) then
		Timers:EnsureNamedTimer(timerName, 120, TIMER_TYPE.SELF_BUFF, nil, 120, nil)
	end

	-- Add shared cooldown timer if applicable
	if sharedTimerName and spellIndexToCheck and StoneIDInSpellTable[spellIndexToCheck] ~= 0 then
		if not Necrosis_TimerExists(sharedTimerName) then
			Timers:EnsureNamedTimer(sharedTimerName, 120, TIMER_TYPE.SELF_BUFF, nil, 120, nil)
		end
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

function Necrosis_UseItem(tooltipType, button)
	Necrosis_MoneyToggle()
	NecrosisTooltip:SetBagItem("player", 17)
	local rightHand = tostring(NecrosisTooltipTextLeft1:GetText())
	local timerService = getTimerService()

	-- Function that uses a hearthstone from the inventory
	-- if one is in the inventory and it was a right-click
	if tooltipType == "Hearthstone" and button == "RightButton" then
		if StoneInventory.Hearthstone.onHand then
			-- use it
			UseContainerItem(StoneInventory.Hearthstone.location[1], StoneInventory.Hearthstone.location[2])
		-- or, if none are in the inventory, show an error message
		else
			sendMessage("Error", "NoHearthStone")
		end
	end

	-- When clicking the Soulstone button
	-- Update the button to indicate the current mode
	if tooltipType == "Soulstone" then
		Necrosis_UpdateIcons()
		-- If mode = 2 (stone in inventory, none in use), use it
		if StoneInventory.Soulstone.mode == 2 then
			-- If a player is targeted, cast on them (with alert message)
			-- If no player is targeted, cast on the Warlock (without a message)
			if UnitIsPlayer("target") then
				SoulstoneUsedOnTarget = true
			else
				SoulstoneUsedOnTarget = false
				TargetUnit("player")
			end
			useStoneFromInventory(StoneInventory.Soulstone)
			-- Now that timers persist across the session, we no longer reset when relogging
			InitState.reloadFlag = false
			-- Refresh the button display
			Necrosis_UpdateIcons()
		-- If no Soulstone is in the inventory, create the highest-rank Soulstone
		elseif (StoneInventory.Soulstone.mode == 1) or (StoneInventory.Soulstone.mode == 3) then
			createStone(1, "NoSoulStoneSpell")
		end
	-- When clicking the Healthstone button:
	elseif tooltipType == "Healthstone" then
		-- If stone is in inventory, use it (with trade/give logic)
		if StoneInventory.Healthstone.onHand then
			-- Handle trade request
			if TradeState.requested then
				PickupContainerItem(StoneInventory.Healthstone.location[1], StoneInventory.Healthstone.location[2])
				ClickTradeButton(1)
				TradeState.requested = false
				TradeState.active = true
				TradeState.countdown = 3
				return
			-- Handle give to friendly target
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
			-- Use on self
			if UnitHealth("player") == UnitHealthMax("player") then
				sendMessage("Error", "FullHealth")
			else
				SpellStopCasting()
				useStoneFromInventory(StoneInventory.Healthstone)
				-- Add shared cooldown timers for Healthstone and Spellstone
				addStoneCooldownTimer(NECROSIS_COOLDOWN.Healthstone, NECROSIS_COOLDOWN.Spellstone, 3)
			end
		-- No stone in inventory, create one
		else
			createStone(2, "NoHealthStoneSpell")
		end
	-- When clicking the Spellstone button
	elseif tooltipType == "Spellstone" then
		if StoneInventory.Spellstone.onHand then
			if isStoneOnCooldown(StoneInventory.Spellstone) then
				sendMessage("Error", "SpellStoneIsOnCooldown")
			else
				SpellStopCasting()
				useStoneFromInventory(StoneInventory.Spellstone)
				-- Add shared cooldown timers for Spellstone and Healthstone
				addStoneCooldownTimer(NECROSIS_COOLDOWN.Spellstone, NECROSIS_COOLDOWN.Healthstone, 2)
			end
		else
			createStone(3, "NoSpellStoneSpell")
		end

	-- When clicking the mount button
	elseif tooltipType == "Mount" then
		-- Or it is the epic mount
		if castSpellByIndex(SpellIndex.SUMMON_DREADSTEED) then
			Necrosis_OnUpdate()
		-- Either it is the normal mount
		elseif castSpellByIndex(SpellIndex.SUMMON_FELSTEED) then
			Necrosis_OnUpdate()
		-- (Or it is nothing at all :) )
		else
			sendMessage("Error", "NoRiding")
		end
	end
end

-- Function that swaps the equipped off-hand item with one from the inventory
function Necrosis_SwitchOffHand(itemType)
	local timerService = getTimerService()
	if itemType == "Spellstone" then
		if StoneInventory.Spellstone.mode == 3 then
			if StoneInventory.Itemswitch.onHand then
				local switchMessage = getMessageNested({ "SwitchMessage" }) or ""
				local containerLink =
					GetContainerItemLink(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
				local inventoryLink = GetInventoryItemLink("player", 17)
				Necrosis_Msg("Equipe " .. (containerLink or "") .. switchMessage .. (inventoryLink or ""), "USER")
				PickupInventoryItem(17)
				PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			end
			return
		else
			PickupContainerItem(StoneInventory.Spellstone.location[1], StoneInventory.Spellstone.location[2])
			PickupInventoryItem(17)
			if timerService and Necrosis_TimerExists(NECROSIS_COOLDOWN.Spellstone) then
				Timers:RemoveTimerByName(NECROSIS_COOLDOWN.Spellstone)
			end
			if timerService then
				Timers:EnsureNamedTimer(NECROSIS_COOLDOWN.Spellstone, 120, TIMER_TYPE.SELF_BUFF, nil, 120, nil)
			end
			return
		end
	end
	if itemType == "OffHand" and UnitClass("player") == NECROSIS_UNIT_WARLOCK then
		if StoneInventory.Itemswitch.location[1] ~= nil and StoneInventory.Itemswitch.location[2] ~= nil then
			PickupContainerItem(StoneInventory.Itemswitch.location[1], StoneInventory.Itemswitch.location[2])
			PickupInventoryItem(17)
		end
	end
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
	if not hasSpell(type) then
		castSpellByIndex(SpellIndex.DEMON_SKIN)
	else
		if (type ~= 44) or (type == 44 and UnitExists("Pet")) then
			castSpellByIndex(type)
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
			local amplifyId = getSpellId(42)
			if (click == "RightButton") and amplifyId then
				local start3, duration3 = GetSpellCooldown(amplifyId, "spell")
				if not (start3 > 0 and duration3 > 0) then
					CastSpell(amplifyId, "spell")
					local spellName = getSpellNameByIndex(SpellIndex.AMPLIFY_CURSE)
					if spellName then
						SpellStopCasting(spellName)
					end
				end
			end
		end
		castSpellByIndex(type)
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
		stoneSpell = Spells:Get(stoneSpellIndex)
	end
	local stoneSpellId = stoneSpell and stoneSpell.ID
	if not stoneSpell or not stoneSpellId then
		local messageKey = "No" .. definition.inventoryKey .. "Spell"
		local message = getMessage("Error", messageKey)
		if message then
			Necrosis_Msg(message, "USER")
		end
	else
		if stoneSpell.Mana and stoneSpell.Mana > UnitMana("player") then
			local message = getMessage("Error", "NoMana")
			if message then
				Necrosis_Msg(message, "USER")
			end
			return
		end
		castSpellByIndex(stoneSpellIndex)
		LastCast.Stone.id = type
		LastCast.Stone.click = click
	end

	MenuState.Stone.alpha = 1
	MenuState.Stone.fadeAt = GetTime() + 3
end

-- Handle casts triggered from the demon menu
function Necrosis_PetCast(type, click)
	if type == 8 and ComponentState.infernal == 0 then
		sendMessage("Error", "InfernalStoneNotPresent")
		return
	elseif type == 30 and ComponentState.demoniac == 0 then
		sendMessage("Error", "DemoniacStoneNotPresent")
		return
	elseif type ~= 15 and type ~= 3 and type ~= 8 and type ~= 30 and SoulshardState.count == 0 then
		sendMessage("Error", "SoulShardNotPresent")
		return
	end
	if type == 3 or type == 4 or type == 5 or type == 6 then
		LastCast.Demon = type
		local dominationId = getSpellId(15)
		if (click == "RightButton") and dominationId then
			local start, duration = GetSpellCooldown(dominationId, "spell")
			if not (start > 0 and duration > 0) then
				CastSpell(dominationId, "spell")
				local spellName = getSpellNameByIndex(SpellIndex.FEL_DOMINATION)
				if spellName then
					SpellStopCasting(spellName)
				end
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
	castSpellByIndex(type)
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
	local timerService = getTimerService()
	if timerService then
		Timers:InsertCustomTimer(timerName, durationSeconds, timerType, targetName, durationSeconds)
	end
end

function NecrosisSpellCast(name)
	if string.find(name, "coa") then
		SpellCastName = getSpellNameByIndex(SpellIndex.CURSE_OF_AGONY)
		SpellTargetName = UnitName("target")
		if not SpellTargetName then
			SpellTargetName = ""
		end
		castSpellByIndex(SpellIndex.CURSE_OF_AGONY)
	end
end
