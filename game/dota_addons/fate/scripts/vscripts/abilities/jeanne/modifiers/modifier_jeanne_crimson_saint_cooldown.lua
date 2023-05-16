modifier_jeanne_crimson_saint_cooldown = class({})

function modifier_jeanne_crimson_saint_cooldown:IsHidden()
	return false 
end

function modifier_jeanne_crimson_saint_cooldown:RemoveOnDeath()
	return false
end

function modifier_jeanne_crimson_saint_cooldown:IsDebuff()
	return true 
end

function modifier_jeanne_crimson_saint_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end