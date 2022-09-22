modifier_gilgamesh_final_hour_cooldown = class({})

function modifier_gilgamesh_final_hour_cooldown:IsHidden()
	return false 
end

function modifier_gilgamesh_final_hour_cooldown:RemoveOnDeath()
	return false
end

function modifier_gilgamesh_final_hour_cooldown:IsDebuff()
	return true 
end

function modifier_gilgamesh_final_hour_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end