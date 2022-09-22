modifier_arrow_rain_cooldown = class({})

function modifier_arrow_rain_cooldown:IsHidden()
	return false 
end

function modifier_arrow_rain_cooldown:RemoveOnDeath()
	return false
end

function modifier_arrow_rain_cooldown:IsDebuff()
	return true 
end

function modifier_arrow_rain_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end