-- luacheck: globals EnhanceQoL
local floor = math.floor
local GetMoney = GetMoney

local COPPER_PER_GOLD = 10000

local provider = {
	id = "gold",
	version = 1,
	title = "Gold",
	columns = {
		{ key = "gold", title = "Gold" },
	},
	events = {
		PLAYER_MONEY = function(stream)
			local row = EnhanceQoL.DataHub:AcquireRow(stream)
			row.gold = floor(GetMoney() / COPPER_PER_GOLD)
			EnhanceQoL.DataHub.Publish(stream, { row })
		end,
	},
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
