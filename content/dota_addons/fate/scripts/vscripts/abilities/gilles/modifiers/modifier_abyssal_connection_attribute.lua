modifier_abyssal_connection_attribute = class({})

function modifier_abyssal_connection_attribute:IsHidden()
	return true
end

function modifier_abyssal_connection_attribute:IsPermanent()
	return true
end

function modifier_abyssal_connection_attribute:RemoveOnDeath()
	return false
end

function modifier_abyssal_connection_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end