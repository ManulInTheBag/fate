modifier_vasavi_slow = class({})

function modifier_vasavi_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_vasavi_slow:GetModifierMoveSpeedBonus_Percentage()
	return -100
end

function modifier_vasavi_slow:IsHidden()
	return true 
end