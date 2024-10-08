-----------------------------
--    Modifier: Mysterious Substance Debuff    --
-----------------------------

modifier_robin_tools_mysterious_substance_debuff = class({})

-- Classification --
function modifier_robin_tools_mysterious_substance_debuff:IsHidden()
	return true
end

function modifier_robin_tools_mysterious_substance_debuff:IsDebuff()
	return true
end

function modifier_robin_tools_mysterious_substance_debuff:IsStunDebuff()
	return false
end

function modifier_robin_tools_mysterious_substance_debuff:IsPurgable()
	return true
end

function modifier_robin_tools_mysterious_substance_debuff:CheckState()
	return { [MODIFIER_STATE_MUTED] = true}
end