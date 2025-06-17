modifier_scathach_red_wind_stun = class({})

function modifier_scathach_red_wind_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_scathach_red_wind_stun:RemoveOnDeath()
	return true
end

function modifier_scathach_red_wind_stun:IsHidden()
	return true
end