modifier_rasputin_low_kick_slow = class({})


function modifier_rasputin_low_kick_slow:IsHidden()
    return false
end


function modifier_rasputin_low_kick_slow:IsDebuff()
    return true
end


function modifier_rasputin_low_kick_slow:IsPurgable()
    return true
end


function modifier_rasputin_low_kick_slow:OnCreated(kv)

    self.slow =
    self:GetAbility():GetSpecialValueFor(
        "slow_amount"
    )


    if IsServer() and kv then

        self:SetDuration(
            kv.Duration or kv.duration,
            false
        )

    end

end


function modifier_rasputin_low_kick_slow:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

end


function modifier_rasputin_low_kick_slow:GetModifierMoveSpeedBonus_Percentage()

    return -self.slow

end
