-----------------------------
--    Modifier: Ultimate Excalibur Beam Placeholder    --
-----------------------------

modifier_artoria_ultimate_excalibur_beam = class({})

function modifier_artoria_ultimate_excalibur_beam:IsHidden()
	return true
end

function modifier_artoria_ultimate_excalibur_beam:IsPermanent()
	return false
end

function modifier_artoria_ultimate_excalibur_beam:RemoveOnDeath()
	return true
end

function modifier_artoria_ultimate_excalibur_beam:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end