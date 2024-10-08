-----------------------------
--    Modifier: Robin of Sherwood Attribute    --
-----------------------------

modifier_robin_of_sherwood_attribute = class({})

function modifier_robin_of_sherwood_attribute:IsHidden()
	return true
end

function modifier_robin_of_sherwood_attribute:IsPermanent()
	return true
end

function modifier_robin_of_sherwood_attribute:RemoveOnDeath()
	return false
end

function modifier_robin_of_sherwood_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end