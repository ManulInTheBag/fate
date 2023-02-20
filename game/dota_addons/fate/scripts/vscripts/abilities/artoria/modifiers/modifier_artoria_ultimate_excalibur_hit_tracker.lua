-----------------------------
--    Modifier: Ultimate Excalibur Hit Tracker    --
-----------------------------

modifier_artoria_ultimate_excalibur_hit_tracker = class({})

function modifier_artoria_ultimate_excalibur_hit_tracker:IsHidden()
	return true
end

function modifier_artoria_ultimate_excalibur_hit_tracker:IsPermanent()
	return false
end

function modifier_artoria_ultimate_excalibur_hit_tracker:RemoveOnDeath()
	return true
end

function modifier_artoria_ultimate_excalibur_hit_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end