modifier_celtic_rune_attribute = class({})

function modifier_celtic_rune_attribute:IsHidden()
	return true
end

function modifier_celtic_rune_attribute:IsPermanent()
	return true
end

function modifier_celtic_rune_attribute:RemoveOnDeath()
	return false
end

function modifier_celtic_rune_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end