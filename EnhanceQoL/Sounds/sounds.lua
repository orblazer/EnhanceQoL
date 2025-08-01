local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end
local LSM = LibStub("LibSharedMedia-3.0")
local voiceoverPath = "Interface\\AddOns\\" .. parentAddonName .. "\\Sounds\\"
local chatIMSoundpath = "Interface\\AddOns\\" .. parentAddonName .. "\\Sounds\\ChatIM\\"

-- Chat Sounds
LSM:Register("sound", "Bell", chatIMSoundpath .. "Bell.ogg")
LSM:Register("sound", "Cheerfull", chatIMSoundpath .. "Cheerfull.ogg")
LSM:Register("sound", "Laughing", chatIMSoundpath .. "Laughing.ogg")
LSM:Register("sound", "LightMetallic", chatIMSoundpath .. "LightMetallic.ogg")
LSM:Register("sound", "Ping", chatIMSoundpath .. "Ping.ogg")
LSM:Register("sound", "Ring", chatIMSoundpath .. "Ring.ogg")
LSM:Register("sound", "Sonarr", chatIMSoundpath .. "Sonarr.ogg")

-- Soundeffects
LSM:Register("sound", "For the Horde", "Interface\\AddOns\\EnhanceQoL\\Sounds\\bloodlust.ogg")
LSM:Register("sound", "EQOL: Bite", "Interface\\AddOns\\EnhanceQoL\\Sounds\\cartoonbite.ogg")
LSM:Register("sound", "EQOL: Punch", "Interface\\AddOns\\EnhanceQoL\\Sounds\\gamingpunch.ogg")

-- Voiceovers
LSM:Register("sound", "EQOL: Adds", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Adds.ogg")
LSM:Register("sound", "EQOL: Add", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Add.ogg")
LSM:Register("sound", "EQOL: AoE", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\AoE.ogg")
LSM:Register("sound", "EQOL: Assist", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Assist.ogg")
LSM:Register("sound", "EQOL: Avoid", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Avoid.ogg")
LSM:Register("sound", "EQOL: Bait", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Bait.ogg")
LSM:Register("sound", "EQOL: Bleed", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Bleed.ogg")
LSM:Register("sound", "EQOL: CC", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\CC.ogg")
LSM:Register("sound", "EQOL: Charge", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Charge.ogg")
LSM:Register("sound", "EQOL: Clear", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Clear.ogg")
LSM:Register("sound", "EQOL: Dance", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Dance.ogg")
LSM:Register("sound", "EQOL: Debuff", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Debuff.ogg")
LSM:Register("sound", "EQOL: Decurse", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Decurse.ogg")
LSM:Register("sound", "EQOL: Defensive", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Defensive.ogg")
LSM:Register("sound", "EQOL: Dispell", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Dispell.ogg")
LSM:Register("sound", "EQOL: Dot", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Dot.ogg")
LSM:Register("sound", "EQOL: Don't move", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Don't move.ogg")
LSM:Register("sound", "EQOL: Drop", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Drop.ogg")
LSM:Register("sound", "EQOL: Enrage", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Enrage.ogg")
LSM:Register("sound", "EQOL: Enter", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Enter.ogg")
LSM:Register("sound", "EQOL: Feet", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Feet.ogg")
LSM:Register("sound", "EQOL: Fixate", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Fixate.ogg")
LSM:Register("sound", "EQOL: Focus", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Focus.ogg")
LSM:Register("sound", "EQOL: Frontal", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Frontal.ogg")
LSM:Register("sound", "EQOL: Hide", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Hide.ogg")
LSM:Register("sound", "EQOL: Immunity", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Immunity.ogg")
LSM:Register("sound", "EQOL: Intermission", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Intermission.ogg")
LSM:Register("sound", "EQOL: Interrupt", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Interrupt.ogg")
LSM:Register("sound", "EQOL: Invis", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Invis.ogg")
LSM:Register("sound", "EQOL: Jump", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Jump.ogg")
LSM:Register("sound", "EQOL: Knock", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Knock.ogg")
LSM:Register("sound", "EQOL: Move", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Move.ogg")
LSM:Register("sound", "EQOL: Pull", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Pull.ogg")
LSM:Register("sound", "EQOL: Reflect", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Reflect.ogg")
LSM:Register("sound", "EQOL: Roar |T463283:16|t", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Roar.ogg")
LSM:Register("sound", "EQOL: Root", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Root.ogg")
LSM:Register("sound", "EQOL: Soak", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Soak.ogg")
LSM:Register("sound", "EQOL: Soon", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Soon.ogg")
LSM:Register("sound", "EQOL: Spread", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Spread.ogg")
LSM:Register("sound", "EQOL: Stack", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Stack.ogg")
LSM:Register("sound", "EQOL: Stopcast", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Stopcast.ogg")
LSM:Register("sound", "EQOL: Stun", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Stun.ogg")
LSM:Register("sound", "EQOL: Targeted", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Targeted.ogg")
LSM:Register("sound", "EQOL: Turn", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Turn.ogg")
LSM:Register("sound", "EQOL: Use", "Interface\\AddOns\\EnhanceQoL\\Sounds\\voiceover\\Use.ogg")
