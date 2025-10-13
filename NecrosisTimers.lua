------------------------------------------------------------------------------------------------------
-- Necrosis Timer Helper API
------------------------------------------------------------------------------------------------------

Necrosis = Necrosis or {}

local table_getn = table.getn

local fallbackTimers = {}
local fallbackSlots = {}
local fallbackGraphical = {
	activeCount = 0,
	names = {},
	expiryTimes = {},
	initialDurations = {},
	displayLines = {},
	slotIds = {},
}

local Timers = {
	_fallbackTimers = fallbackTimers,
	_fallbackSlots = fallbackSlots,
	_fallbackGraphical = fallbackGraphical,
}

local function timersActive()
	return NecrosisSpellTimersEnabled ~= false
end

local function getService()
	local service = NecrosisTimerService
	if type(service) == "table" then
		return service
	end
	return nil
end

local function hasMethod(service, method)
	return service and type(service[method]) == "function"
end

function Timers:GetService()
	return getService()
end

function Timers:HasService()
	return getService() ~= nil
end

function Timers:GetTimers()
	local service = getService()
	if service and service.timers then
		return service.timers
	end
	return fallbackTimers
end

function Timers:GetTimerSlots()
	local service = getService()
	if service and service.timerSlots then
		return service.timerSlots
	end
	return fallbackSlots
end

function Timers:GetTimerTables()
	local service = getService()
	if service then
		return service.timers, service.timerSlots
	end
	return fallbackTimers, fallbackSlots
end

function Timers:GetTimerCount()
	local service = getService()
	if hasMethod(service, "GetTimerCount") then
		return service:GetTimerCount()
	end
	return 0
end

function Timers:GetTimerAt(index)
	if not index then
		return nil
	end
	local service = getService()
	if hasMethod(service, "GetTimerAt") then
		return service:GetTimerAt(index)
	end
	return fallbackTimers[index]
end

function Timers:IterateTimers(callback)
	if type(callback) ~= "function" then
		return
	end
	local service = getService()
	if hasMethod(service, "IterateTimers") then
		return service:IterateTimers(callback)
	end
	for idx = 1, table_getn(fallbackTimers) do
		local timer = fallbackTimers[idx]
		if timer ~= nil then
			local shouldContinue = callback(timer, idx)
			if shouldContinue == false then
				break
			end
		end
	end
end

function Timers:TimerExists(name)
	if not name then
		return false
	end
	local service = getService()
	if hasMethod(service, "TimerExists") then
		return service:TimerExists(name)
	end
	return false
end

function Timers:FindTimerByName(name, target)
	if not name then
		return nil, 0
	end
	local service = getService()
	if hasMethod(service, "FindTimerByName") then
		return service:FindTimerByName(name, target)
	end
	return nil, 0
end

function Timers:EnsureTimer(options)
	if not timersActive() then
		return fallbackTimers, fallbackSlots
	end
	local service = getService()
	if hasMethod(service, "EnsureTimer") then
		return service:EnsureTimer(options)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:EnsureSpellIndexTimer(spellIndex, target, duration, timerType, initial, expiry)
	if not timersActive() then
		return fallbackTimers, fallbackSlots
	end
	local service = getService()
	if hasMethod(service, "EnsureSpellIndexTimer") then
		return service:EnsureSpellIndexTimer(spellIndex, target, duration, timerType, initial, expiry)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:EnsureNamedTimer(name, duration, timerType, target, initial, expiry)
	if not timersActive() then
		return fallbackTimers, fallbackSlots
	end
	local service = getService()
	if hasMethod(service, "EnsureNamedTimer") then
		return service:EnsureNamedTimer(name, duration, timerType, target, initial, expiry)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:InsertCustomTimer(spellName, duration, timerType, targetName, initialDuration, expiryTime)
	if not timersActive() then
		return fallbackTimers, fallbackSlots
	end
	local service = getService()
	if hasMethod(service, "InsertCustomTimer") then
		return service:InsertCustomTimer(spellName, duration, timerType, targetName, initialDuration, expiryTime)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:RemoveTimerByName(name)
	local service = getService()
	if hasMethod(service, "RemoveTimerByName") then
		return service:RemoveTimerByName(name)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:RemoveTimerByIndex(index)
	local service = getService()
	if hasMethod(service, "RemoveTimerByIndex") then
		return service:RemoveTimerByIndex(index)
	end
	return fallbackTimers, fallbackSlots
end

function Timers:RemoveCombatTimers()
	local service = getService()
	if hasMethod(service, "RemoveCombatTimers") then
		return service:RemoveCombatTimers()
	end
	return fallbackTimers, fallbackSlots
end

function Timers:RemoveAllTimers()
	local service = getService()
	if hasMethod(service, "RemoveAllTimers") then
		return service:RemoveAllTimers()
	end
	for index = table_getn(fallbackTimers), 1, -1 do
		table.remove(fallbackTimers, index)
	end
	for index = table_getn(fallbackSlots), 1, -1 do
		fallbackSlots[index] = false
	end
	for key in pairs(fallbackGraphical.names) do
		fallbackGraphical.names[key] = nil
	end
	for key in pairs(fallbackGraphical.expiryTimes) do
		fallbackGraphical.expiryTimes[key] = nil
	end
	for key in pairs(fallbackGraphical.initialDurations) do
		fallbackGraphical.initialDurations[key] = nil
	end
	for key in pairs(fallbackGraphical.displayLines) do
		fallbackGraphical.displayLines[key] = nil
	end
	for key in pairs(fallbackGraphical.slotIds) do
		fallbackGraphical.slotIds[key] = nil
	end
	fallbackGraphical.activeCount = 0
	return fallbackTimers, fallbackSlots
end

function Timers:UpdateTimerEntry(name, target, timeRemaining, expiryTime, timerType, initialDuration)
	if not timersActive() then
		return false
	end
	local service = getService()
	if hasMethod(service, "UpdateTimerEntry") then
		return service:UpdateTimerEntry(name, target, timeRemaining, expiryTime, timerType, initialDuration)
	end
	return false
end

function Timers:UpdateTimer(name, target, mutator)
	if not timersActive() then
		return false, nil, 0
	end
	local service = getService()
	if hasMethod(service, "UpdateTimer") then
		return service:UpdateTimer(name, target, mutator)
	end
	return false, nil, 0
end

function Timers:ResetTimerAssignments()
	local service = getService()
	if hasMethod(service, "ResetTimerAssignments") then
		return service:ResetTimerAssignments()
	end
	return fallbackSlots
end

function Timers:ClearExpiredTimers(currentTime, targetName)
	local service = getService()
	if hasMethod(service, "ClearExpiredTimers") then
		return service:ClearExpiredTimers(currentTime, targetName)
	end
end

function Timers:BuildDisplayData(currentTime, buildText)
	local service = getService()
	if hasMethod(service, "BuildDisplayData") then
		return service:BuildDisplayData(currentTime or 0, buildText)
	end
	return 0
end

function Timers:GetGraphicalData()
	local service = getService()
	if hasMethod(service, "GetGraphicalData") then
		return service:GetGraphicalData()
	end
	return fallbackGraphical
end

function Timers:GetColoredDisplay()
	local service = getService()
	if hasMethod(service, "GetColoredDisplay") then
		return service:GetColoredDisplay()
	end
	return ""
end

function Timers:IsTextDirty()
	local service = getService()
	if hasMethod(service, "IsTextDirty") then
		return service:IsTextDirty()
	end
	return false
end

function Timers:GetLastTextBuildTime()
	local service = getService()
	if hasMethod(service, "GetLastTextBuildTime") then
		return service:GetLastTextBuildTime()
	end
	return 0
end

function Timers:MarkTextDirty()
	local service = getService()
	if hasMethod(service, "MarkTextDirty") then
		return service:MarkTextDirty()
	end
end

Necrosis.Timers = Timers
