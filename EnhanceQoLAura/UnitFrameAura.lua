local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
        addon = _G[parentAddonName]
else
        error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL_Aura")

addon.Aura.unitFrame = {}

local function ensureIcon(frame)
        if frame.EQOLTrackedAura then return frame.EQOLTrackedAura end
        local iconFrame = CreateFrame("Frame", nil, frame)
        iconFrame:SetSize(20, 20)
        iconFrame:SetPoint("CENTER", frame)
        local tex = iconFrame:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(iconFrame)
        iconFrame.icon = tex
        frame.EQOLTrackedAura = iconFrame
        return iconFrame
end

local function UpdateTrackedBuffs(frame, unit)
        if not frame or not unit or not addon.db.unitFrameAuraIDs then return end
        local iconFrame = ensureIcon(frame)
        iconFrame:Hide()
        for i = 1, 40 do
                local name, icon, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
                if not name then break end
                if addon.db.unitFrameAuraIDs[spellId] then
                        iconFrame.icon:SetTexture(icon)
                        iconFrame:Show()
                        return
                end
        end
end

addon.Aura.unitFrame.Update = UpdateTrackedBuffs

local function RefreshAll()
        if CompactRaidFrameContainer and CompactRaidFrameContainer.GetFrames then
                for frame in CompactRaidFrameContainer:GetFrames() do
                        UpdateTrackedBuffs(frame, frame.unit)
                end
        end
        for i = 1, 5 do
                local f = _G["CompactPartyFrameMember" .. i]
                if f then UpdateTrackedBuffs(f, f.unit) end
        end
end

addon.Aura.unitFrame.RefreshAll = RefreshAll

local function HookCUF(frame)
        if frame.__eqolBuffHooked then return end
        hooksecurefunc(frame, "UpdateAuras", function(f) UpdateTrackedBuffs(f, f.unit) end)
        frame.__eqolBuffHooked = true
end

hooksecurefunc("CompactUnitFrame_SetUpFrame", HookCUF)
if CompactRaidFrameContainer and CompactRaidFrameContainer.GetFrames then
        for frame in CompactRaidFrameContainer:GetFrames() do HookCUF(frame) end
end
for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f then HookCUF(f) end
end

function addon.Aura.functions.addUnitFrameAuraOptions(container)
        local wrapper = addon.functions.createContainer("SimpleGroup", "Flow")
        wrapper:SetFullWidth(true)
        container:AddChild(wrapper)

        local drop
        local function refresh()
                local list, order = addon.functions.prepareListForDropdown(addon.db.unitFrameAuraIDs)
                drop:SetList(list, order)
                drop:SetValue(nil)
                RefreshAll()
        end

        local edit = addon.functions.createEditboxAce(L["AddSpellID"], nil, function(self, _, text)
                local id = tonumber(text)
                if id then
                        local info = C_Spell.GetSpellInfo(id)
                        if info then
                                addon.db.unitFrameAuraIDs[id] = string.format("%s (%d)", info.name, id)
                                refresh()
                        end
                end
                self:SetText("")
        end)
        wrapper:AddChild(edit)

        local list, order = addon.functions.prepareListForDropdown(addon.db.unitFrameAuraIDs)
        drop = addon.functions.createDropdownAce(L["TrackedAuras"], list, order, nil)
        wrapper:AddChild(drop)

        local btn = addon.functions.createButtonAce(REMOVE, 100, function()
                local sel = drop:GetValue()
                if sel then
                        addon.db.unitFrameAuraIDs[sel] = nil
                        refresh()
                end
        end)
        wrapper:AddChild(btn)
end
