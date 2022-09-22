modifier_f16_cd = class({})

function modifier_f16_cd:GetTexture()
	return "custom/lancelot/lancelot_f16"
end

function modifier_f16_cd:IsHidden()
	return false 
end

function modifier_f16_cd:RemoveOnDeath()
	return false
end

function modifier_f16_cd:IsDebuff()
	return true 
end

function modifier_f16_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end