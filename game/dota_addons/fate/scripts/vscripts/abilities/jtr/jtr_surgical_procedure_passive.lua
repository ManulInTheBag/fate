jtr_surgical_procedure_passive = class({})

LinkLuaModifier("modifier_surgical_procedure", "abilities/jtr/modifiers/modifier_surgical_procedure", LUA_MODIFIER_MOTION_NONE)

function jtr_surgical_procedure_passive:GetIntrinsicModifierName()
	return "modifier_surgical_procedure"
end