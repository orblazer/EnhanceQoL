local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local frame = CreateFrame("Frame", "EnhanceQoLQueryFrame", UIParent, "BasicFrameTemplateWithInset")
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local currentGroup = "generator" -- UI group: generator|inspector
local currentMode = "drink" -- one of: "drink", "potion", "auto"
local reSearchList = {}
local resultsAHSearch = {}
local lastProcessedBrowseCount = 0
local browseStallCount = 0

local executeSearch = false

addon.Query = {}

frame:SetSize(520, 420)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetResizable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide() -- Initially hide the frame

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText(addonName)

-- Right content area that auto-resizes with the window
frame.content = CreateFrame("Frame", nil, frame)
frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 160, -60)
frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 50)

-- Mode controls
local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modeLabel:ClearAllPoints()
modeLabel:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
modeLabel:SetText("Mode:")
modeLabel:Hide() -- legacy UI hidden; AceGUI window is used

local function setMode(mode)
    currentMode = mode
    if frame and frame.title then
        frame.title:SetText(string.format("%s - %s", addonName or "Query", (mode == "drink" and "Drinks") or (mode == "potion" and "Mana Potions") or "Auto"))
    end
    if frame.scanButton then
        frame.scanButton:SetText(mode == "potion" and "Scan Potions" or "Scan Drinks")
    end
end

local btnModeDrink = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnModeDrink:SetPoint("TOPLEFT", modeLabel, "TOPRIGHT", 6, 0)
btnModeDrink:SetSize(80, 20)
btnModeDrink:SetText("Drinks")
btnModeDrink:SetScript("OnClick", function() setMode("drink") end)
btnModeDrink:Hide()

local btnModePotion = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnModePotion:SetPoint("LEFT", btnModeDrink, "RIGHT", 4, 0)
btnModePotion:SetSize(100, 20)
btnModePotion:SetText("Mana Potions")
btnModePotion:SetScript("OnClick", function() setMode("potion") end)
btnModePotion:Hide()

local btnModeAuto = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnModeAuto:SetPoint("LEFT", btnModePotion, "RIGHT", 4, 0)
btnModeAuto:SetSize(60, 20)
btnModeAuto:SetText("Auto")
btnModeAuto:SetScript("OnClick", function() setMode("auto") end)
btnModeAuto:Hide()

frame.editBox = CreateFrame("ScrollFrame", nil, frame.content, "UIPanelScrollFrameTemplate")
frame.editBox:ClearAllPoints()
frame.editBox:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -24)
frame.editBox:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, -24)
frame.editBox:SetHeight(60)
frame.editBox:Hide()

frame.editEditBox = CreateFrame("EditBox", nil, frame.editBox)
frame.editEditBox:SetSize(480, 60)
frame.editEditBox:SetMultiLine(true)
frame.editEditBox:SetAutoFocus(false)
frame.editEditBox:SetFontObject("ChatFontNormal")
frame.editBox:SetScrollChild(frame.editEditBox)
frame.editEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

frame.outputBox = CreateFrame("ScrollFrame", nil, frame.content, "UIPanelScrollFrameTemplate")
frame.outputBox:ClearAllPoints()
frame.outputBox:SetPoint("TOPLEFT", frame.editBox, "BOTTOMLEFT", 0, -12)
frame.outputBox:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", 0, 30)
frame.outputBox:Hide()

frame.outputEditBox = CreateFrame("EditBox", nil, frame.outputBox)
frame.outputEditBox:SetSize(480, 230)
frame.outputEditBox:SetMultiLine(true)
frame.outputEditBox:SetAutoFocus(false)
frame.outputEditBox:SetFontObject("ChatFontNormal")
frame.outputBox:SetScrollChild(frame.outputEditBox)
frame.outputEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

local addedItems = {} -- known items already present in code lists
local inputAdded = {} -- items the user has added in the current input session
local addedResults = {}

local function seedKnownItems()
    wipe(addedItems)
    if addon and addon.Drinks and addon.Drinks.drinkList then
        for _, drink in ipairs(addon.Drinks.drinkList) do
            if drink and drink.id then addedItems[tostring(drink.id)] = true end
        end
    end
    if addon and addon.Drinks and addon.Drinks.manaPotions then
        for _, pot in ipairs(addon.Drinks.manaPotions) do
            if pot and pot.id then addedItems[tostring(pot.id)] = true end
        end
    end
end

local tooltip = CreateFrame("GameTooltip", "EnhanceQoLQueryTooltip", UIParent, "GameTooltipTemplate")

local function extractManaFromTooltip(itemLink)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    local mana = 0

    for i = 1, tooltip:NumLines() do
        local text = _G["EnhanceQoLQueryTooltipTextLeft" .. i]:GetText()
        if text and text:lower():find("mana") then
            -- Prefer explicit "million mana" match to avoid picking up unrelated "million" (e.g., health)
            local millionStr = text:lower():match("([%d%.,]+)%s*million%s*mana")
            if millionStr then
                local clean = (millionStr:gsub(",", "")) -- keep decimal dot for fractional millions
                local v = tonumber(clean) or 0
                mana = math.floor(v * 1000000 + 0.5)
                break
            end
            -- Fallback: plain numeric before "mana" (supports thousands separators)
            local plainStr = text:match("([%d%.,]+)%s*mana")
            if plainStr then
                local clean = plainStr:gsub("[,%.]", "")
                mana = tonumber(clean) or 0
                break
            end
        end
    end

    tooltip:Hide()
    return mana
end

local function extractWellFedFromTooltip(itemLink)
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	local buffFood = "false"

	for i = 1, tooltip:NumLines() do
		local text = _G["EnhanceQoLQueryTooltipTextLeft" .. i]:GetText()
		if text and (text:match("well fed") or text:match("Well Fed")) then
			buffFood = "true"
			break
		end
	end

	tooltip:Hide()
	return buffFood
end

local function classifyItemByIDs(itemID)
    if not itemID then return nil end
    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    if classID == Enum.ItemClass.Consumable then
        if subClassID == Enum.ItemConsumableSubclass.Fooddrink then return "drink" end
        if subClassID == Enum.ItemConsumableSubclass.Potion then return "potion" end
    end
    if classID == Enum.ItemClass.Gem then return "gem" end
    return nil
end

local function sanitizeKey(name)
    local formatted = tostring(name or "")
    -- Remove quotes and collapse spaces to avoid invalid Lua string keys
    formatted = formatted:gsub('"', "")
    formatted = formatted:gsub("'", "")
    formatted = formatted:gsub("%s+", "")
    -- Fallback if empty after sanitization
    if formatted == "" then formatted = "item" end
    return formatted
end

-- Pretty text for item quality
local function qualityText(q)
    local n = tonumber(q) or 0
    local names = {
        [0] = "Poor", [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
        [5] = "Legendary", [6] = "Artifact", [7] = "Heirloom", [8] = "WoWToken",
    }
    return string.format("%s (%d)", names[n] or tostring(n), n)
end

-- Public inspector function used by AceUI and Shift+Click when in inspector
function addon.Query.showItem(itemLink)
    local name, link, quality, ilvl, reqLevel, type, subType, stack, equipLoc, icon, sellPrice,
        classID, subClassID, bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(itemLink)
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    local effIlvl = (GetDetailedItemLevelInfo and select(1, GetDetailedItemLevelInfo(itemLink))) or ilvl
    local stats = GetItemStats and GetItemStats(itemLink) or nil

    local lines = {}
    table.insert(lines, string.format("Name: %s", name or "?"))
    table.insert(lines, string.format("Item ID: %s", itemID or "?"))
    table.insert(lines, string.format("Link: %s", link or "?"))
    table.insert(lines, string.format("Quality: %s", qualityText(quality)))
    table.insert(lines, string.format("Item Level: %s", effIlvl or "?"))
    table.insert(lines, string.format("Required Level: %s", reqLevel or "?"))
    table.insert(lines, string.format("Type: %s", type or "?"))
    table.insert(lines, string.format("Subtype: %s", subType or "?"))
    table.insert(lines, string.format("ClassID/SubClassID: %s/%s", tostring(classID or "?"), tostring(subClassID or "?")))
    table.insert(lines, string.format("Stack Size: %s", stack or "?"))
    table.insert(lines, string.format("Equip Slot: %s", equipLoc or ""))
    table.insert(lines, string.format("Icon: %s |T%s:16:16:0:0|t", tostring(icon or ""), tostring(icon or "")))
    if sellPrice and sellPrice > 0 then
        table.insert(lines, string.format("Sell Price: %s", GetCoinTextureString and GetCoinTextureString(sellPrice) or tostring(sellPrice)))
    end
    if isCraftingReagent ~= nil then table.insert(lines, string.format("Crafting Reagent: %s", tostring(isCraftingReagent))) end

    if stats then
        table.insert(lines, " ")
        table.insert(lines, "Stats:")
        for k, v in pairs(stats) do
            local nice = _G[k] or k
            table.insert(lines, string.format(" - %s: %s", nice, tostring(v)))
        end
    end

    if addon.Query.ui and addon.Query.ui.inspectorOutput then
        addon.Query.ui.inspectorOutput:SetText(table.concat(lines, "\n"))
    end
end

local function formatDrinkString(name, itemID, minLevel, mana, isBuffFood)
    local formattedKey = sanitizeKey(name) ~= "" and sanitizeKey(name) or ("item" .. tostring(itemID))
    return string.format('{ key = "%s", id = %d, requiredLevel = %d, mana = %d, isBuffFood = %s }', formattedKey, itemID, minLevel or 1, mana or 0, tostring(isBuffFood))
end

local function formatGemDrinkString(name, itemID, minLevel, mana, isBuffFood)
    local formattedKey = sanitizeKey(name) ~= "" and sanitizeKey(name) or ("item" .. tostring(itemID))
    return string.format('{ key = "%s", id = %d, requiredLevel = %d, mana = %d, isBuffFood = %s, isEarthenFood = true, earthenOnly = true }', formattedKey, itemID, minLevel or 1, mana or 0, tostring(isBuffFood))
end

local function formatPotionString(name, itemID, minLevel, mana)
    local formattedKey = sanitizeKey(name) ~= "" and sanitizeKey(name) or ("item" .. tostring(itemID))
    return string.format('{ key = "%s", id = %d, requiredLevel = %d, mana = %d }', formattedKey, itemID, minLevel or 1, mana or 0)
end

local function updateItemInfo(itemLink)
	if not itemLink then return end
	local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, texture = C_Item.GetItemInfo(itemLink)
	local mana = extractManaFromTooltip(itemLink)
	if name and type and subType and minLevel and mana > 0 then
		local itemID = tonumber(itemLink:match("item:(%d+)"))
		local kind = currentMode
		if kind == "auto" then kind = classifyItemByIDs(itemID) or "drink" end
		if kind == "potion" then
			return formatPotionString(name, itemID, minLevel, mana)
		else
			local buffFood = extractWellFedFromTooltip(itemLink)
			if type == "Gem" then
				return formatGemDrinkString(name, itemID, minLevel, mana, buffFood)
			else
				return formatDrinkString(name, itemID, minLevel, mana, buffFood)
			end
		end
	end
	return nil
end

local loadedResults = {}

frame.editEditBox:SetScript("OnTextChanged", function(self)
	local itemLinks = { strsplit(" ", self:GetText()) }
	local results = {}

	for _, itemLink in ipairs(itemLinks) do
		local itemID = itemLink:match("item:(%d+)")
		if nil ~= itemID then
			local result = nil
			if nil == loadedResults[itemID] then
				result = updateItemInfo(itemLink)
				loadedResults[itemID] = result
			else
				result = loadedResults[itemID]
			end
			if result then table.insert(results, result) end
		end
	end

    UI_SetOutput(table.concat(results, ",\n        "))
end)


local function addToSearchResult(itemID)
	local name, link, quality, level, minLevel, type, subType = C_Item.GetItemInfo(itemID)
	if not link then return end
	local mana = extractManaFromTooltip(link)
	if not (name and type and subType and minLevel and mana > 0) then return end
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	local result
	if currentMode == "potion" then
		if classID == Enum.ItemClass.Consumable and subClassID == Enum.ItemConsumableSubclass.Potion then
			result = formatPotionString(name, itemID, minLevel, mana)
		end
	else
		if classID == Enum.ItemClass.Consumable and subClassID == Enum.ItemConsumableSubclass.Fooddrink then
			local buffFood = extractWellFedFromTooltip(link)
			result = formatDrinkString(name, itemID, minLevel, mana, buffFood)
		end
	end
	-- Skip items already in our master lists or already added in this session
	if result and not addedItems[tostring(itemID)] and not addedResults[tostring(itemID)] then
		addedResults[tostring(itemID)] = true
		table.insert(resultsAHSearch, result)
	end
    UI_SetOutput(table.concat(resultsAHSearch, ",\n        "))
end

local function handleItemLink(text)
	local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc, texture = C_Item.GetItemInfo(text)
	local itemID = text and text:match("item:(%d+)") and tonumber(text:match("item:(%d+)")) or nil
	local kind = currentMode
	if kind == "auto" then kind = classifyItemByIDs(itemID) or "drink" end
	local isDrink = (type == "Consumable" and subType == "Food & Drink") or (type == "Gem" and select(2, UnitRace("player")) == "EarthenDwarf")
	local isPotion = (type == "Consumable" and subType == "Potion")
    if (kind == "drink" and isDrink) or (kind == "potion" and isPotion) or (kind == "drink" and type == "Gem") then
        local itemId = text:match("item:(%d+)")
        if not inputAdded[itemId] then
            inputAdded[itemId] = true
            if addon.Query.ui and addon.Query.ui.input then
                local currentText = addon.Query.ui.input:GetText() or ""
                addon.Query.ui.input:SetText((currentText ~= "" and (currentText .. " ") or "") .. text)
            elseif frame.editEditBox then
                local currentText = frame.editEditBox:GetText()
                frame.editEditBox:SetText(currentText .. " " .. text)
                frame.editEditBox:GetScript("OnTextChanged")(frame.editEditBox)
            end
        else
            print("Item is already in the list.")
        end
	else
		print("Item not matching mode or not supported.")
	end
end

local function BuildAceWindow()
    if not AceGUI then return end
    if addon.Query.ui and addon.Query.ui.window then return end
    local win = AceGUI:Create("Window")
    addon.Query.ui = addon.Query.ui or {}
    addon.Query.ui.window = win
    win:SetTitle("EnhanceQoLQuery - Drinks")
    win:SetWidth(700)
    win:SetHeight(520)
    win:SetLayout("Fill")

    local tree = AceGUI:Create("TreeGroup")
    addon.Query.ui.tree = tree
    tree:SetTree({ { value = "generator", text = "Generator" }, { value = "inspector", text = "Inspector" } })
    tree:SetLayout("Fill")
    win:AddChild(tree)

    local function buildGenerator(container)
        addon.Query.ui.activeGroup = "generator"
        container:ReleaseChildren()
        local outer = AceGUI:Create("SimpleGroup"); outer:SetFullWidth(true); outer:SetFullHeight(true); outer:SetLayout("List"); container:AddChild(outer)

        local row = AceGUI:Create("SimpleGroup"); row:SetFullWidth(true); row:SetLayout("Flow"); outer:AddChild(row)
        local lbl = AceGUI:Create("Label"); lbl:SetText("Mode:"); lbl:SetWidth(60); row:AddChild(lbl)
        local b1 = AceGUI:Create("Button"); b1:SetText("Drinks"); b1:SetWidth(100); b1:SetCallback("OnClick", function() setMode("drink") end); row:AddChild(b1)
        local b2 = AceGUI:Create("Button"); b2:SetText("Mana Potions"); b2:SetWidth(120); b2:SetCallback("OnClick", function() setMode("potion") end); row:AddChild(b2)
        local b3 = AceGUI:Create("Button"); b3:SetText("Auto"); b3:SetWidth(80); b3:SetCallback("OnClick", function() setMode("auto") end); row:AddChild(b3)

        local input = AceGUI:Create("MultiLineEditBox"); input:SetLabel("Input (paste item links/IDs; Shift+Click adds here)"); input:SetFullWidth(true); input:SetNumLines(3); input:DisableButton(true); input:SetCallback("OnTextChanged", function(_,_,t) processInputText(t) end); outer:AddChild(input); addon.Query.ui.input = input
        local output = AceGUI:Create("MultiLineEditBox"); output:SetLabel("Generated table rows"); output:SetFullWidth(true); output:SetNumLines(16); output:DisableButton(true); outer:AddChild(output); addon.Query.ui.output = output

        local bottom = AceGUI:Create("SimpleGroup"); bottom:SetFullWidth(true); bottom:SetLayout("Flow"); outer:AddChild(bottom)
        local scanBtn = AceGUI:Create("Button"); scanBtn:SetText("Scan Drinks"); scanBtn:SetWidth(140); scanBtn:SetCallback("OnClick", function()
            executeSearch = true; lastProcessedBrowseCount = 0; browseStallCount = 0
            if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
                local query
                if currentMode == "potion" then
                    query = { searchString = "", sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = true } }, filters = { Enum.AuctionHouseFilter.Potions }, itemClassFilters = { { classID = Enum.ItemClass.Consumable, subClassID = Enum.ItemConsumableSubclass.Potion } } }
                else
                    query = { searchString = "", sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = true } }, itemClassFilters = { { classID = Enum.ItemClass.Consumable, subClassID = Enum.ItemConsumableSubclass.Fooddrink } } }
                end
                reSearchList = {}; resultsAHSearch = {}; addedResults = {}; C_AuctionHouse.SendBrowseQuery(query)
            else
                print("Auction House is not open.")
            end
        end); bottom:AddChild(scanBtn); addon.Query.ui.scanBtn = scanBtn
        local clearBtn = AceGUI:Create("Button"); clearBtn:SetText("Clear"); clearBtn:SetWidth(120); clearBtn:SetCallback("OnClick", function() input:SetText(""); output:SetText(""); addedResults = {}; resultsAHSearch = {}; inputAdded = {}; wipe(loadedResults) end); bottom:AddChild(clearBtn)
        local copyBtn = AceGUI:Create("Button"); copyBtn:SetText("Copy"); copyBtn:SetWidth(120); copyBtn:SetCallback("OnClick", function() output:SetFocus(); output:HighlightText(); C_Timer.After(0.8, function() output:ClearFocus() end) end); bottom:AddChild(copyBtn)
    end

    local function buildInspector(container)
        addon.Query.ui.activeGroup = "inspector"
        container:ReleaseChildren()
        local outer = AceGUI:Create("SimpleGroup"); outer:SetFullWidth(true); outer:SetFullHeight(true); outer:SetLayout("List"); container:AddChild(outer)
        local tip = AceGUI:Create("Label"); tip:SetText("Shift+Click an item link or press the button below to load from cursor."); tip:SetFullWidth(true); outer:AddChild(tip)
        local pick = AceGUI:Create("Button"); pick:SetText("Load item from cursor"); pick:SetWidth(200); pick:SetCallback("OnClick", function() local t,_,link = GetCursorInfo(); if t=="item" and link then addon.Query.showItem(link); ClearCursor() end end); outer:AddChild(pick)
        local output = AceGUI:Create("MultiLineEditBox"); output:SetLabel("Item details"); output:SetFullWidth(true); output:SetNumLines(18); output:DisableButton(true); outer:AddChild(output); addon.Query.ui.inspectorOutput = output
        local follow = AceGUI:Create("CheckBox"); follow:SetLabel("Enable follow-up calls (experimental)"); addon.functions.InitDBValue("queryFollowupEnabled", false); follow:SetValue(addon.db.queryFollowupEnabled); follow:SetCallback("OnValueChanged", function(_,_,v) addon.db.queryFollowupEnabled = v and true or false end); outer:AddChild(follow)
    end

    tree:SetCallback("OnGroupSelected", function(_, _, group) if group=="generator" then buildGenerator(tree) else buildInspector(tree) end end)
    tree:SelectByValue("generator")
    setMode(currentMode)
end

local function onAddonLoaded(event, addonName)
    if addonName == "EnhanceQoLQuery" then
        -- Registriere den Slash-Command für /rq
        SLASH_EnhanceQoLQUERY1 = "/rq"
        SlashCmdList["EnhanceQoLQUERY"] = function(msg)
            if not (addon.Query.ui and addon.Query.ui.window) then BuildAceWindow() end
            if addon.Query.ui and addon.Query.ui.window then addon.Query.ui.window:Show() end
        end

        print("EnhanceQoLQuery command registered: /rq")
    end
end

local function onItemPush(bag, slot)
	if nil == bag or nil == slot then return end
	if bag < 0 or bag > 5 or slot < 1 or slot > C_Container.GetContainerNumSlots(bag) then return end
	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if itemLink then handleItemLink(itemLink) end
end

local function onAuctionHouseEvent(self, event, ...)
	if executeSearch then
		if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
			local browseResults = C_AuctionHouse.GetBrowseResults() or {}
			-- process only new entries since last event to avoid duplicates
			local currentCount = #browseResults
			if currentCount > lastProcessedBrowseCount then
				for i = lastProcessedBrowseCount + 1, currentCount do
					local itemID = browseResults[i] and browseResults[i].itemKey and browseResults[i].itemKey.itemID
					if itemID then
						local _, link = C_Item.GetItemInfo(itemID)
						if nil == link then
							reSearchList[itemID] = true
						else
							addToSearchResult(itemID)
						end
					end
				end
				lastProcessedBrowseCount = currentCount
				browseStallCount = 0
				-- attempt to request more pages if API available
				if C_AuctionHouse.RequestMoreBrowseResults then C_AuctionHouse.RequestMoreBrowseResults() end
			else
				-- No growth, count stalls; stop after a couple of no-growth events
				browseStallCount = (browseStallCount or 0) + 1
				if browseStallCount >= 2 then
					executeSearch = false
					lastProcessedBrowseCount = 0
					browseStallCount = 0
				end
			end
		end
	end
end

local function onGetItemInfoReceived(...)
	local itemID, success = ...
	if success == true and reSearchList[itemID] == true then addToSearchResult(itemID) end
end

local function onEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		-- Ensure slash command is registered as soon as the addon loads
    onAddonLoaded(event, ...)
    seedKnownItems()
	elseif event == "PLAYER_LOGIN" then
		-- Fallback: also register slash on login and seed known items
    onAddonLoaded(event, "EnhanceQoLQuery")
    seedKnownItems()
    elseif event == "ITEM_PUSH" and (addon.Query.ui and addon.Query.ui.window and addon.Query.ui.window.frame and addon.Query.ui.window.frame:IsShown()) then
        onItemPush(...)
    elseif event == "GET_ITEM_INFO_RECEIVED" and (addon.Query.ui and addon.Query.ui.window and addon.Query.ui.window.frame and addon.Query.ui.window.frame:IsShown()) then
        onGetItemInfoReceived(...)
    elseif (addon.Query.ui and addon.Query.ui.window and addon.Query.ui.window.frame and addon.Query.ui.window.frame:IsShown()) then
        onAuctionHouseEvent(self, event, ...)
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ITEM_PUSH")
frame:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", onEvent)

-- Handling Shift+Click to add item link to the EditBox and clear previous item
hooksecurefunc("ChatEdit_InsertLink", function(itemLink)
    local shown = (addon.Query.ui and addon.Query.ui.window and addon.Query.ui.window.frame and addon.Query.ui.window.frame:IsShown())
    if itemLink and shown then
        if addon.Query.ui and addon.Query.ui.activeGroup == "inspector" and addon.Query.showItem then
            addon.Query.showItem(itemLink)
        else
            handleItemLink(itemLink)
        end
        return true
    end
end)

-- Button to copy the output to the clipboard
-- legacy copy button hidden (AceGUI provides UI)
do
    local copyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    copyButton:Hide()
    frame.copyButton = nil
end

-- Button to scan auction house items
local scanButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
scanButton:Hide()
scanButton:SetScript("OnClick", function()
	executeSearch = true
	lastProcessedBrowseCount = 0
	browseStallCount = 0
	if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
		-- local function SearchAuctionHouseByMultipleItemIDs(itemIDs)
		--     local itemKeys = {}

		--     for _, itemID in ipairs(itemIDs) do
		--         local itemKey = C_AuctionHouse.MakeItemKey(itemID)
		--         if itemKey then
		--             table.insert(itemKeys, itemKey)
		--         else
		--             print("Kein ItemKey für ItemID:", itemID)
		--         end
		--     end

		--     if #itemKeys > 0 then
		--         -- Sortieren nach Preis aufsteigend
		--         local sorts =
		--             {{sortOrder = 0, reverseSort = false} -- 0 ist der Index für Preis, "false" bedeutet aufsteigend
		--             }

		--         -- Suche nach allen ItemKeys gleichzeitig mit Sortierung
		--         C_AuctionHouse.SearchForItemKeys(itemKeys, sorts)
		--         print("Suche nach den ItemIDs:", table.concat(itemIDs, ", "))
		--     else
		--         print("Keine gültigen ItemKeys gefunden.")
		--     end
		-- end

		-- -- Beispielaufruf mit einer Liste von ItemIDs
		-- SearchAuctionHouseByMultipleItemIDs({221853, 221854, 221855, 221859, 221860, 221861, 221856, 221857, 221858})

		-- Build query according to mode
		local query
		if currentMode == "potion" then
			query = {
				searchString = "",
				sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = true } },
				filters = { Enum.AuctionHouseFilter.Potions },
				itemClassFilters = { { classID = Enum.ItemClass.Consumable, subClassID = Enum.ItemConsumableSubclass.Potion } },
			}
		else
			query = {
				searchString = "",
				sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = true } },
				itemClassFilters = { { classID = Enum.ItemClass.Consumable, subClassID = Enum.ItemConsumableSubclass.Fooddrink } },
			}
		end
		-- Clear per-scan buffers
		reSearchList = {}
		resultsAHSearch = {}
		addedResults = {}
		C_AuctionHouse.SendBrowseQuery(query)
	else
		print("Auction House is not open.")
	end
end)

frame.scanButton = scanButton

-- Left navigation tree (simple two entries)
local function buildLeftTree()
    if not AceGUI then return end
    local tree = AceGUI:Create("TreeGroup")
    tree.frame:SetParent(frame)
    tree.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
    tree.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    tree:SetWidth(140)
    tree:SetTree({ { value = "generator", text = "Generator" }, { value = "inspector", text = "Inspector" } })
    tree:EnableButtonTooltips(false)
    tree:SetCallback("OnGroupSelected", function(_, _, group)
        currentGroup = group or "generator"
        -- Toggle visibility of groups
        local genVisible = (currentGroup == "generator")
        modeLabel:SetShown(genVisible)
        btnModeDrink:SetShown(genVisible)
        btnModePotion:SetShown(genVisible)
        btnModeAuto:SetShown(genVisible)
        frame.editBox:SetShown(genVisible)
        frame.outputBox:SetShown(genVisible)
        if frame.copyButton then frame.copyButton:SetShown(genVisible) end
        if frame.scanButton then frame.scanButton:SetShown(genVisible) end
        if frame.clearButton then frame.clearButton:SetShown(genVisible) end
        -- Inspector visibility
        if frame.inspector then
            frame.inspector.drop:SetShown(not genVisible)
            frame.inspector.outputScroll:Show()
            frame.inspector.outputScroll:SetShown(not genVisible)
            frame.inspector.followup:SetShown(not genVisible)
        end
        -- Update scan button label based on mode
        if genVisible then setMode(currentMode) end
    end)
    frame.leftTree = tree
end

-- Clear button
do
    local clearButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearButton:Hide()
    frame.clearButton = nil
end

-- Initialize mode label/button state
setMode(currentMode)

-- Inspector UI (drop item and show details)
local function createInspectorUI()
    if frame.inspector then return end
    frame.inspector = {}
    local drop = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    drop:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    drop:SetSize(200, 40)
    drop:SetText("Drop item here / Shift+Click")
    drop:RegisterForClicks("AnyUp")
    drop:SetScript("OnClick", function()
        -- Try to read from cursor (drag & drop)
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" and itemLink then
            addon.Query.showItem(itemLink)
            ClearCursor()
        end
    end)
    drop:SetScript("OnReceiveDrag", function()
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" and itemLink then
            addon.Query.showItem(itemLink)
            ClearCursor()
        end
    end)
    frame.inspector.drop = drop

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", drop, "BOTTOMLEFT", 0, -12)
    scroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", 0, 0)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetSize(480, 280)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    scroll:SetScrollChild(edit)
    frame.inspector.outputScroll = scroll
    frame.inspector.outputEdit = edit

    local follow = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    follow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 0, 0)
    follow.Text:SetText("Enable follow-up calls (experimental)")
    addon.functions.InitDBValue("queryFollowupEnabled", false)
    follow:SetChecked(addon.db.queryFollowupEnabled)
    follow:SetScript("OnClick", function(self)
        addon.db.queryFollowupEnabled = self:GetChecked() and true or false
    end)
    frame.inspector.followup = follow

    local function qualityText(q)
        local n = tonumber(q) or 0
        local names = {
            [0] = "Poor", [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
            [5] = "Legendary", [6] = "Artifact", [7] = "Heirloom", [8] = "WoWToken",
        }
        return string.format("%s (%d)", names[n] or tostring(n), n)
    end

    function frame.inspector.showItem(itemLink)
        local name, link, quality, ilvl, reqLevel, type, subType, stack, equipLoc, icon, sellPrice,
            classID, subClassID, bindType, expacID, setID, isCraftingReagent = C_Item.GetItemInfo(itemLink)
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        local effIlvl = (GetDetailedItemLevelInfo and select(1, GetDetailedItemLevelInfo(itemLink))) or ilvl
        local stats = GetItemStats and GetItemStats(itemLink) or nil

        local lines = {}
        table.insert(lines, string.format("Name: %s", name or "?"))
        table.insert(lines, string.format("Item ID: %s", itemID or "?"))
        table.insert(lines, string.format("Link: %s", link or "?"))
        table.insert(lines, string.format("Quality: %s", qualityText(quality)))
        table.insert(lines, string.format("Item Level: %s", effIlvl or "?"))
        table.insert(lines, string.format("Required Level: %s", reqLevel or "?"))
        table.insert(lines, string.format("Type: %s", type or "?"))
        table.insert(lines, string.format("Subtype: %s", subType or "?"))
        table.insert(lines, string.format("ClassID/SubClassID: %s/%s", tostring(classID or "?"), tostring(subClassID or "?")))
        table.insert(lines, string.format("Stack Size: %s", stack or "?"))
        table.insert(lines, string.format("Equip Slot: %s", equipLoc or ""))
        table.insert(lines, string.format("Icon: %s |T%s:16:16:0:0|t", tostring(icon or ""), tostring(icon or "")))
        if sellPrice and sellPrice > 0 then
            table.insert(lines, string.format("Sell Price: %s", GetCoinTextureString and GetCoinTextureString(sellPrice) or tostring(sellPrice)))
        end
        if isCraftingReagent ~= nil then table.insert(lines, string.format("Crafting Reagent: %s", tostring(isCraftingReagent))) end

        if stats then
            table.insert(lines, " ")
            table.insert(lines, "Stats:")
            for k, v in pairs(stats) do
                local nice = _G[k] or k
                table.insert(lines, string.format(" - %s: %s", nice, tostring(v)))
            end
        end

        edit:SetText(table.concat(lines, "\n"))
    end
end

-- AceGUI window will be built on /rq; legacy UI not used

-- Hide inspector by default (shown when tree selects it)
if frame.inspector then frame.inspector.drop:Hide(); frame.inspector.outputScroll:Hide(); frame.inspector.followup:Hide() end

-- Now that all controls exist, select default group
-- No legacy tree selection; AceGUI manages selection

-- Simple resize handle (bottom-right corner)
-- No resizer for legacy frame; AceGUI handles resizing of its own window

addon.Query.frame = frame
