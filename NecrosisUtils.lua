------------------------------------------------------------------------------------------------------
-- Necrosis Utility Helpers
------------------------------------------------------------------------------------------------------

NecrosisUtils = NecrosisUtils or {}

function NecrosisUtils.WipeArray(t)
	if type(t) ~= "table" then
		return
	end
	for index = table.getn(t), 1, -1 do
		t[index] = nil
	end
end

function NecrosisUtils.WipeTable(t)
	if type(t) ~= "table" then
		return
	end
	for key in pairs(t) do
		t[key] = nil
	end
end
