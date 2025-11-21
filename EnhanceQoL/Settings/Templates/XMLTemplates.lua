local addonName, addon = ...
EQOL_SettingsListSectionHeaderMixin = CreateFromMixins(SettingsListSectionHeaderMixin)

function EQOL_SettingsListSectionHeaderMixin:Init(initializer)
	SettingsListSectionHeaderMixin.Init(self, initializer)

	local data = initializer:GetData()
	if addon.variables.NewVersionTableEQOL[data.newTagID] then self.NewFeature:SetShown(true) end
end
