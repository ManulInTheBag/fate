modifier_lu_bu_fangtian_huaji_attribute = class({})

function modifier_lu_bu_fangtian_huaji_attribute:IsHidden()
	return true
end

function modifier_lu_bu_fangtian_huaji_attribute:IsPermanent()
	return true
end

function modifier_lu_bu_fangtian_huaji_attribute:RemoveOnDeath()
	return false
end

function modifier_lu_bu_fangtian_huaji_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end