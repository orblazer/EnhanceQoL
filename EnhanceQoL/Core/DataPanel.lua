local addonName, addon = ...
addon.DataPanel = addon.DataPanel or {}
local DataPanel = addon.DataPanel
local DataHub = addon.DataHub

local panels = {}

local function ensureSettings(id)
	addon.db = addon.db or {}
	addon.db.dataPanels = addon.db.dataPanels or {}
	local info = addon.db.dataPanels[id]
	if not info then
		info = { point = "CENTER", x = 0, y = 0, width = 200, height = 20 }
		addon.db.dataPanels[id] = info
	end
	return info
end

local function savePosition(frame, id)
	local info = ensureSettings(id)
	info.point, _, _, info.x, info.y = frame:GetPoint()
	info.width = frame:GetWidth()
	info.height = frame:GetHeight()
end

function DataPanel.Create(id)
	if panels[id] then return panels[id] end
	local info = ensureSettings(id)
	local frame = CreateFrame("Frame", addonName .. "DataPanel" .. id, UIParent, "BackdropTemplate")
	frame:SetSize(info.width, info.height)
	frame:SetPoint(info.point, info.x, info.y)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		savePosition(f, id)
	end)
	frame:SetScript("OnMouseDown", function(f, btn)
		if btn == "RightButton" then f:StartSizing("BOTTOMRIGHT") end
	end)
	frame:SetScript("OnMouseUp", function(f, btn)
		if btn == "RightButton" then
			f:StopMovingOrSizing()
			savePosition(f, id)
		end
	end)
	frame:SetScript("OnSizeChanged", function(f) savePosition(f, id) end)
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.5)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetAllPoints()
	text:SetJustifyH("LEFT")
	text:SetWordWrap(true)
	frame.text = text

	local panel = { frame = frame, id = id, streams = {}, text = text }

	function panel:Refresh()
		local parts = {}
		for _, data in pairs(self.streams) do
			parts[#parts + 1] = data.text
		end
		self.text:SetText(table.concat(parts, " "))
	end

	function panel:AddStream(name)
		if self.streams[name] then return end
		local data = { text = "" }
		local function cb(snapshot)
			local rows = {}
			for _, row in ipairs(snapshot or {}) do
				if type(row) == "table" then
					local cols = {}
					for _, v in pairs(row) do
						if type(v) ~= "table" then cols[#cols + 1] = tostring(v) end
					end
					rows[#rows + 1] = table.concat(cols, " ")
				else
					rows[#rows + 1] = tostring(row)
				end
			end
			data.text = table.concat(rows, " | ")
			self:Refresh()
		end
		data.unsub = DataHub:Subscribe(name, cb)
		self.streams[name] = data
	end

	function panel:RemoveStream(name)
		local info = self.streams[name]
		if not info then return end
		if info.unsub then info.unsub() end
		self.streams[name] = nil
		self:Refresh()
	end

	panels[id] = panel
	return panel
end

SLASH_EQOLPANEL1 = "/eqolpanel"
SlashCmdList.EQOLPANEL = function(msg)
	local cmd, rest = msg:match("^(%S*)%s*(.-)$")
	if cmd == "create" then
		local id, w, h = rest:match("^(%S+)%s*(%d*)%s*(%d*)")
		if id then
			local panel = DataPanel.Create(id)
			if w ~= "" and h ~= "" then panel.frame:SetSize(tonumber(w), tonumber(h)) end
		end
	elseif cmd == "add" then
		local id, stream = rest:match("^(%S+)%s+(%S+)$")
		if id and stream then
			local panel = DataPanel.Create(id)
			panel:AddStream(stream)
		end
	elseif cmd == "remove" then
		local id, stream = rest:match("^(%S+)%s+(%S+)$")
		if id and stream and panels[id] then panels[id]:RemoveStream(stream) end
	else
		print("/eqolpanel create <id> [width] [height]")
		print("/eqolpanel add <id> <stream>")
		print("/eqolpanel remove <id> <stream>")
	end
end

return DataPanel
