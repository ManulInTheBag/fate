modifier_lu_bu_armistice_stun = class({})

function modifier_lu_bu_armistice_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false
	}

	return state
end

function modifier_lu_bu_armistice_stun:RemoveOnDeath()
	return true
end

function modifier_lu_bu_armistice_stun:IsHidden()
	return true
end