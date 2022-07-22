modifier_battle_cont_cooldown = class({})

function modifier_battle_cont_cooldown:IsHidden()
	return false 
end

function modifier_battle_cont_cooldown:RemoveOnDeath()
	return false
end

function modifier_battle_cont_cooldown:IsDebuff()
	return true 
end

function modifier_battle_cont_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end