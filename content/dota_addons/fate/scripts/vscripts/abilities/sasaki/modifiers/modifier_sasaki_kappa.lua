modifier_sasaki_kappa = class({})

function modifier_sasaki_kappa:IsHidden()
	return false
end

function modifier_sasaki_kappa:IsDebuff()
	return false
end

function modifier_sasaki_kappa:RemoveOnDeath()
	return true
end

function modifier_sasaki_kappa:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sasaki_kappa:GetTexture()
	return "custom/false_assassin_minds_eye"
end