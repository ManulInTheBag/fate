modifier_jeanne_vision = class({})

-- Vision provider buff
function modifier_jeanne_vision:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_jeanne_vision:GetModifierProvidesFOWVision()
	return 1
end

function modifier_jeanne_vision:IsHidden()
	return false
end

function modifier_jeanne_vision:IsDebuff()
    return true
end

function modifier_jeanne_vision:RemoveOnDeath()
    return true
end

function modifier_jeanne_vision:GetTexture()
	return "custom/jeanne_identity_discernment"
end