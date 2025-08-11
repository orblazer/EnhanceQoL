-- luacheck: globals EnhanceQoL
local addonName, addon = ...

local AceGUI = addon.AceGUI
local db
local function RestorePosition(frame)
	if db.point and db.x and addon.db.y then
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
	if not db then
		addon.db.datapanel = addon.db.datapanel or {}
		addon.db.datapanel.talent = addon.db.datapanel.talent or {}
		db = addon.db.datapanel.talent
	end
	local frame = AceGUI:Create("Frame")
	aceWindow = frame.frame
	frame:SetTitle(GAMEMENU_OPTIONS)
	frame:SetWidth(300)
	frame:SetHeight(400)
	frame:SetLayout("Fill")

	frame.frame:SetScript("OnShow", function(self) RestorePosition(self) end)
	frame.frame:SetScript("OnHide", function(self)
		local point, _, _, xOfs, yOfs = self:GetPoint()
		db.point = point
		db.x = xOfs
		db.y = yOfs
	end)
	frame.frame:Show()
end

local function GetConfigName(configID)
	if configID then
		if type(configID) == "number" then
			local info = C_Traits.GetConfigInfo(configID)
			if info then return info.name end
		end
	end
	return "Unknown"
end

local function GetCurrentTalents(stream)
	local specId = PlayerUtil.GetCurrentSpecID()
	if specId then stream.snapshot.text = GetConfigName(C_ClassTalents.GetLastSelectedSavedConfigID(specId)) end
end

local provider = {
	id = "talent",
	version = 1,
	title = TALENTS,
	update = GetCurrentTalents,
	events = {
		PLAYER_LOGIN = function(stream)
			C_Timer.After(1, function() addon.DataHub:RequestUpdate(stream) end)
		end,
		TRAIT_CONFIG_CREATED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		TRAIT_CONFIG_DELETED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		TRAIT_CONFIG_UPDATED = function(stream)
			C_Timer.After(0.02, function() addon.DataHub:RequestUpdate(stream) end)
		end,
		ZONE_CHANGED_NEW_AREA = function(stream) addon.DataHub:RequestUpdate(stream) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then createAceWindow() end
	end,
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
