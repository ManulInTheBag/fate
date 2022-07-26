modifier_tawrich_crit = class({})

function modifier_tawrich_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_tawrich_crit:GetModifierPreAttack_CriticalStrike()
	return self:GetAbility():GetSpecialValueFor("crit_dmg")
end

function modifier_tawrich_crit:IsHidden()
	return true 
end

function modifier_tawrich_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end