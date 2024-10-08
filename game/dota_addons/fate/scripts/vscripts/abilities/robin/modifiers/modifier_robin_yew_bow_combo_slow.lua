modifier_robin_yew_bow_combo_slow = class({})

function modifier_robin_yew_bow_combo_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_robin_yew_bow_combo_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

function modifier_robin_yew_bow_combo_slow:IsHidden()
	return true 
end
