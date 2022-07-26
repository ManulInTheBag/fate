modifier_overedge_attribute = class({})

function modifier_overedge_attribute:IsHidden()
	return true
end

function modifier_overedge_attribute:IsPermanent()
	return true
end

function modifier_overedge_attribute:RemoveOnDeath()
	return false
end

function modifier_overedge_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end