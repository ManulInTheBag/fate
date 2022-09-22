modifier_golden_rose_attribute = class({})

function modifier_golden_rose_attribute:IsHidden()
	return true
end

function modifier_golden_rose_attribute:IsPermanent()
	return true
end

function modifier_golden_rose_attribute:RemoveOnDeath()
	return false
end

function modifier_golden_rose_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end