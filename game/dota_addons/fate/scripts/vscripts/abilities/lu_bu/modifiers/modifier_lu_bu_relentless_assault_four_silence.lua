modifier_lu_bu_relentless_assault_four_silence = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_four_silence:IsDebuff()
	return true
end

function modifier_lu_bu_relentless_assault_four_silence:CheckState()
	local state = {
		[MODIFIER_STATE_SILENCED] = true
	}

	return state
end

function modifier_lu_bu_relentless_assault_four_silence:IsHidden()
	return true
end