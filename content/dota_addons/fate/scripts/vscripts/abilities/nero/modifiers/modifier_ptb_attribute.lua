modifier_ptb_attribute = class({})

function modifier_ptb_attribute:IsHidden()
	return true
end

function modifier_ptb_attribute:IsPermanent()
	return true
end

function modifier_ptb_attribute:RemoveOnDeath()
	return false
end

function modifier_ptb_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end