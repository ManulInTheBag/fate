modifier_laus_saint_claudius_cooldown = class({})

function modifier_laus_saint_claudius_cooldown:GetTexture()
	return "custom/nero_laus_saint"
end

function modifier_laus_saint_claudius_cooldown:IsHidden()
	return false 
end

function modifier_laus_saint_claudius_cooldown:RemoveOnDeath()
	return false
end

function modifier_laus_saint_claudius_cooldown:IsDebuff()
	return true 
end

function modifier_laus_saint_claudius_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end