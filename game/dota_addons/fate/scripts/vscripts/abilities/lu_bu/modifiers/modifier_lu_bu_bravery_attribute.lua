modifier_lu_bu_bravery_attribute = class({})

function modifier_lu_bu_bravery_attribute:IsHidden()
	return true
end

function modifier_lu_bu_bravery_attribute:IsPermanent()
	return true
end

function modifier_lu_bu_bravery_attribute:RemoveOnDeath()
	return false
end

function modifier_lu_bu_bravery_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end