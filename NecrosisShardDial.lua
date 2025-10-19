------------------------------------------------------------------------------------------------------
-- Necrosis Shard Dial
------------------------------------------------------------------------------------------------------

NecrosisShardDial = NecrosisShardDial or {}

local Dial = NecrosisShardDial
Dial.themes = {
	-- Matches legacy colour selection options (Rose, Bleu, Orange, Turquoise, Violet, X)
	Rose = {
		coreTint = { r = 255, g = 170, b = 200 },
		wedgeMin = { r = 200, g = 80, b = 130 },
		wedgeMax = { r = 255, g = 190, b = 220 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Bleu = {
		coreTint = { r = 170, g = 210, b = 255 },
		wedgeMin = { r = 70, g = 120, b = 255 },
		wedgeMax = { r = 170, g = 220, b = 255 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Orange = {
		coreTint = { r = 255, g = 170, b = 90 },
		wedgeMin = { r = 255, g = 120, b = 20 },
		wedgeMax = { r = 255, g = 220, b = 120 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Turquoise = {
		coreTint = { r = 140, g = 240, b = 220 },
		wedgeMin = { r = 40, g = 180, b = 160 },
		wedgeMax = { r = 160, g = 255, b = 235 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Violet = {
		coreTint = { r = 210, g = 170, b = 255 },
		wedgeMin = { r = 150, g = 80, b = 255 },
		wedgeMax = { r = 220, g = 190, b = 255 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	X = {
		coreTint = { r = 200, g = 200, b = 200 },
		wedgeMin = { r = 120, g = 120, b = 120 },
		wedgeMax = { r = 220, g = 220, b = 220 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
}

local function getTheme(name)
	return Dial.themes[name] or Dial.themes.Orange
end

local function easeOutCubic(t)
	return 1 - (1 - t) ^ 3
end

local function normaliseChannel(value)
	return (value or 255) / 255
end

local function blendChannel(min, max, blend)
	return min + (max - min) * blend
end

function Dial:Init()
	if self.initialised then
		return
	end

	local parent = NecrosisButton
	if not parent then
		return
	end

	self.wedgeCount = 16
	self.wedges = {}
	self.enabled = false
	self.themeName = nil
	self.lastCount = 0

	local texturePath = "Interface\\AddOns\\Necrosis\\UI\\Wedges\\"

	local core = parent:CreateTexture("NecrosisShardDialCore", "ARTWORK")
	core:SetTexture(texturePath .. "ShardCore")
	core:SetAllPoints(parent)
	core:Hide()
	self.coreTex = core

	for index = 1, self.wedgeCount do
		local tex = parent:CreateTexture("NecrosisShardDialWedge" .. index, "ARTWORK")
		tex:SetTexture(string.format("%sWedgeMask%02d", texturePath, index - 1))
		tex:SetAllPoints(parent)
		tex:Hide()
		self.wedges[index] = tex
	end

	local divider = parent:CreateTexture("NecrosisShardDialDivider", "OVERLAY")
	divider:SetTexture(texturePath .. "DividerOverlay")
	divider:SetAllPoints(parent)
	divider:Hide()
	self.dividerTex = divider

	self.initialised = true
end

function Dial:SetEnabled(enabled)
	if not self.initialised then
		self:Init()
	end
	if self.enabled == enabled then
		return
	end
	self.enabled = enabled
	if not self.coreTex then
		return
	end
	if enabled then
		self.coreTex:Show()
		self.dividerTex:Show()
		self:SetShardCount(self.lastCount or 0)
	else
		self.coreTex:Hide()
		self.dividerTex:Hide()
		for _, wedge in ipairs(self.wedges) do
			wedge:Hide()
		end
	end
end

function Dial:SetTheme(themeName)
	if not self.initialised then
		self:Init()
	end
	local requested = themeName or self.themeName
	if not requested then
		requested = "Orange"
	end

	local theme
	if self.themeName == requested and self.theme then
		theme = self.theme
	else
		self.themeName = requested
		theme = getTheme(self.themeName)
		self.theme = theme
	end

	if self.coreTex then
		self.coreTex:SetVertexColor(
			normaliseChannel(theme.coreTint.r),
			normaliseChannel(theme.coreTint.g),
			normaliseChannel(theme.coreTint.b)
		)
	end

	if self.dividerTex then
		self.dividerTex:SetVertexColor(
			normaliseChannel(theme.dividerTint.r),
			normaliseChannel(theme.dividerTint.g),
			normaliseChannel(theme.dividerTint.b)
		)
	end

	self:SetShardCount(self.lastCount or 0)
end

local function getWedgeColour(theme, step)
	local blend = easeOutCubic(step / 15)
	return {
		r = blendChannel(theme.wedgeMin.r, theme.wedgeMax.r, blend),
		g = blendChannel(theme.wedgeMin.g, theme.wedgeMax.g, blend),
		b = blendChannel(theme.wedgeMin.b, theme.wedgeMax.b, blend),
	}
end

function Dial:SetShardCount(count)
	if not self.enabled or not self.initialised then
		return
	end

	self.lastCount = count
	local theme = self.theme or getTheme(self.themeName)
	local active = count
	if active > 32 then
		active = 32
	end
	local displayCount = math.min(active, self.wedgeCount)
	local colourOffset = 0
	if active > self.wedgeCount then
		colourOffset = active - self.wedgeCount
	end

	for index = 1, self.wedgeCount do
		local wedge = self.wedges[index]
		if index <= displayCount and wedge then
			local step = math.mod(index - 1 + colourOffset, self.wedgeCount)
			local colour = getWedgeColour(theme, step)
			wedge:SetVertexColor(normaliseChannel(colour.r), normaliseChannel(colour.g), normaliseChannel(colour.b))
			wedge:Show()
		elseif wedge then
			wedge:Hide()
		end
	end
end

function Dial:Clear()
	self.lastCount = 0
	if not self.wedges then
		return
	end
	for _, wedge in ipairs(self.wedges) do
		wedge:Hide()
	end
end
