modifier_jeanne_crimson_saint_stun = class({})

function modifier_jeanne_crimson_saint_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_jeanne_crimson_saint_stun:RemoveOnDeath()
	return true
end

function modifier_jeanne_crimson_saint_stun:IsHidden()
	return true
end