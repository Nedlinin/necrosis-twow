------------------------------------------------------------------------------------------------------
-- Necrosis Runtime State
------------------------------------------------------------------------------------------------------

Necrosis = Necrosis or {}
Necrosis.runtime = Necrosis.runtime or {}

local runtime = Necrosis.runtime

local function hydrateTable(target, defaults)
	if type(target) ~= "table" then
		target = {}
	end
	for key, defaultValue in pairs(defaults) do
		if type(defaultValue) == "table" then
			target[key] = hydrateTable(target[key], defaultValue)
		elseif target[key] == nil then
			target[key] = defaultValue
		end
	end
	return target
end

local stateDefaults = {
	soulshards = {
		count = 0,
		container = 4,
		slots = {},
		nextSlotIndex = 1,
		pendingMoves = 0,
		tidyAccumulator = 0,
		pendingSortCheck = false,
	},
	mount = { available = false, active = false, notify = true },
	combat = { inCombat = false },
	shadowTrance = { active = false, buffId = -1, remaining = nil },
	antiFear = { inUse = false, blink1 = 0, blink2 = 0, currentTargetImmune = false },
	trade = { requested = false, active = false, countdown = 0 },
	components = { infernal = 0, demoniac = 0 },
	bags = { scanQueued = true, nextScanTime = 0, processing = false },
	messages = { pet = 0, steed = 0, rez = 0, tp = 0 },
	demon = {
		type = nil, -- Previously: DemonType global
		enslaved = false, -- Previously: DemonEnslaved global
	},
	buffs = {
		amplifyUp = false, -- Previously: AmplifyUp global
		dominationUp = false, -- Previously: DominationUp global
		lastRefreshed = nil, -- Previously: LastRefreshedBuffName global
	},
	soulstone = {
		target = nil, -- Previously: SoulstoneTarget global
		pendingAdvice = false, -- Previously: SoulstoneAdvice global
	},
	initialization = {
		loaded = false, -- Previously: Loaded local in Necrosis.lua
		inWorld = false, -- Previously: Necrosis_In global
		reloadFlag = true, -- Previously: NecrosisRL global
	},
}

local menuDefaults = {
	Pet = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Buff = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Curse = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
	Stone = { open = false, fading = false, alpha = 1, fadeAt = 0, sticky = false, frames = {} },
}

local inventoryDefaults = {
	stones = {
		Soulstone = { onHand = false, location = { nil, nil }, mode = 1 },
		Healthstone = { onHand = false, location = { nil, nil }, mode = 1 },
		Firestone = { onHand = false, location = { nil, nil } },
		Spellstone = { onHand = false, location = { nil, nil }, mode = 1 },
		Felstone = { onHand = false, location = { nil, nil } },
		Wrathstone = { onHand = false, location = { nil, nil } },
		Voidstone = { onHand = false, location = { nil, nil } },
		Hearthstone = { onHand = false, location = { nil, nil } },
		Itemswitch = { onHand = false, location = { nil, nil } },
	},
	bagIsSoulPouch = { nil, nil, nil, nil, nil },
}

runtime.state = hydrateTable(runtime.state, stateDefaults)
runtime.inventory = hydrateTable(runtime.inventory, inventoryDefaults)
runtime.menus = hydrateTable(runtime.menus, menuDefaults)

runtime.lastCast = hydrateTable(runtime.lastCast, {
	Demon = 0,
	Buff = 0,
	Curse = { id = 0, click = "LeftButton" },
	Stone = { id = 0, click = "LeftButton" },
})

local state = runtime.state
local inventory = runtime.inventory
local menus = runtime.menus

------------------------------------------------------------------------------------------------------
-- Accessors
------------------------------------------------------------------------------------------------------

function Necrosis.GetRuntime()
	return runtime
end

function Necrosis.GetStateSlice(key)
	return state[key]
end

function Necrosis.GetInventorySlice(key)
	return inventory[key]
end

function Necrosis.GetLastCast()
	return runtime.lastCast
end

function Necrosis.GetMenuState()
	return menus
end

function Necrosis_GetStateSlice(key)
	return Necrosis.GetStateSlice(key)
end

function Necrosis_GetLastCast()
	return Necrosis.GetLastCast()
end

MenuState = menus

function Necrosis_GetMenuState()
	return Necrosis.GetMenuState()
end
