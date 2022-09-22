modifier_shadow_strike_upgrade = class({})

function modifier_shadow_strike_upgrade:IsHidden()
	return true 
end

function modifier_shadow_strike_upgrade:IsHidden()
	return true
end

function modifier_shadow_strike_upgrade:IsPermanent()
	return true
end

function modifier_shadow_strike_upgrade:RemoveOnDeath()
	return false
end

function modifier_shadow_strike_upgrade:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end