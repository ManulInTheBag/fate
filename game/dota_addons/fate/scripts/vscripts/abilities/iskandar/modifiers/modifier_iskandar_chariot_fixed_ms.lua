modifier_iskandar_chariot_fixed_ms = class({})

function modifier_iskandar_chariot_fixed_ms:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE }
end

function modifier_iskandar_chariot_fixed_ms:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor("fixed_ms")
end

function modifier_iskandar_chariot_fixed_ms:IsHidden()
	return true
end