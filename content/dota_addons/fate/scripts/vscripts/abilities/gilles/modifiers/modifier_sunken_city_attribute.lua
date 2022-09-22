modifier_sunken_city_attribute = class({})

function modifier_sunken_city_attribute:IsHidden()
	return true
end

function modifier_sunken_city_attribute:IsPermanent()
	return true
end

function modifier_sunken_city_attribute:RemoveOnDeath()
	return false
end

function modifier_sunken_city_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end