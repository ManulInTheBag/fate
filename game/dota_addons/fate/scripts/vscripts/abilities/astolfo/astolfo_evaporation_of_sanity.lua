astolfo_evaporation_of_sanity = class({})

LinkLuaModifier("modifier_evaporation_sanity", "abilities/astolfo/modifiers/modifier_evaporation_sanity", LUA_MODIFIER_MOTION_NONE)

function astolfo_evaporation_of_sanity:GetIntrinsicModifierName()
	return "modifier_evaporation_sanity"
end