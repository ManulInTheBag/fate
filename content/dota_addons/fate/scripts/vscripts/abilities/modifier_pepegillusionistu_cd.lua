modifier_pepegillusionist_cd = class({})

function modifier_pepegillusionist_cd:IsHidden()
	return false 
end

function modifier_pepegillusionist_cd:RemoveOnDeath()
	return false
end

function modifier_pepegillusionist_cd:IsDebuff()
	return true 
end

function modifier_pepegillusionist_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end