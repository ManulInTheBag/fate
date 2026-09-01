modifier_rasputin_wide_kick_target = class({})


function modifier_rasputin_wide_kick_target:IsHidden()
    return true
end


function modifier_rasputin_wide_kick_target:IsPurgable()
    return true
end


function modifier_rasputin_wide_kick_target:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_wide_kick_target:GetModifierProvidesFOWVision()
    return 1
end


function modifier_rasputin_wide_kick_target:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_rasputin_seen = class({})

function modifier_rasputin_seen:IsHidden() return true end
function modifier_rasputin_seen:IsPurgable() return false end
function modifier_rasputin_seen:IsDebuff() return false end
function modifier_rasputin_seen:RemoveOnDeath() return true end


function modifier_rasputin_seen:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_seen:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_seen:GetModifierProvidesFOWVision()
    return 1
end
