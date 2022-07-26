modifier_rampant_warrior_cooldown = class({})

function modifier_rampant_warrior_cooldown:IsHidden()
	return false 
end

function modifier_rampant_warrior_cooldown:RemoveOnDeath()
	return false
end

function modifier_rampant_warrior_cooldown:IsDebuff()
	return true 
end

function modifier_rampant_warrior_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rampant_warrior_cooldown:GetTexture()
	return "custom/diarmuid_rampant_warrior"
end