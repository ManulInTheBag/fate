jtr_holy_mother_passive = ({})

LinkLuaModifier("modifier_holy_mother", "abilities/jtr/modifiers/modifier_holy_mother", LUA_MODIFIER_MOTION_NONE)

function jtr_holy_mother_passive:GetIntrinsicModifierName()
	return "modifier_holy_mother"
end
