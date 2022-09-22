hero_base_stats_bonus = class({})

LinkLuaModifier("modifier_level_up_bonus", "abilities/general/modifiers/modifier_level_up_bonus", LUA_MODIFIER_MOTION_NONE)

function hero_base_stats_bonus:GetIntrinsicModifierName()
	return "modifier_level_up_bonus"
end