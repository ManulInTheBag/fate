modifier_scathach_slow = class({})

-- Classification --
function modifier_scathach_slow:IsHidden()
	return true
end

function modifier_scathach_slow:IsDebuff()
	return true
end

function modifier_scathach_slow:IsStunDebuff()
	return false
end

function modifier_scathach_slow:IsPurgable()
	return true
end

-- Modifier Effects --
function modifier_scathach_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_scathach_slow:GetModifierMoveSpeedBonus_Percentage()
	return -40
end