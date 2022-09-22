medusa_riding_passive = class({})

LinkLuaModifier("modifier_medusa_riding_passive", "abilities/medusa/modifiers/modifier_medusa_riding_passive", LUA_MODIFIER_MOTION_NONE)

function medusa_riding_passive:GetIntrinsicModifierName()
	return "modifier_medusa_riding_passive"
end