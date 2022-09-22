modifier_alice_tea_party_cd = class({})

function modifier_alice_tea_party_cd:GetTexture()
	return "custom/alice/alice_tea_party"
end

function modifier_alice_tea_party_cd:IsHidden()
	return false 
end

function modifier_alice_tea_party_cd:RemoveOnDeath()
	return false
end

function modifier_alice_tea_party_cd:IsDebuff()
	return true 
end

function modifier_alice_tea_party_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end