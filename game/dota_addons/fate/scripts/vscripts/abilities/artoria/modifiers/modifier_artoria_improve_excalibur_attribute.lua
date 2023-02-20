modifier_artoria_improve_excalibur_attribute = class({})

function modifier_artoria_improve_excalibur_attribute:IsHidden()
	return true
end

function modifier_artoria_improve_excalibur_attribute:IsPermanent()
	return true
end

function modifier_artoria_improve_excalibur_attribute:RemoveOnDeath()
	return false
end

function modifier_artoria_improve_excalibur_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end