modifier_lu_bu_god_force_mute = class({})

function modifier_lu_bu_god_force_mute:CheckState()
	return { [MODIFIER_STATE_MUTED] = true }
end

function modifier_lu_bu_god_force_mute:IsHidden()
	return true
end
