modifier_galatine_combo_cd = class({})

function modifier_galatine_combo_cd:GetTexture()
	return "custom/gawain_galatine_combo"
end

function modifier_galatine_combo_cd:IsHidden()
	return false 
end

function modifier_galatine_combo_cd:RemoveOnDeath()
	return false
end

function modifier_galatine_combo_cd:IsDebuff()
	return true 
end

function modifier_galatine_combo_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end