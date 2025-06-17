modifier_scathach_combo_2_cooldown = class({})

function modifier_scathach_combo_2_cooldown:IsHidden()
	return false 
end

function modifier_scathach_combo_2_cooldown:RemoveOnDeath()
	return false
end

function modifier_scathach_combo_2_cooldown:IsDebuff()
	return true 
end

function modifier_scathach_combo_2_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end