modifier_shaytan_arm_attribute = class({})

function modifier_shaytan_arm_attribute:IsHidden()
	return true
end

function modifier_shaytan_arm_attribute:IsPermanent()
	return true
end

function modifier_shaytan_arm_attribute:RemoveOnDeath()
	return false
end

function modifier_shaytan_arm_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end