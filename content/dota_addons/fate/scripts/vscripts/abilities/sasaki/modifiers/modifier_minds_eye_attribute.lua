modifier_minds_eye_attribute = class({})

function modifier_minds_eye_attribute:IsHidden()
	return true
end

function modifier_minds_eye_attribute:IsPermanent()
	return true
end

function modifier_minds_eye_attribute:RemoveOnDeath()
	return false
end

function modifier_minds_eye_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end