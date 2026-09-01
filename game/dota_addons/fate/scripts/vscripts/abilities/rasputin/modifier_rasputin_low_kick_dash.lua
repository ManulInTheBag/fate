modifier_rasputin_low_kick_dash = class({})


function modifier_rasputin_low_kick_dash:IsHidden()
    return true
end


function modifier_rasputin_low_kick_dash:IsPurgable()
    return false
end


function modifier_rasputin_low_kick_dash:CheckState()

    return {

        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_DISARMED] = true,

    }

end
