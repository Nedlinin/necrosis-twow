------------------------------------------------------------------------------------------------------
-- Necrosis Shard Dial
------------------------------------------------------------------------------------------------------

NecrosisShardDial = NecrosisShardDial or {}

local Dial = NecrosisShardDial

local DEFAULT_THEME = "Rose"
local TIMER_THEME = "Blue"

Dial.themes = {
	-- Matches legacy colour selection options (Rose, Blue, Orange, Turquoise, Violet)
	Rose = {
		coreTint = { r = 255, g = 170, b = 200 },
		wedgeMin = { r = 200, g = 80, b = 130 },
		wedgeMax = { r = 255, g = 190, b = 220 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Blue = {
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
}

local function getTheme(name)
	return Dial.themes[name] or Dial.themes[DEFAULT_THEME]
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

local function clampCount(count)
	local numeric = tonumber(count) or 0
	if numeric < 0 then
		numeric = 0
	elseif numeric > 32 then
		numeric = 32
	end
	return numeric
end

local function applyTheme(self, themeName)
	local resolvedTheme = themeName or self.baseThemeName or DEFAULT_THEME
	if not Dial.themes[resolvedTheme] then
		resolvedTheme = DEFAULT_THEME
	end
	local theme = getTheme(resolvedTheme)
	self.activeThemeName = resolvedTheme
	self.activeTheme = theme
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
end

local function getWedgeColour(theme, step)
	local blend = easeOutCubic(step / 15)
	return {
		r = blendChannel(theme.wedgeMin.r, theme.wedgeMax.r, blend),
		g = blendChannel(theme.wedgeMin.g, theme.wedgeMax.g, blend),
		b = blendChannel(theme.wedgeMin.b, theme.wedgeMax.b, blend),
	}
end

local function applyCount(self, count)
	local displayCount = clampCount(count)
	self.displayCount = displayCount
	if not self.enabled then
		return
	end
	local theme = self.activeTheme or getTheme(self.activeThemeName or self.baseThemeName or DEFAULT_THEME)
	local visible = math.min(displayCount, self.wedgeCount)
	local colourOffset = 0
	if displayCount > self.wedgeCount then
		colourOffset = displayCount - self.wedgeCount
	end
	for index = 1, self.wedgeCount do
		local wedge = self.wedges[index]
		if wedge then
			if index <= visible then
				local step = math.mod(index - 1 + colourOffset, self.wedgeCount)
				local colour = getWedgeColour(theme, step)
				wedge:SetVertexColor(normaliseChannel(colour.r), normaliseChannel(colour.g), normaliseChannel(colour.b))
				wedge:Show()
			else
				wedge:Hide()
			end
		end
	end
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
	self.baseThemeName = DEFAULT_THEME
	self.activeThemeName = nil
	self.overrideThemeName = nil
	self.baseCount = 0
	self.overrideCount = 0
	self.overrideHasCount = false
	self.overrideActive = false
	self.displayCount = 0

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
	self.enabled = enabled and true or false
	if not self.coreTex or not self.dividerTex then
		return
	end
	if self.enabled then
		self.coreTex:Show()
		self.dividerTex:Show()
		applyTheme(self, self.overrideThemeName or self.baseThemeName)
		local countToApply = self.baseCount
		if self.overrideActive and self.overrideHasCount then
			countToApply = self.overrideCount
		end
		applyCount(self, countToApply)
	else
		self.coreTex:Hide()
		self.dividerTex:Hide()
		for _, wedge in ipairs(self.wedges) do
			wedge:Hide()
		end
	end
end

function Dial:SetUserTheme(themeName)
	if not self.initialised then
		self:Init()
	end
	local resolved
	if themeName and Dial.themes[themeName] then
		resolved = themeName
	elseif themeName then
		resolved = DEFAULT_THEME
	else
		resolved = self.baseThemeName or DEFAULT_THEME
	end
	if self.baseThemeName ~= resolved then
		self.baseThemeName = resolved
		self.configuredThemeName = nil
	end
	if not self.overrideActive then
		if self.configuredThemeName ~= resolved then
			applyTheme(self, resolved)
			self.configuredThemeName = resolved
		end
		applyCount(self, self.baseCount)
	end
end

function Dial:SetTheme(themeName)
	self:SetUserTheme(themeName)
end

function Dial:SetShardCount(count)
	if not self.initialised then
		self:Init()
	end
	self.baseCount = clampCount(count)
	if not self.overrideActive or not self.overrideHasCount then
		applyCount(self, self.baseCount)
	end
end

function Dial:SetOverride(themeName, count)
	if not self.initialised then
		self:Init()
	end
	self.overrideActive = true
	if themeName ~= nil then
		local resolved = Dial.themes[themeName] and themeName or DEFAULT_THEME
		if self.overrideThemeName ~= resolved then
			self.overrideThemeName = resolved
			self.overrideThemeDirty = true
		end
	end
	if count ~= nil then
		local numeric = clampCount(count)
		if not self.overrideHasCount or self.overrideCount ~= numeric then
			self.overrideHasCount = true
			self.overrideCount = numeric
			self.overrideCountDirty = true
		end
	elseif not self.overrideHasCount then
		self.overrideCount = self.baseCount
	end
	local resolvedTheme = self.overrideThemeName or self.baseThemeName
	if self.overrideThemeDirty or self.activeThemeName ~= resolvedTheme then
		applyTheme(self, resolvedTheme)
		self.overrideThemeDirty = false
	end
	if self.overrideHasCount then
		if self.overrideCountDirty or self.displayCount ~= self.overrideCount then
			applyCount(self, self.overrideCount)
			self.overrideCountDirty = false
		end
	else
		if self.displayCount ~= self.baseCount then
			applyCount(self, self.baseCount)
		end
	end
end

function Dial:SetOverrideTheme(themeName)
	self:SetOverride(themeName, nil)
end

function Dial:SetOverrideCount(count)
	self:SetOverride(nil, count)
end

function Dial:ClearOverride()
	if not self.initialised then
		self:Init()
	end
	if not self.overrideActive and not self.overrideHasCount and not self.overrideThemeName then
		return
	end
	self.overrideActive = false
	self.overrideHasCount = false
	self.overrideThemeName = nil
	self.overrideCount = 0
	self.overrideThemeDirty = false
	self.overrideCountDirty = false
	applyTheme(self, self.baseThemeName)
	applyCount(self, self.baseCount)
end

function Dial:IsOverrideActive()
	return self.overrideActive
end

function Dial:Clear()
	if not self.initialised then
		return
	end
	self.baseCount = 0
	self.overrideActive = false
	self.overrideHasCount = false
	self.overrideThemeName = nil
	self.overrideCount = 0
	if self.enabled then
		applyCount(self, 0)
	end
	for _, wedge in ipairs(self.wedges) do
		if wedge then
			wedge:Hide()
		end
	end
end

function Dial.Ensure()
	if type(Dial.Init) ~= "function" then
		return nil
	end
	if not Dial.initialised then
		Dial:Init()
	end
	if not Dial.initialised then
		return nil
	end
	return Dial
end

function Dial.GetConfiguredTheme()
	local config = NecrosisConfig
	if config and config.Circle and config.Circle ~= 1 then
		return TIMER_THEME
	end
	local theme = config and config.NecrosisColor
	if theme and Dial.themes[theme] then
		return theme
	end
	return DEFAULT_THEME
end

function Dial.SyncConfiguredTheme()
	local dial = Dial.Ensure()
	if not dial then
		return nil
	end
	dial:SetEnabled(true)
	local configuredTheme = Dial.GetConfiguredTheme()
	if dial.configuredThemeName ~= configuredTheme then
		dial:SetUserTheme(configuredTheme)
		dial.configuredThemeName = configuredTheme
	else
		dial.configuredThemeName = configuredTheme
	end
	if not (NecrosisConfig and NecrosisConfig.Circle == 2) and dial:IsOverrideActive() then
		dial:ClearOverride()
	end
	return dial
end
