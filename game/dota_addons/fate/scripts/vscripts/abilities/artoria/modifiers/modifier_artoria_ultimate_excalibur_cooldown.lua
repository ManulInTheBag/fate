-----------------------------
--    Modifier: Ultimate Excalibur Cooldown    --
-----------------------------

modifier_artoria_ultimate_excalibur_cooldown = class({})

function modifier_artoria_ultimate_excalibur_cooldown:IsHidden()
	return false 
end

function modifier_artoria_ultimate_excalibur_cooldown:RemoveOnDeath()
	return false
end

function modifier_artoria_ultimate_excalibur_cooldown:IsDebuff()
	return true 
end

function modifier_artoria_ultimate_excalibur_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end