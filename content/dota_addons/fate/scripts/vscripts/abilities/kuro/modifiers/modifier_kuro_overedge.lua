modifier_kuro_overedge = class({})

function modifier_kuro_overedge:IsHidden() 
	return true 
end

function modifier_kuro_overedge:IsPermanent()
	return true
end

function modifier_kuro_overedge:RemoveOnDeath()
	return false
end

function modifier_kuro_overedge:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end