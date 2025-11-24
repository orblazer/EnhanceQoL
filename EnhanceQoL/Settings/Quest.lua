local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cQuest = addon.functions.SettingsCreateCategory(nil, L["Quest"], nil, "Quest")
addon.SettingsLayout.questCategory = cQuest

local data = {
	{
		var = "autoChooseQuest",
		text = L["autoChooseQuest"],
		desc = L["interruptWithShift"],
		func = function(key) addon.db["autoChooseQuest"] = key end,
		default = false,
		children = {

			{
				var = "ignoreDailyQuests",
				text = L["ignoreDailyQuests"]:format(QUESTS_LABEL),
				func = function(key) addon.db["ignoreDailyQuests"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreWarbandCompleted",
				text = L["ignoreWarbandCompleted"]:format(ACCOUNT_COMPLETED_QUEST_LABEL, QUESTS_LABEL),
				func = function(key) addon.db["ignoreWarbandCompleted"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				var = "ignoreTrivialQuests",
				text = L["ignoreTrivialQuests"]:format(QUESTS_LABEL),
				func = function(key) addon.db["ignoreTrivialQuests"] = key end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
			},
			{
				text = "|cff99e599" .. L["ignoreNPCTipp"] .. "|r",
				sType = "hint",
			},
			{
				listFunc = function()
					local tList = { [""] = "" }
					for id, name in pairs(addon.db["ignoredQuestNPC"] or {}) do
						tList[id] = name
					end
					return tList
				end,
				text = REMOVE,
				get = function() return "" end,
				set = function(key)
					-- TODO - Add static popup with remove dialog
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoChooseQuest"]
						and addon.SettingsLayout.elements["autoChooseQuest"].setting
						and addon.SettingsLayout.elements["autoChooseQuest"].setting:GetValue() == true
				end,
				parent = true,
				default = "",
				var = "ignoredQuestNPC",
				type = Settings.VarType.String,
				sType = "dropdown",
			},
		},
	},
	{
		var = "questWowheadLink",
		text = L["questWowheadLink"],
		func = function(key) addon.db["questWowheadLink"] = key end,
		default = false,
	},
	{
		var = "autoCancelCinematic",
		text = L["autoCancelCinematic"],
		desc = L["autoCancelCinematicDesc"],
		func = function(key) addon.db["autoCancelCinematic"] = key end,
		default = false,
	},
	{
		var = "questTrackerShowQuestCount",
		text = L["questTrackerShowQuestCount"],
		desc = L["questTrackerShowQuestCount_desc"],
		func = function(key)
			addon.db["questTrackerShowQuestCount"] = key
			addon.functions.UpdateQuestTrackerQuestCount()
		end,
		default = false,
		children = {
			{
				var = "questTrackerQuestCountOffsetX",
				text = L["questTrackerQuestCountOffsetX"],
				parentCheck = function()
					return addon.SettingsLayout.elements["questTrackerShowQuestCount"]
						and addon.SettingsLayout.elements["questTrackerShowQuestCount"].setting
						and addon.SettingsLayout.elements["questTrackerShowQuestCount"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.questTrackerQuestCountOffsetX or 0 end,
				set = function(value)
					addon.db["questTrackerQuestCountOffsetX"] = value
					addon.functions.UpdateQuestTrackerQuestCountPosition()
				end,
				min = -200,
				max = 200,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
			},
			{
				var = "questTrackerQuestCountOffsetY",
				text = L["questTrackerQuestCountOffsetY"],
				parentCheck = function()
					return addon.SettingsLayout.elements["questTrackerShowQuestCount"]
						and addon.SettingsLayout.elements["questTrackerShowQuestCount"].setting
						and addon.SettingsLayout.elements["questTrackerShowQuestCount"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.questTrackerQuestCountOffsetY or 0 end,
				set = function(value)
					addon.db["questTrackerQuestCountOffsetY"] = value
					addon.functions.UpdateQuestTrackerQuestCountPosition()
				end,
				min = -200,
				max = 200,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cQuest, data)

----- REGION END

function addon.functions.initQuest()
	if Menu and Menu.ModifyMenu then
		local function GetNPCIDFromGUID(guid)
			if guid then
				local type, _, _, _, _, npcID = strsplit("-", guid)
				if type == "Creature" or type == "Vehicle" then return tonumber(npcID) end
			end
			return nil
		end

		local function AddIgnoreAutoQuest(owner, root, ctx)
			if not addon.db["autoChooseQuest"] then return end

			if not UnitExists("target") or UnitPlayerControlled("target") then return end
			local npcID = GetNPCIDFromGUID(UnitGUID("target"))
			if not npcID then return end
			local name = UnitName("target")
			if not name then return end

			root:CreateDivider()
			root:CreateTitle(addonName)
			if addon.db["ignoredQuestNPC"][npcID] then
				root:CreateButton(L["SettingsQuestHeaderIgnoredNPCRemove"], function(id) addon.db["ignoredQuestNPC"][npcID] = nil end, npcID)
			else
				root:CreateButton(L["SettingsQuestHeaderIgnoredNPCAdd"], function(id) addon.db["ignoredQuestNPC"][npcID] = name end, npcID)
			end
		end

		Menu.ModifyMenu("MENU_UNIT_TARGET", AddIgnoreAutoQuest)
	end
end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
