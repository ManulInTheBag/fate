modifier_enkidu_false_soul_attribute = class({})

function modifier_enkidu_false_soul_attribute:IsHidden()
	return true
end

function modifier_enkidu_false_soul_attribute:IsPermanent()
	return true
end

function modifier_enkidu_false_soul_attribute:RemoveOnDeath()
	return false
end

function modifier_enkidu_false_soul_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end