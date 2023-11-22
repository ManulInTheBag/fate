-----------------------------
--    Modifier: Sky Piercer Cooldown    --
-----------------------------

modifier_lu_bu_sky_piercer_cooldown = class({})

function modifier_lu_bu_sky_piercer_cooldown:IsHidden()
	return false 
end

function modifier_lu_bu_sky_piercer_cooldown:RemoveOnDeath()
	return false
end

function modifier_lu_bu_sky_piercer_cooldown:IsDebuff()
	return true 
end

function modifier_lu_bu_sky_piercer_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end