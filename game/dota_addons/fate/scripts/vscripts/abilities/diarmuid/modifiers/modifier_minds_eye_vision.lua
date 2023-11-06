modifier_minds_eye_vision = class({})

function modifier_minds_eye_vision:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_minds_eye_vision:GetModifierProvidesFOWVision()
	if CanBeDetected(self:GetParent()) then
		return 1
	end
	return 0
end

function modifier_minds_eye_vision:IsHidden()
	return false
end

function modifier_minds_eye_vision:IsDebuff()
    return true
end

function modifier_minds_eye_vision:RemoveOnDeath()
    return true
end