modifier_scathach_pinning_god_self_stun = class({})

function modifier_scathach_pinning_god_self_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_scathach_pinning_god_self_stun:RemoveOnDeath()
	return true
end

function modifier_scathach_pinning_god_self_stun:IsHidden()
	return true
end