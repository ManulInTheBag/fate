modifier_gordius_wheel_temp_bandaid = class({})

function modifier_gordius_wheel_temp_bandaid:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_MAX,
			 MODIFIER_PROPERTY_MOVESPEED_LIMIT,
			 MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE, }
end

function modifier_gordius_wheel_temp_bandaid:GetModifierMoveSpeed_Limit()
	return 5000
end

function modifier_gordius_wheel_temp_bandaid:GetModifierMoveSpeed_Max()
	return 5000
end

function modifier_gordius_wheel_temp_bandaid:GetModifierTurnRate_Percentage()
	return -350
end

function modifier_gordius_wheel_temp_bandaid:CheckState()
	return { [MODIFIER_STATE_ROOTED] = false,
			 [MODIFIER_STATE_STUNNED] = false }
end
