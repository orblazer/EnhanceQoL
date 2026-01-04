-- luacheck: globals EnhanceQoL MASTER_VOLUME OPTION_TOOLTIP_MASTER_VOLUME
local addonName, addon = ...
local L = addon.L

local AceGUI = addon.AceGUI
local db
local stream
local sliderFrame
local slider

local floor = math.floor
local format = string.format

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.volume = addon.db.datapanel.volume or {}
	db = addon.db.datapanel.volume
	db.fontSize = db.fontSize or 14
	db.step = db.step or 0.05
end

local function RestorePosition(frame)
	if db.point and db.x and db.y then
		frame:ClearAllPoints()
		frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
	end
end

local aceWindow
local function createAceWindow()
	if aceWindow then
		aceWindow:Show()
		return
	end
	ensureDB()
	local frame = AceGUI:Create("Window")
	aceWindow = frame.frame
	frame:SetTitle(GAMEMENU_OPTIONS)
	frame:SetWidth(300)
	frame:SetHeight(200)
	frame:SetLayout("List")

	frame.frame:SetScript("OnShow", function(self) RestorePosition(self) end)
	frame.frame:SetScript("OnHide", function(self)
		local point, _, _, xOfs, yOfs = self:GetPoint()
		db.point = point
		db.x = xOfs
		db.y = yOfs
	end)

	local fontSize = AceGUI:Create("Slider")
	fontSize:SetLabel(FONT_SIZE)
	fontSize:SetSliderValues(8, 32, 1)
	fontSize:SetValue(db.fontSize)
	fontSize:SetCallback("OnValueChanged", function(_, _, val)
		db.fontSize = val
		addon.DataHub:RequestUpdate(stream)
	end)
	frame:AddChild(fontSize)

	frame.frame:Show()
end

local function clampVolume(value)
	value = tonumber(value) or 0
	if value < 0 then return 0 end
	if value > 1 then return 1 end
	return value
end

local function getVolume() return clampVolume(GetCVar and GetCVar("Sound_MasterVolume")) end

local function setVolume(value) SetCVar("Sound_MasterVolume", clampVolume(value)) end

local function formatPercent(value) return format("%d%%", floor(value * 100 + 0.5)) end

local function updateSliderText(value)
	if not slider or not slider.Text then return end
	slider.Text:SetText(formatPercent(value))
end

local function updateSliderValue(value)
	if not slider then return end
	slider._ignore = true
	slider:SetValue(value)
	slider._ignore = nil
	updateSliderText(value)
end

local function ensureSliderFrame()
	if sliderFrame then return sliderFrame end
	ensureDB()
	sliderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	sliderFrame:SetSize(200, 44)
	sliderFrame:SetFrameStrata("TOOLTIP")
	sliderFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	sliderFrame:SetBackdropColor(0, 0, 0, 0.85)
	sliderFrame:EnableMouse(true)
	sliderFrame:Hide()
	sliderFrame:SetScript("OnHide", function(self) self.owner = nil end)

	slider = CreateFrame("Slider", nil, sliderFrame, "OptionsSliderTemplate")
	slider:SetWidth(160)
	slider:SetPoint("CENTER", sliderFrame, "CENTER", 0, 0)
	slider:SetMinMaxValues(0, 1)
	slider:SetValueStep(db.step or 0.05)
	slider:SetObeyStepOnDrag(true)
	if slider.Low then slider.Low:SetText("0%") end
	if slider.High then slider.High:SetText("100%") end

	slider:SetScript("OnValueChanged", function(self, value)
		if self._ignore then return end
		setVolume(value)
		updateSliderText(value)
		if stream then addon.DataHub:RequestUpdate(stream) end
	end)

	return sliderFrame
end

local function toggleSlider(anchor)
	if not anchor then return end
	local frame = ensureSliderFrame()
	if frame:IsShown() and frame.owner == anchor then
		frame:Hide()
		return
	end
	frame.owner = anchor
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
	if not anchor._volumeSliderHideHooked then
		anchor._volumeSliderHideHooked = true
		anchor:HookScript("OnHide", function()
			if sliderFrame and sliderFrame.owner == anchor then sliderFrame:Hide() end
		end)
	end
	frame:Show()
	updateSliderValue(getVolume())
end

local function updateVolume(streamObj)
	ensureDB()
	local volume = getVolume()
	local size = db.fontSize or 14
	streamObj.snapshot.fontSize = size
	streamObj.snapshot.text = ("|TInterface\\Common\\VoiceChat-Speaker:%d:%d:0:0|t %s"):format(size, size, formatPercent(volume))
	local tip = OPTION_TOOLTIP_MASTER_VOLUME or MASTER_VOLUME
	local hint = getOptionsHint()
	if hint and tip then
		streamObj.snapshot.tooltip = tip .. "\n" .. hint
	elseif tip then
		streamObj.snapshot.tooltip = tip
	else
		streamObj.snapshot.tooltip = hint
	end
	if sliderFrame and sliderFrame:IsShown() then updateSliderValue(volume) end
end

local provider = {
	id = "volume",
	version = 1,
	title = MASTER_VOLUME or "Master Volume",
	update = updateVolume,
	events = {
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
		CVAR_UPDATE = function(s, _, name)
			if name == "Sound_MasterVolume" then addon.DataHub:RequestUpdate(s) end
		end,
	},
	OnClick = function(btn, mouseButton)
		if mouseButton == "LeftButton" then
			toggleSlider(btn)
		elseif mouseButton == "RightButton" then
			createAceWindow()
		end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
