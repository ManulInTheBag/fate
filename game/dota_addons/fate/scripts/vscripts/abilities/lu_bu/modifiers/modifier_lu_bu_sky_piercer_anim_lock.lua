modifier_lu_bu_sky_piercer_anim_lock = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_sky_piercer_anim_lock:IsDebuff()
	return true
end

function modifier_lu_bu_sky_piercer_anim_lock:IsStunDebuff()
	return true
end

function modifier_lu_bu_sky_piercer_anim_lock:IsHidden()
	return false 
end

--------------------------------------------------------------------------------

function modifier_lu_bu_sky_piercer_anim_lock:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end
