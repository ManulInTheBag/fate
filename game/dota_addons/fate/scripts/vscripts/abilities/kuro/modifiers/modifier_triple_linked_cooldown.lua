modifier_triple_linked_cooldown = class({})

function modifier_triple_linked_cooldown:IsHidden()
	return false 
end

function modifier_triple_linked_cooldown:RemoveOnDeath()
	return false
end

function modifier_triple_linked_cooldown:IsDebuff()
	return true 
end

function modifier_triple_linked_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end