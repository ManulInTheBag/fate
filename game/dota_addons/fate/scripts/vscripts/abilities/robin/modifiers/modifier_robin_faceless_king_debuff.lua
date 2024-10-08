-----------------------------
--    Modifier: Faceless King Debuff    --
-----------------------------

modifier_robin_faceless_king_debuff = class({})

-- Classification --
function modifier_robin_faceless_king_debuff:IsHidden()
	return true
end

function modifier_robin_faceless_king_debuff:IsDebuff()
	return true
end

function modifier_robin_faceless_king_debuff:IsStunDebuff()
	return false
end

function modifier_robin_faceless_king_debuff:IsPurgable()
	return true
end

function modifier_robin_faceless_king_debuff:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true,
					[MODIFIER_STATE_MUTED] = true,
					[MODIFIER_STATE_DISARMED] = true}
end