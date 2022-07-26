modifier_projection_attribute = class({})

function modifier_projection_attribute:IsHidden() 
	return true 
end

function modifier_projection_attribute:IsPermanent()
	return true
end

function modifier_projection_attribute:RemoveOnDeath()
	return false
end

function modifier_projection_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_projection_attribute:DeclareFunctions()
	local func = {MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE}
	return func
end

--function modifier_projection_attribute:GetModifierPercentageCooldown()
--	return 35
--end