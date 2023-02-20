modifier_artoria_ = class({})

-- Classification --
function modifier_artoria_:IsHidden()
	return true
end

function modifier_artoria_:IsDebuff()
	return true
end

function modifier_artoria_:IsStunDebuff()
	return false
end

function modifier_artoria_:IsPurgable()
	return true
end

function modifier_artoria_:RemoveOnDeath()
    return true
end

function modifier_artoria_:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

-- Modifier Effects --
function modifier_artoria_:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_artoria_:GetModifierMoveSpeedBonus_Percentage()
	return -40
end