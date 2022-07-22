modifier_sasaki_vision = class({})

function modifier_sasaki_vision:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_sasaki_vision:GetModifierProvidesFOWVision()
	if self:GetParent():HasModifier("modifier_murderer_mist_invis") then
		return 0
	end
    return 1
end

function modifier_sasaki_vision:IsHidden()
	return false
end

function modifier_sasaki_vision:IsDebuff()
    return true
end

function modifier_sasaki_vision:RemoveOnDeath()
    return true
end

function modifier_sasaki_vision:GetTexture()
	return "custom/false_assassin_attribute_eye_of_serenity"
end