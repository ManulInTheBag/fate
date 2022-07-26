nero_aestus_estus_passive = class({})

LinkLuaModifier("modifier_aestus_estus", "abilities/nero/modifiers/modifier_aestus_estus", LUA_MODIFIER_MOTION_NONE)

function nero_aestus_estus_passive:GetIntrinsicModifierName()
	return "modifier_aestus_estus"
end