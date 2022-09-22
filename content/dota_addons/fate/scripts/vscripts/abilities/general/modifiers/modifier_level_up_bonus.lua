modifier_level_up_bonus = class({})

function modifier_level_up_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_BONUS }
end

function modifier_level_up_bonus:GetModifierHealthBonus()
	return (self:GetParent():GetLevel() - 1) * self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_level_up_bonus:IsHidden()
	return true 
end