modifier_kuro_projection = class({})

function modifier_kuro_projection:IsHidden() 
	return true 
end

function modifier_kuro_projection:IsPermanent()
	return true
end

function modifier_kuro_projection:RemoveOnDeath()
	return false
end

function modifier_kuro_projection:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end