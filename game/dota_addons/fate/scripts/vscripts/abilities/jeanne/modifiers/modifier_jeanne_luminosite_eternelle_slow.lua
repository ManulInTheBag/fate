-----------------------------
--    Modifier: Slow    --
-----------------------------

modifier_jeanne_luminosite_eternelle_slow = class({})

-- Classification --
function modifier_jeanne_luminosite_eternelle_slow:OnCreated( kv )
end

function modifier_jeanne_luminosite_eternelle_slow:IsHidden()
	return false
end

function modifier_jeanne_luminosite_eternelle_slow:IsDebuff()
	return true
end

function modifier_jeanne_luminosite_eternelle_slow:IsStunDebuff()
	return false
end

function modifier_jeanne_luminosite_eternelle_slow:IsPurgable()
	return true
end

function modifier_jeanne_luminosite_eternelle_slow:RemoveOnDeath()
    return true
end

-- Modifier Effects --
function modifier_jeanne_luminosite_eternelle_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_jeanne_luminosite_eternelle_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end