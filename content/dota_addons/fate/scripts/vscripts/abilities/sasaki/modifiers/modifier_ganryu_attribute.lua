modifier_ganryu_attribute = class({})

function modifier_ganryu_attribute:IsHidden() 
	return true 
end

function modifier_ganryu_attribute:IsPermanent()
	return true
end

function modifier_ganryu_attribute:RemoveOnDeath()
	return false
end

function modifier_ganryu_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end