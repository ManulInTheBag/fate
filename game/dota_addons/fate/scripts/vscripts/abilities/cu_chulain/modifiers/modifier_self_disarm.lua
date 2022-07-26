modifier_self_disarm = class({})

function modifier_self_disarm:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true }
end

function modifier_self_disarm:IsHidden()
	return true
end

function modifier_self_disarm:RemoveOnDeath()
	return true
end

function modifier_self_disarm:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end