modifier_eternal_flame_attribute = class({})

function modifier_eternal_flame_attribute:IsHidden()
	return true
end

function modifier_eternal_flame_attribute:IsPermanent()
	return true
end

function modifier_eternal_flame_attribute:RemoveOnDeath()
	return false
end

function modifier_eternal_flame_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end