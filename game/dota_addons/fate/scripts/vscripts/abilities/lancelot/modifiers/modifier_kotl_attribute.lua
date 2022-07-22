modifier_kotl_attribute = class({})

function modifier_kotl_attribute:IsHidden()
	return true
end

function modifier_kotl_attribute:IsPermanent()
	return true
end

function modifier_kotl_attribute:RemoveOnDeath()
	return false
end

function modifier_kotl_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end