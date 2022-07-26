modifier_discern_poor_horseman = class({})

function modifier_discern_poor_horseman:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_PROVIDES_VISION] = true }
end


function modifier_discern_poor_horseman:RemoveOnDeath()
	return true 
end

function modifier_discern_poor_horseman:IsDebuff()
	return true
end