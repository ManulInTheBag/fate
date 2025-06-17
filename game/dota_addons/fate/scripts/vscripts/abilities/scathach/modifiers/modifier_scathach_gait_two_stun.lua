modifier_scathach_gait_two_stun = class({})

function modifier_scathach_gait_two_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_scathach_gait_two_stun:RemoveOnDeath()
	return true
end

function modifier_scathach_gait_two_stun:IsHidden()
	return true
end