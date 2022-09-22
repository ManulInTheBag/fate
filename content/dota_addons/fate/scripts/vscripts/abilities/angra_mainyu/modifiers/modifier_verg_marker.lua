modifier_verg_marker = class({})

function modifier_verg_marker:IsHidden()
	return false 
end

function modifier_verg_marker:RemoveOnDeath()
	return true
end

function modifier_verg_marker:IsDebuff()
	return true
end

function modifier_verg_marker:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end