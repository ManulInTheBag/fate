modifier_heart_of_harmony_speed = class({})

function modifier_heart_of_harmony_speed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
    }
 
    return funcs
end

function modifier_heart_of_harmony_speed:GetModifierMoveSpeed_Absolute() 
    return 550
end

-----------------------------------------------------------------------------------

function modifier_heart_of_harmony_speed:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_heart_of_harmony_speed:IsHidden()
    return true
end

function modifier_heart_of_harmony_speed:IsPurgable()
    return false
end

function modifier_heart_of_harmony_speed:IsDebuff()
    return false
end

function modifier_heart_of_harmony_speed:RemoveOnDeath()
    return true
end

function modifier_heart_of_harmony_speed:GetTexture()
    return "custom/false_assassin_heart_of_harmony"
end
-----------------------------------------------------------------------------------
