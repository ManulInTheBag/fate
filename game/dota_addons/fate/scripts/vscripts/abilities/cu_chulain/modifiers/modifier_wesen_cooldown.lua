modifier_wesen_cooldown = class({})

function modifier_wesen_cooldown:IsHidden()
	return false 
end

function modifier_wesen_cooldown:RemoveOnDeath()
	return false
end

function modifier_wesen_cooldown:IsDebuff()
	return true 
end

function modifier_wesen_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end