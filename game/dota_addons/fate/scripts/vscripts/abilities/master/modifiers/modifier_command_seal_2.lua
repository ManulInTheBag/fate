modifier_command_seal_2 = class({})

function modifier_command_seal_2:IsHidden()
	return false 
end

function modifier_command_seal_2:RemoveOnDeath()
	return false
end

function modifier_command_seal_2:IsDebuff()
	return true 
end

function modifier_command_seal_2:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end