astolfo_monstrous_strength_passive = class({})

LinkLuaModifier("modifier_monstrous_strengh_damage_bonus", "abilities/astolfo/modifiers/modifier_monstrous_strengh_damage_bonus", LUA_MODIFIER_MOTION_NONE)

function astolfo_monstrous_strength_passive:GetIntrinsicModifierName()
	return "modifier_monstrous_strengh_damage_bonus"
end