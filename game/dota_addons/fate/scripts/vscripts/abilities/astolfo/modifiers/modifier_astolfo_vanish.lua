modifier_astolfo_vanish = class({})

function modifier_astolfo_vanish:CheckState()
	return { [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR] = true,
			 [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_astolfo_vanish:IsHidden()
	return true
end