modifier_quickdraw_cooldown = class({})

function modifier_quickdraw_cooldown:IsHidden()
	return false 
end

function modifier_quickdraw_cooldown:RemoveOnDeath()
	return false
end

function modifier_quickdraw_cooldown:IsDebuff()
	return true 
end

function modifier_quickdraw_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end