-----------------------------
--    Modifier: Independent Action Attribute    --
-----------------------------

modifier_robin_independent_action_attribute = class({})

function modifier_robin_independent_action_attribute:IsHidden()
	return true
end

function modifier_robin_independent_action_attribute:IsPermanent()
	return true
end

function modifier_robin_independent_action_attribute:RemoveOnDeath()
	return false
end

function modifier_robin_independent_action_attribute:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_BONUS }
end

function modifier_robin_independent_action_attribute:GetModifierManaBonus()
	return 300
end

function modifier_robin_independent_action_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end