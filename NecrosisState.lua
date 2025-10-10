------------------------------------------------------------------------------------------------------
-- Necrosis State Definitions
------------------------------------------------------------------------------------------------------

NecrosisState = NecrosisState
	or {
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
		bags = { pending = true, nextScanTime = 0 },
		messages = { pet = 0, steed = 0, rez = 0, tp = 0 },
	}

NecrosisState.inventory = NecrosisState.inventory
	or {
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

SoulshardState = NecrosisState.soulshards

MountState = NecrosisState.mount
CombatState = NecrosisState.combat
ShadowState = NecrosisState.shadowTrance
AntiFearState = NecrosisState.antiFear
TradeState = NecrosisState.trade
ComponentState = NecrosisState.components
MessageState = NecrosisState.messages
InventoryState = NecrosisState.inventory
StoneInventory = InventoryState.stones
BagIsSoulPouch = InventoryState.bagIsSoulPouch
BagScanState = InventoryState.bags
