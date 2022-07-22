modifier_overdrive_attribute = class({})

function modifier_overdrive_attribute:IsHidden()
	return true
end

function modifier_overdrive_attribute:IsPermanent()
	return true
end

function modifier_overdrive_attribute:RemoveOnDeath()
	return false
end

function modifier_overdrive_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end