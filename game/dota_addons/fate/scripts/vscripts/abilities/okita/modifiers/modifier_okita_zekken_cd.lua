modifier_okita_zekken_cd = class({})

function modifier_okita_zekken_cd:GetTexture()
	return "custom/okita/okita_combo_zekken"
end

function modifier_okita_zekken_cd:IsHidden()
	return false 
end

function modifier_okita_zekken_cd:RemoveOnDeath()
	return false
end

function modifier_okita_zekken_cd:IsDebuff()
	return true 
end

function modifier_okita_zekken_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end