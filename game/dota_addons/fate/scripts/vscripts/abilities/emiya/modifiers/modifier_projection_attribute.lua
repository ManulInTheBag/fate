modifier_projection_attribute = class({})

function modifier_projection_attribute:IsHidden() 
	return true 
end

function modifier_projection_attribute:IsPermanent()
	return true
end

function modifier_projection_attribute:RemoveOnDeath()
	return false
end

function modifier_projection_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end