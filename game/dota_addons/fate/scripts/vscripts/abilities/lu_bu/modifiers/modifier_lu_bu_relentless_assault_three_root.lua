modifier_lu_bu_relentless_assault_three_root = class({})

--------------------------------------------------------------------------------

function modifier_lu_bu_relentless_assault_three_root:IsDebuff()
	return true
end

function modifier_lu_bu_relentless_assault_three_root:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true
	}

	return state
end

function modifier_lu_bu_relentless_assault_three_root:IsHidden()
	return true
end