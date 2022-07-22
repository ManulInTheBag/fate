modifier_la_pucelle_cooldown = class({})

function modifier_la_pucelle_cooldown:IsHidden()
	return false 
end

function modifier_la_pucelle_cooldown:RemoveOnDeath()
	return false
end

function modifier_la_pucelle_cooldown:IsDebuff()
	return true 
end

function modifier_la_pucelle_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end