modifier_eagle_eye = class({})

function modifier_eagle_eye:IsHidden() 
	return true 
end

function modifier_eagle_eye:IsPermanent()
	return true
end

function modifier_eagle_eye:RemoveOnDeath()
	return false
end

function modifier_eagle_eye:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end