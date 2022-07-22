modifier_discern_poor_extra = class({})

function modifier_discern_poor_extra:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_PROVIDES_VISION] = true }
end


function modifier_discern_poor_extra:RemoveOnDeath()
	return true 
end

function modifier_discern_poor_extra:IsDebuff()
	return true
end