modifier_eam_crit_active = class({})

function modifier_eam_crit_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_eam_crit_active:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_eam_crit_active:IsHidden()
	return true 
end

function modifier_eam_crit_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end