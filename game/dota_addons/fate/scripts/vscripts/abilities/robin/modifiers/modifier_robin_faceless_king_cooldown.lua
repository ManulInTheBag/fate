-----------------------------
--    Modifier: Faceless King Cooldown    --
-----------------------------

modifier_robin_faceless_king_cooldown = class({})

function modifier_robin_faceless_king_cooldown:IsHidden()
	return false 
end

function modifier_robin_faceless_king_cooldown:RemoveOnDeath()
	return false
end

function modifier_robin_faceless_king_cooldown:IsDebuff()
	return true 
end

function modifier_robin_faceless_king_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end