local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cGameplay = addon.SettingsLayout.rootGAMEPLAY
if not cGameplay then return end

local expandable = addon.functions.SettingsCreateExpandableSection(cGameplay, {
	name = L["Convenience"],
	expanded = false,
	colorizeTitle = false,
})

local classTag = (addon.variables and addon.variables.unitClass) or select(2, UnitClass("player"))
if classTag == "DRUID" then
	addon.functions.SettingsCreateHeadline(cGameplay, select(1, UnitClass("player")), { parentSection = expandable })

	local data = {
		{
			var = "autoCancelDruidFlightForm",
			text = L["autoCancelDruidFlightForm"],
			desc = L["autoCancelDruidFlightFormDesc"],
			func = function(value)
				addon.db["autoCancelDruidFlightForm"] = value and true or false
				if addon.functions.updateDruidFlightFormWatcher then addon.functions.updateDruidFlightFormWatcher() end
			end,
			parentSection = expandable,
		},
	}

	addon.functions.SettingsCreateCheckboxes(cGameplay, data)
end
