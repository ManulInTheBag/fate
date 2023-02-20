modifier_artoria_strike_air_attribute = class({})

function modifier_artoria_strike_air_attribute:IsHidden()
	return true
end

function modifier_artoria_strike_air_attribute:IsPermanent()
	return true
end

function modifier_artoria_strike_air_attribute:RemoveOnDeath()
	return false
end

function modifier_artoria_strike_air_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end