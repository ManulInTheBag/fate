modifier_lu_bu_sky_piercer_stun = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_sky_piercer_stun:IsDebuff()
	return true
end

function modifier_lu_bu_sky_piercer_stun:IsStunDebuff()
	return true
end

function modifier_lu_bu_sky_piercer_stun:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_lu_bu_sky_piercer_stun:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end
