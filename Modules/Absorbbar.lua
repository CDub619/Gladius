local Gladius = _G.Gladius
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Health Bar"))
end
local L = Gladius.L
local LSM

-- Global Functions
local pairs = pairs
local select = select
local strfind = string.find

local CreateFrame = CreateFrame
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax


local AbsorbBar = Gladius:NewModule("AbsorbBar", true, true, {
	absorbBarAttachTo = "HealthBar",
	absorbBarColor = {r = 0, g = 0, b = 0, a = 1},
	absorbBarTexture = "Minimalist",
	absorbBarOffsetX = 0,
	absorbBarOffsetY = 0,
	absorbBarAnchor = "LEFT",
	absorbBarRelativePoint = "LEFT",
	absorbBarBlizTexture  = true,
})

function AbsorbBar:OnEnable()
	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
	LSM = Gladius.LSM
	-- set frame type
	if not self.frame then
		self.frame = { }
	end
end

function AbsorbBar:OnDisable()
	self:UnregisterAllEvents()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
		self.frame[unit].overlay:SetAlpha(0)
		self.frame[unit].overAbsorbGlow:SetAlpha(0)
	end
end

function AbsorbBar:GetAttachTo()
	return Gladius.db.absorbBarAttachTo
end

function AbsorbBar:GetFrame(unit)
	return self.frame[unit]
end

function AbsorbBar:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if not unit then
		return
	end
	if not Gladius:IsValidUnit(unit) or not UnitExists(unit) then
		return
	end
	local health, maxHealth, totalAbsorbs = UnitHealth(unit), UnitHealthMax(unit), UnitGetTotalAbsorbs(unit)
	self:UpdateAbsorb(unit, health, maxHealth, totalAbsorbs)
end

function AbsorbBar:UNIT_HEALTH(event, unit)
	if not unit then
		return
	end
	if not Gladius:IsValidUnit(unit) or not UnitExists(unit) then
		return
	end
	local health, maxHealth, totalAbsorbs = UnitHealth(unit), UnitHealthMax(unit), UnitGetTotalAbsorbs(unit)
	self:UpdateAbsorb(unit, health, maxHealth, totalAbsorbs)
end

function AbsorbBar:UpdateAbsorb(unit, health, maxHealth, totalAbsorbs)
	if not self.frame[unit] then
		if not Gladius.buttons[unit] then
			Gladius:UpdateUnit(unit)
		else
			self:Update(unit)
		end
	end

	if not Gladius.test and (not Gladius:IsValidUnit(unit) or not UnitExists(unit)) then
		self.frame[unit]:SetAlpha(0)
		self.frame[unit].overlay:SetAlpha(0)
		self.frame[unit].overAbsorbGlow:SetAlpha(0)
		return
	end

	-- update min max values
	if self.frame[unit] == nil then
		return
	end

	if totalAbsorbs then

		local parent = Gladius:GetParent(unit, Gladius.db.absorbBarAttachTo)
		local width = Gladius.db.healthBarAdjustWidth and Gladius.db.barWidth or Gladius.db.healthBarWidth
		-- add width of the widget if attached to an widget
		if Gladius.db.healthBarAttachTo ~= "Frame" and not strfind(Gladius.db.healthBarRelativePoint,"BOTTOM") and Gladius.db.healthBarAdjustWidth then
			if not Gladius:GetModule(Gladius.db.healthBarAttachTo).frame[unit] then
				Gladius:GetModule(Gladius.db.healthBarAttachTo):Update(unit)
			end
			width = width + Gladius:GetModule(Gladius.db.healthBarAttachTo).frame[unit]:GetWidth()
		end

		local barOffsetX = width * health/maxHealth
		local healthgone = ((maxHealth - health)/maxHealth) * width
		local absorb = (totalAbsorbs/maxHealth) * width
		--print(unit.." "..barOffsetX)
		--print(unit.." "..healthgone)
		--print(unit.." "..absorb)
		local overAbsorb
		if absorb >= healthgone then
			if ( totalAbsorbs > 0 ) then
				overAbsorb = true;
				if healthgone < 1 then
					healthgone = 1
				end
			end
		end

		self.frame[unit]:ClearAllPoints()
		self.frame[unit]:SetHeight(Gladius.db.healthBarHeight)
		self.frame[unit]:SetWidth(healthgone)
		self.frame[unit]:SetPoint(Gladius.db.absorbBarAnchor, parent, Gladius.db.absorbBarRelativePoint, barOffsetX, 0)
		self.frame[unit]:SetFrameStrata("MEDIUM")
		self.frame[unit]:SetFrameLevel(parent:GetFrameLevel() + 2)
		self.frame[unit].tileSize = 20;
		self.frame[unit].overlay:ClearAllPoints()
		self.frame[unit].overlay:SetHeight(Gladius.db.healthBarHeight)
		self.frame[unit].overlay:SetWidth(healthgone)
		self.frame[unit].overlay:SetPoint(Gladius.db.absorbBarAnchor, self.frame[unit], Gladius.db.absorbBarRelativePoint, barOffsetX, 0)
		self.frame[unit].overlay:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Overlay", true, true);	--Tile both vertically and horizontally
		self.frame[unit].overlay:SetAllPoints(self.frame[unit]);
		self.frame[unit].overlay.tileSize = 20;
		self.frame[unit].overlay:SetFrameStrata("MEDIUM")
		self.frame[unit].overlay:SetFrameLevel(parent:GetFrameLevel() + 3)
		self.frame[unit].overAbsorbGlow:ClearAllPoints()
		self.frame[unit].overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield");
		self.frame[unit].overAbsorbGlow:SetBlendMode("ADD");
		self.frame[unit].overAbsorbGlow:SetPoint("BOTTOMLEFT", self.frame[unit].overlay, "BOTTOMRIGHT", -6, 0);
		self.frame[unit].overAbsorbGlow:SetPoint("TOPLEFT", self.frame[unit].overlay, "TOPRIGHT", -6, 0);
		self.frame[unit].overAbsorbGlow:SetWidth(11);
		self.frame[unit].overAbsorbGlow:SetHeight(Gladius.db.healthBarHeight)

		if overAbsorb then
			self.frame[unit].overAbsorbGlow:Show();
		else
			self.frame[unit].overAbsorbGlow:Hide();
		end

		if Gladius.db.absorbBarBlizTexture then
			self.frame[unit]:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill")
			self.frame[unit].overlay:SetAlpha(1)
			self.frame[unit].overAbsorbGlow:SetAlpha(1)
		else
			self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.absorbBarTexture))
			-- disable tileing
			self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
			self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
			self.frame[unit].overlay:SetAlpha(0)
			self.frame[unit].overAbsorbGlow:SetAlpha(0)
		end

		self.frame[unit]:SetMinMaxValues(0, healthgone)
		self.frame[unit].overlay:SetMinMaxValues(0, healthgone)
		self.frame[unit]:SetValue(absorb)
		self.frame[unit].overlay:SetValue(absorb)

	else
		self.frame[unit]:SetAlpha(0)
		self.frame[unit].overlay:SetAlpha(0)
		self.frame[unit].overAbsorbGlow:SetAlpha(0)
	end
end


function AbsorbBar:UpdateColors(unit)
	local testing = Gladius.test
		local color = Gladius.db.absorbBarColor
		if Gladius.db.absorbBarBlizTexture then
			self.frame[unit]:SetStatusBarColor(1, 1, 1, 1)
		else
			self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
		end
end

function AbsorbBar:CreateBar(unit)
	local button = Gladius.buttons[unit]
	if not button then
		return
	end
	-- create bar + text
	self.frame[unit] = CreateFrame("STATUSBAR", "Gladius"..self.name..unit, button)
	self.frame[unit].overlay= CreateFrame("STATUSBAR", "Gladius"..self.name..unit.."Overlay", button)
	self.frame[unit].overAbsorbGlow = self.frame[unit].overlay:CreateTexture("Gladius"..self.name.."overAbsorbGlow"..unit, "OVERLAY")
end

function AbsorbBar:Update(unit)
	-- check parent module
	if not Gladius:GetModule(Gladius.db.castBarAttachTo) then
		if self.frame[unit] then
			self.frame[unit]:Hide()
		end
		return
	end
	-- create power bar
	if not self.frame[unit] then
		self:CreateBar(unit)
	end
end

function AbsorbBar:Show(unit)
	-- show frame
	self.frame[unit]:SetAlpha(1)

	local color = Gladius.db.absorbBarColor

	if Gladius.db.absorbBarBlizTexture then
		self.frame[unit]:SetStatusBarColor(1, 1, 1, 1)
	else
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
	end
	-- call event
	if not Gladius.test then
		self:UNIT_ABSORB_AMOUNT_CHANGED("UNIT_ABSORB_AMOUNT_CHANGED", unit)
	end
end

function AbsorbBar:Reset(unit)
	if not self.frame[unit] then
		return
	end
	-- reset bar
	self.frame[unit]:SetMinMaxValues(0, 1)
	self.frame[unit]:SetValue(1)
	-- hide
	self.frame[unit]:SetAlpha(0)
end

function AbsorbBar:Test(unit)
	-- set test values
	local maxHealth = Gladius.testing[unit].maxHealth
	local health = Gladius.testing[unit].health
	local totalAbsorbs = Gladius.testing[unit].totalAbsorbs
	self:UpdateAbsorb(unit, health, maxHealth, totalAbsorbs)
end

function AbsorbBar:GetOptions()
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				bar = {
					type = "group",
					name = L["Bar"],
					desc = L["Bar settings"],
					inline = true,
					order = 1,
					args = {
						sep = {
							type = "description",
							name = "",
							width = "full",
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 7,
						},
						absorbBarBlizTexture = {
							type = "toggle",
							name = "Blizzard Texture",
							desc = "Blizzard absorb default texture",
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 6,
						},
						absorbBarColor = {
							type = "color",
							name = L["Health bar color"],
							desc = L["Color of the health bar"],
							hasAlpha = true,
							get = function(info)
								return Gladius:GetColorOption(info)
							end,
							set = function(info, r, g, b, a)
								return Gladius:SetColorOption(info, r, g, b, a)
							end,
							disabled = function()
								return Gladius.dbi.profile.absorbBarBlizTexture or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 7,
						},
						absorbBarTexture = {
							type = "select",
							name = L["Health bar texture"],
							desc = L["Texture of the health bar"],
							dialogControl = "LSM30_Statusbar",
							values = AceGUIWidgetLSMlists.statusbar,
							disabled = function()
								return Gladius.dbi.profile.absorbBarBlizTexture or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 20,
						},
					},
				},
			},
		},
	}
end
