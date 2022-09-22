modifier_catastrophe_active = class({})

function modifier_catastrophe_active:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_catastrophe_active:IsHidden()
    return true
end

function modifier_catastrophe_active:IsDebuff()
    return false
end

function modifier_catastrophe_active:RemoveOnDeath()
    return true
end