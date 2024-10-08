-----------------------------
--    Modifier: Tools Attribute    --
-----------------------------

modifier_robin_tools_attribute = class({})

function modifier_robin_tools_attribute:IsHidden()
	return true
end

function modifier_robin_tools_attribute:IsPermanent()
	return true
end

function modifier_robin_tools_attribute:RemoveOnDeath()
	return false
end

function modifier_robin_tools_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end