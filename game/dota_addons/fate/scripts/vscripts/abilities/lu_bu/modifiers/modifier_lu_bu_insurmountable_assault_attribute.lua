modifier_lu_bu_insurmountable_assault_attribute = class({})

function modifier_lu_bu_insurmountable_assault_attribute:IsHidden()
	return true
end

function modifier_lu_bu_insurmountable_assault_attribute:IsPermanent()
	return true
end

function modifier_lu_bu_insurmountable_assault_attribute:RemoveOnDeath()
	return false
end

function modifier_lu_bu_insurmountable_assault_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end