modifier_lu_bu_halberd_throw_self_stun = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_halberd_throw_self_stun:IsDebuff()
	return true
end

function modifier_lu_bu_halberd_throw_self_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	}

	return state
end

function modifier_lu_bu_halberd_throw_self_stun:IsHidden()
	return true
end