modifier_whitechapel_cooldown = class({})

function modifier_whitechapel_cooldown:IsHidden()
	return false 
end

function modifier_whitechapel_cooldown:RemoveOnDeath()
	return false
end

function modifier_whitechapel_cooldown:IsDebuff()
	return true 
end

function modifier_whitechapel_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end