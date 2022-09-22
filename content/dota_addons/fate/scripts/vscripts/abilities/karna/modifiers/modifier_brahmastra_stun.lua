modifier_brahmastra_stun = class({})

function modifier_brahmastra_stun:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true }
end

function modifier_brahmastra_stun:IsHidden()
	return true 
end