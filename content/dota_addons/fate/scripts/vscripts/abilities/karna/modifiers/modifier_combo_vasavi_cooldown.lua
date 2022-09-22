modifier_combo_vasavi_cooldown = class({})

function modifier_combo_vasavi_cooldown:IsHidden()
	return false 
end

function modifier_combo_vasavi_cooldown:RemoveOnDeath()
	return false
end

function modifier_combo_vasavi_cooldown:IsDebuff()
	return true 
end

function modifier_combo_vasavi_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end