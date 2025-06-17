modifier_scathach_branches_of_tonelico_attribute = class({})

function modifier_scathach_branches_of_tonelico_attribute:IsHidden()
	return true
end

function modifier_scathach_branches_of_tonelico_attribute:IsPermanent()
	return true
end

function modifier_scathach_branches_of_tonelico_attribute:RemoveOnDeath()
	return false
end

function modifier_scathach_branches_of_tonelico_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end