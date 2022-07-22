modifier_whitechapel_murderer_crit = class({})

function modifier_whitechapel_murderer_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_whitechapel_murderer_crit:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_whitechapel_murderer_crit:IsHidden()
	return true 
end

function modifier_whitechapel_murderer_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end