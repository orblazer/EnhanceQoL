-- luacheck: globals EnhanceQoL
local addonName, addon = ...
local floor = math.floor
local GetMoney = GetMoney

local COPPER_PER_GOLD = 10000

local function formatGoldString(copper)
	local g = floor(copper / COPPER_PER_GOLD)
	local s = floor((copper % COPPER_PER_GOLD) / 100)
	local c = copper % 100
	local gText = (BreakUpLargeNumbers and BreakUpLargeNumbers(g)) or tostring(g)
	return gText, s, c
end

local function checkMoney(stream)
	local money = GetMoney() or 0
	local gText, s, c = formatGoldString(money)
	stream.snapshot.text = ("|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t %s"):format(gText)
	-- stream.snapshot.tooltip = ("Gold: %s  Silver: %d  Copper: %d"):format(gText, s, c)
end

local provider = {
	id = "gold",
	version = 1,
	title = WORLD_QUEST_REWARD_FILTERS_GOLD,
	update = checkMoney,
	events = {
		PLAYER_MONEY = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_LOGIN = function(stream) addon.DataHub:RequestUpdate(stream) end,
	},
	-- OnClick = function(...) end,
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
