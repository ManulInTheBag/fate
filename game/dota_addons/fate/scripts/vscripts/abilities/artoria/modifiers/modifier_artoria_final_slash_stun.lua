modifier_artoria_final_slash_stun = class({})

function modifier_artoria_final_slash_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_artoria_final_slash_stun:RemoveOnDeath()
	return true
end

function modifier_artoria_final_slash_stun:IsHidden()
	return true
end