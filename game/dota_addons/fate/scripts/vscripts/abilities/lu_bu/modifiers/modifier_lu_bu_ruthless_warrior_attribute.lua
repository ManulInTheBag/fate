modifier_lu_bu_ruthless_warrior_attribute = class({})

function modifier_lu_bu_ruthless_warrior_attribute:IsHidden()
	return true
end

function modifier_lu_bu_ruthless_warrior_attribute:IsPermanent()
	return true
end

function modifier_lu_bu_ruthless_warrior_attribute:RemoveOnDeath()
	return false
end

function modifier_lu_bu_ruthless_warrior_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end