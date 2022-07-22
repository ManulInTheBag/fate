modifier_kuro_projection_overpower = class({})

function modifier_kuro_projection_overpower:IsHidden() 
	return true 
end

function modifier_kuro_projection_overpower:IsPermanent()
	return true
end

function modifier_kuro_projection_overpower:RemoveOnDeath()
	return false
end

function modifier_kuro_projection_overpower:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end