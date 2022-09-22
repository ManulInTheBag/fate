modifier_kuro_eagle_eye = class({})

function modifier_kuro_eagle_eye:IsHidden() 
	return true 
end

function modifier_kuro_eagle_eye:IsPermanent()
	return true
end

function modifier_kuro_eagle_eye:RemoveOnDeath()
	return false
end

function modifier_kuro_eagle_eye:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end