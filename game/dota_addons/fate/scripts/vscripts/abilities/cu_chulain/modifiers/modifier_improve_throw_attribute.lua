modifier_improve_throw_attribute = class({})

function modifier_improve_throw_attribute:IsHidden()
	return true
end

function modifier_improve_throw_attribute:IsPermanent()
	return true
end

function modifier_improve_throw_attribute:RemoveOnDeath()
	return false
end

function modifier_improve_throw_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end