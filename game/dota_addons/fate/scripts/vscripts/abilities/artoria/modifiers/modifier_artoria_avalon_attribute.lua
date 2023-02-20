modifier_artoria_avalon_attribute = class({})

function modifier_artoria_avalon_attribute:IsHidden()
	return true
end

function modifier_artoria_avalon_attribute:IsPermanent()
	return true
end

function modifier_artoria_avalon_attribute:RemoveOnDeath()
	return false
end

function modifier_artoria_avalon_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end