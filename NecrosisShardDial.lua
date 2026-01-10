------------------------------------------------------------------------------------------------------
-- Necrosis Shard Dial
------------------------------------------------------------------------------------------------------

NecrosisShardDial = NecrosisShardDial or {}

local Dial = NecrosisShardDial

local DEFAULT_THEME = "Rose"
local MAX_SHARD_STEPS = 32
local INACTIVE_COLOR = { r = 25, g = 25, b = 25 }

Dial.themes = {
	Rose = {
		targetColor = { r = 255, g = 20, b = 245 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Blue = {
		targetColor = { r = 64, g = 140, b = 255 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Orange = {
		targetColor = { r = 255, g = 170, b = 64 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Turquoise = {
		targetColor = { r = 64, g = 224, b = 208 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
	Violet = {
		targetColor = { r = 186, g = 85, b = 211 },
		dividerTint = { r = 0, g = 0, b = 0 },
	},
}

local DEFAULT_THEME_DEFINITION = Dial.themes[DEFAULT_THEME]
local DEFAULT_TARGET_COLOR = DEFAULT_THEME_DEFINITION and DEFAULT_THEME_DEFINITION.targetColor
	or { r = 255, g = 255, b = 255 }
local DEFAULT_DIVIDER_TINT = DEFAULT_THEME_DEFINITION and DEFAULT_THEME_DEFINITION.dividerTint
	or { r = 0, g = 0, b = 0 }

local function getTheme(name)
	return Dial.themes[name] or Dial.themes[DEFAULT_THEME]
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
	elseif numeric > MAX_SHARD_STEPS then
		numeric = MAX_SHARD_STEPS
	end
	return numeric
end

local currentThemeSteps = nil
local currentThemeFingerprint = nil

local STANDARD_FONT = _G and _G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

local function normaliseFlags(flags)
	if type(flags) ~= "string" then
		return ""
	end
	return flags
end

local function removeFlag(flags, flag)
	local parsed = {}
	for part in string.gfind(normaliseFlags(flags), "%S+") do
		if part ~= flag then
			table.insert(parsed, part)
		end
	end
	return table.concat(parsed, " ")
end

local function addFlag(flags, flag)
	local base = normaliseFlags(flags)
	if base == "" then
		return flag or ""
	end
	if not flag or flag == "" then
		return base
	end
	for part in string.gfind(base, "%S+") do
		if part == flag then
			return base
		end
	end
	return base .. " " .. flag
end

local function applyCountTextStyle(self, countText, colour)
	if not countText then
		return
	end
	local r, g, b
	if colour then
		r = colour.r or 1
		g = colour.g or 1
		b = colour.b or 1
	else
		r = self.coreCurrentR or self.baseCoreR or 1
		g = self.coreCurrentG or self.baseCoreG or 1
		b = self.coreCurrentB or self.baseCoreB or 1
	end
	local luminance = 0.299 * r + 0.587 * g + 0.114 * b
	local fontPath = self.baseFontPath or STANDARD_FONT
	local fontSize = self.baseFontSize or 12
	if luminance > 0.5 then
		countText:SetTextColor(0, 0, 0)
		countText:SetShadowColor(0, 0, 0, 0)
		countText:SetShadowOffset(0, 0)
		local flags = self.baseFontFlagsNoOutline or removeFlag(self.baseFontFlags, "OUTLINE")
		if flags ~= "" then
			countText:SetFont(fontPath, fontSize, flags)
		else
			countText:SetFont(fontPath, fontSize)
		end
	else
		countText:SetTextColor(1, 1, 1)
		countText:SetShadowColor(0, 0, 0, 0)
		countText:SetShadowOffset(0, 0)
		local flags = self.baseFontFlagsWithOutline or addFlag(self.baseFontFlags, "OUTLINE")
		if flags ~= "" then
			countText:SetFont(fontPath, fontSize, flags)
		else
			countText:SetFont(fontPath, fontSize)
		end
	end
end

local function themeFingerprint(theme)
	if not theme then
		return nil
	end
	local targetColor = theme.targetColor or DEFAULT_TARGET_COLOR
	local divider = theme.dividerTint or DEFAULT_DIVIDER_TINT
	return string.format(
		"%d:%d:%d|%d:%d:%d",
		(targetColor and targetColor.r) or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.r) or 0,
		(targetColor and targetColor.g) or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.g) or 0,
		(targetColor and targetColor.b) or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.b) or 0,
		(divider and divider.r) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.r) or 0,
		(divider and divider.g) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.g) or 0,
		(divider and divider.b) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.b) or 0
	)
end

local function ensureThemeSteps(theme)
	if not theme then
		return nil
	end
	local fingerprint = themeFingerprint(theme)
	if fingerprint == currentThemeFingerprint and currentThemeSteps then
		return currentThemeSteps
	end
	local steps = {}
	local targetColor = theme.targetColor or DEFAULT_TARGET_COLOR or INACTIVE_COLOR
	local targetR = (targetColor and targetColor.r)
		or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.r)
		or INACTIVE_COLOR.r
	local targetG = (targetColor and targetColor.g)
		or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.g)
		or INACTIVE_COLOR.g
	local targetB = (targetColor and targetColor.b)
		or (DEFAULT_TARGET_COLOR and DEFAULT_TARGET_COLOR.b)
		or INACTIVE_COLOR.b
	local effectiveMinR = INACTIVE_COLOR.r + 0.40 * (targetR - INACTIVE_COLOR.r)
	local effectiveMinG = INACTIVE_COLOR.g + 0.40 * (targetG - INACTIVE_COLOR.g)
	local effectiveMinB = INACTIVE_COLOR.b + 0.40 * (targetB - INACTIVE_COLOR.b)
	for index = 0, MAX_SHARD_STEPS - 1 do
		local blend = index / (MAX_SHARD_STEPS - 1)
		local r = normaliseChannel(blendChannel(effectiveMinR, targetR, blend))
		local g = normaliseChannel(blendChannel(effectiveMinG, targetG, blend))
		local b = normaliseChannel(blendChannel(effectiveMinB, targetB, blend))
		steps[index + 1] = { r = r, g = g, b = b }
	end
	currentThemeSteps = steps
	currentThemeFingerprint = fingerprint
	return steps
end

local function applyTheme(self, themeName)
	local resolvedTheme = themeName or self.baseThemeName or DEFAULT_THEME
	if not Dial.themes[resolvedTheme] then
		resolvedTheme = DEFAULT_THEME
	end
	local theme = getTheme(resolvedTheme)
	self.activeThemeName = resolvedTheme
	self.activeTheme = theme
	ensureThemeSteps(theme)
	if resolvedTheme == self.baseThemeName then
		self.baseCoreR = 1
		self.baseCoreG = 1
		self.baseCoreB = 1
	end
	self.coreCurrentR = 1
	self.coreCurrentG = 1
	self.coreCurrentB = 1
	if self.dividerTex then
		local dividerTint = theme.dividerTint or DEFAULT_DIVIDER_TINT
		local dividerR = (dividerTint and dividerTint.r) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.r) or 0
		local dividerG = (dividerTint and dividerTint.g) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.g) or 0
		local dividerB = (dividerTint and dividerTint.b) or (DEFAULT_DIVIDER_TINT and DEFAULT_DIVIDER_TINT.b) or 0
		self.dividerTex:SetVertexColor(
			normaliseChannel(dividerR),
			normaliseChannel(dividerG),
			normaliseChannel(dividerB)
		)
	end
end

local function applyCount(self, count)
	local displayCount = clampCount(count)
	self.displayCount = displayCount
	if not self.enabled then
		return
	end
	local theme = self.activeTheme or getTheme(self.activeThemeName or self.baseThemeName or DEFAULT_THEME)
	local steps = ensureThemeSteps(theme)
	local visible = math.min(displayCount, self.wedgeCount)
	local lastColour = nil
	for index = 1, self.wedgeCount do
		local wedge = self.wedges[index]
		if wedge then
			if index <= visible then
				local stepIndex
				if displayCount <= self.wedgeCount then
					stepIndex = math.ceil((index / visible) * MAX_SHARD_STEPS)
				else
					local offset = displayCount - visible
					local fraction = (offset + index) / displayCount
					stepIndex = math.ceil(fraction * MAX_SHARD_STEPS)
				end
				if stepIndex > MAX_SHARD_STEPS then
					stepIndex = MAX_SHARD_STEPS
				elseif stepIndex < 1 then
					stepIndex = 1
				end
				local colour = steps and steps[stepIndex]
				if colour then
					wedge:SetVertexColor(colour.r, colour.g, colour.b)
					lastColour = colour
				else
					wedge:SetVertexColor(1, 1, 1)
					lastColour = { r = 1, g = 1, b = 1 }
				end
			else
				wedge:SetVertexColor(
					normaliseChannel(INACTIVE_COLOR.r),
					normaliseChannel(INACTIVE_COLOR.g),
					normaliseChannel(INACTIVE_COLOR.b)
				)
			end
			wedge:Show()
		end
	end

	local countText = _G.NecrosisShardCount
	if lastColour and self.coreTex then
		self.coreTex:SetVertexColor(lastColour.r, lastColour.g, lastColour.b)
		self.coreCurrentR = lastColour.r
		self.coreCurrentG = lastColour.g
		self.coreCurrentB = lastColour.b
		applyCountTextStyle(self, countText, lastColour)
	elseif
		self.coreTex
		and (
			self.coreCurrentR ~= self.baseCoreR
			or self.coreCurrentG ~= self.baseCoreG
			or self.coreCurrentB ~= self.baseCoreB
		)
	then
		self.coreTex:SetVertexColor(self.baseCoreR, self.baseCoreG, self.baseCoreB)
		self.coreCurrentR = self.baseCoreR
		self.coreCurrentG = self.baseCoreG
		self.coreCurrentB = self.baseCoreB
		applyCountTextStyle(self, countText, nil)
	elseif countText then
		applyCountTextStyle(self, countText, nil)
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

	local baseTexture = parent:GetNormalTexture()
	if baseTexture then
		baseTexture:SetTexture(nil)
		baseTexture:Hide()
	end
	parent:SetNormalTexture(nil)

	local countText = _G.NecrosisShardCount
	if countText then
		local fontPath, fontSize, fontFlags = countText:GetFont()
		fontPath = fontPath or STANDARD_FONT
		fontSize = fontSize or 12
		local normalisedFlags = normaliseFlags(fontFlags)
		local baseFlagsNoOutline = removeFlag(normalisedFlags, "OUTLINE")
		local baseFlagsWithOutline = addFlag(baseFlagsNoOutline, "OUTLINE")
		self.baseFontPath = fontPath
		self.baseFontSize = fontSize
		self.baseFontFlags = normalisedFlags
		self.baseFontFlagsNoOutline = baseFlagsNoOutline
		self.baseFontFlagsWithOutline = baseFlagsWithOutline
		if baseFlagsNoOutline ~= "" then
			countText:SetFont(fontPath, fontSize, baseFlagsNoOutline)
		else
			countText:SetFont(fontPath, fontSize)
		end
		countText:SetTextColor(1, 1, 1, 1)
		countText:SetShadowColor(0, 0, 0, 0)
		countText:SetShadowOffset(0, 0)
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
	self.baseCoreR = 1
	self.baseCoreG = 1
	self.baseCoreB = 1
	self.coreCurrentR = 1
	self.coreCurrentG = 1
	self.coreCurrentB = 1
	self.baseFontPath = self.baseFontPath or STANDARD_FONT
	self.baseFontSize = self.baseFontSize or 12
	self.baseFontFlags = normaliseFlags(self.baseFontFlags)
	self.baseFontFlagsNoOutline = self.baseFontFlagsNoOutline or removeFlag(self.baseFontFlags, "OUTLINE")
	self.baseFontFlagsWithOutline = self.baseFontFlagsWithOutline or addFlag(self.baseFontFlagsNoOutline, "OUTLINE")

	local texturePath = "Interface\\AddOns\\Necrosis\\UI\\Wedges\\"

	local core = parent:CreateTexture("NecrosisShardDialCore", "ARTWORK")
	core:SetTexture(texturePath .. "ShardCore")
	core:SetPoint("CENTER", parent, "CENTER")
	core:SetWidth(parent:GetWidth() * 0.5)
	core:SetHeight(parent:GetHeight() * 0.5)
	core:Hide()
	core:SetDrawLayer("ARTWORK", 1)
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
	divider:SetDrawLayer("OVERLAY", 0)
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
		ensureThemeSteps(getTheme(resolved))
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
	local themeChanged = false
	if self.overrideThemeDirty or self.activeThemeName ~= resolvedTheme then
		applyTheme(self, resolvedTheme)
		self.overrideThemeDirty = false
		themeChanged = true
	end
	local countToDisplay = self.overrideHasCount and self.overrideCount or self.baseCount
	if themeChanged then
		applyCount(self, countToDisplay)
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
