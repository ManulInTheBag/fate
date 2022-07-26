angra_mainyu_demon_incarnate_passive = class({})

LinkLuaModifier("modifier_demon_incarnate", "abilities/angra_mainyu/modifiers/modifier_demon_incarnate", LUA_MODIFIER_MOTION_NONE)

function angra_mainyu_demon_incarnate_passive:GetIntrinsicModifierName()
	return "modifier_demon_incarnate"
end