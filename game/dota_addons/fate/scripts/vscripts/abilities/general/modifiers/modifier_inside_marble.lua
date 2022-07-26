modifier_inside_marble = class({})

function modifier_inside_marble:IsHidden()
    return true
end

function modifier_inside_marble:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end