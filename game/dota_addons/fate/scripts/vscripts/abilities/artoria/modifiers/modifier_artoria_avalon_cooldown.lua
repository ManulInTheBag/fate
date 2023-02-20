-----------------------------
--    Modifier: Avalon Cooldown    --
-----------------------------

modifier_artoria_avalon_cooldown = class({})

function modifier_artoria_avalon_cooldown:IsHidden()
	return true 
end

function modifier_artoria_avalon_cooldown:RemoveOnDeath()
	return false
end

function modifier_artoria_avalon_cooldown:IsDebuff()
	return true 
end

function modifier_artoria_avalon_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artoria_avalon_cooldown:GetTexture()
    return "custom/artoria/artoria_avalon"
end