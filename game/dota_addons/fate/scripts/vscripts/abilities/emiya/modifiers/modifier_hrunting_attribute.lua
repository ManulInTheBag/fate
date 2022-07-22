modifier_hrunting_attribute = class({})

function modifier_hrunting_attribute:IsHidden()
	return true
end

function modifier_hrunting_attribute:IsPermanent()
	return true
end

function modifier_hrunting_attribute:RemoveOnDeath()
	return false
end

function modifier_hrunting_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end