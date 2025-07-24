# Deprecated Stuff to remove

## Release of 11.2 Patch

Reference: <https://warcraft.wiki.gg/wiki/Patch_11.2.0/API_changes>

### BankFrame Updates

#### Removed Stuff

- _NUM_BANKGENERIC_SLOTS_
  - Used in EnhanceQoL
- _\_G.AccountBankPanel_
  - Used in EnhanceQoL
- IsReagentBankUnlocked
  - Used in EnhanceQoLTooltip
- L["Reagentbank"]
  - Used in EnhanceQoLTooltip

### API Transitions

These global functions are deprecated in 11.2 and should be replaced once support for pre-11.2 versions is dropped.

- `GetSpecializationInfo` -> `C_SpecializationInfo.GetSpecializationInfo`
- `GetSpecialization` -> `C_SpecializationInfo.GetSpecialization`
- `GetActiveSpecGroup` -> `C_SpecializationInfo.GetActiveSpecGroup`
- `IsSpellKnown` / `IsSpellKnownOrOverridesKnown` -> `C_SpellBook.IsSpellInSpellBook`
- `SendChatMessage` -> `C_ChatInfo.SendChatMessage`
- `EquipmentManager_UnpackLocation` will change in 12.0 when Void Storage is removed
- Translation key `L["Reagentbank"]` will no longer be needed
