modifier_tamamo_combo_cooldown = class({})

function modifier_tamamo_combo_cooldown:IsHidden()
	return false 
end

function modifier_tamamo_combo_cooldown:RemoveOnDeath()
	return false
end

function modifier_tamamo_combo_cooldown:IsDebuff()
	return true 
end

function modifier_tamamo_combo_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end