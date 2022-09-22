modifier_polygamist_cooldown = class({})

function modifier_polygamist_cooldown:IsHidden()
	return false 
end

function modifier_polygamist_cooldown:RemoveOnDeath()
	return false
end

function modifier_polygamist_cooldown:IsDebuff()
	return true 
end

function modifier_polygamist_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end