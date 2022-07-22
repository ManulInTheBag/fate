modifier_vision_provider = class({})

function modifier_vision_provider:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_vision_provider:GetModifierProvidesFOWVision()
    return 1
end

function modifier_vision_provider:IsHidden()
    return true
end

function modifier_vision_provider:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end