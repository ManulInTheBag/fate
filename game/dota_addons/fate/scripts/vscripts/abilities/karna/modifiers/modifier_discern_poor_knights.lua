modifier_discern_poor_knights = class({})

function modifier_discern_poor_knights:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_PROVIDES_VISION] = true }
end


function modifier_discern_poor_knights:RemoveOnDeath()
	return true 
end

function modifier_discern_poor_knights:IsDebuff()
	return true
end