-----------------------------
--    Modifier: Yew Bow Attribute    --
-----------------------------

modifier_robin_yew_bow_attribute = class({})

function modifier_robin_yew_bow_attribute:IsHidden()
	return true
end

function modifier_robin_yew_bow_attribute:IsPermanent()
	return true
end

function modifier_robin_yew_bow_attribute:RemoveOnDeath()
	return false
end

function modifier_robin_yew_bow_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end