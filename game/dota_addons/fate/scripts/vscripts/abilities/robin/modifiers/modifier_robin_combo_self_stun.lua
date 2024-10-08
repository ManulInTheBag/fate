modifier_robin_combo_self_stun = class({})

function modifier_robin_combo_self_stun:CheckState()
	local state = {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}

	return state
end

function modifier_robin_combo_self_stun:RemoveOnDeath()
	return true
end

function modifier_robin_combo_self_stun:IsHidden()
	return true
end