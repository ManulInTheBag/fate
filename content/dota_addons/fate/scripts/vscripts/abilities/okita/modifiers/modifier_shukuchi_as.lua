modifier_shukuchi_as = class({})

function modifier_shukuchi_as:IsDebuff() return false end

function modifier_shukuchi_as:IsHidden() return false end

function modifier_shukuchi_as:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,}
end

function modifier_shukuchi_as:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("as_bonus")
end

modifier_shukuchi_crit = class({})

function modifier_shukuchi_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_shukuchi_crit:GetModifierPreAttack_CriticalStrike()
	return self:GetAbility():GetSpecialValueFor("critical")
end