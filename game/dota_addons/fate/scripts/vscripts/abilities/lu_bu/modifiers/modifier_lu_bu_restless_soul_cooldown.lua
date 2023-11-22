modifier_lu_bu_restless_soul_cooldown = class({})

function modifier_lu_bu_restless_soul_cooldown:IsHidden()
	return false 
end

function modifier_lu_bu_restless_soul_cooldown:RemoveOnDeath()
	return false
end

function modifier_lu_bu_restless_soul_cooldown:IsDebuff()
	return true 
end

function modifier_lu_bu_restless_soul_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_lu_bu_restless_soul_cooldown:GetTexture()
    return "custom/lu_bu/lu_bu_insurmountable_assault_attribute"
end