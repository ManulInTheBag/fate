require('abilities/rasputin/rasputin_gesture')

modifier_rasputin_low_kick_tracker = class({})


function modifier_rasputin_low_kick_tracker:IsHidden()
    return false
end

function modifier_rasputin_low_kick_tracker:IsDebuff()
    return false
end

function modifier_rasputin_low_kick_tracker:GetTexture()
    return "custom/rasputin/rasputin_low_kicks"
end


function modifier_rasputin_low_kick_tracker:IsPurgable()
    return false
end


function modifier_rasputin_low_kick_tracker:RemoveOnDeath()
    return true
end


function modifier_rasputin_low_kick_tracker:OnCreated(kv)

    if not IsServer() then return end

    self:SetStackCount(2)


    if kv then

        self:SetDuration(
            kv.Duration or kv.duration,
            false
        )

    end


    self.sequenceStart = GameRules:GetGameTime()

end


function modifier_rasputin_low_kick_tracker:OnDestroy()

    if not IsServer() then return end


    local ability = self:GetAbility()

    if ability then


        local start = self.sequenceStart or GameRules:GetGameTime()

        local elapsed = GameRules:GetGameTime() - start


        local refreshed = RasputinWasRefreshed(ability, start)


        local cooldown =
        ability:GetCooldown(ability:GetLevel())
        * ability:GetCaster():GetCooldownReduction()
        - elapsed
        - (ability.bankedCooldownRefund or 0)

        ability.bankedCooldownRefund = nil
        ability.recastGapUntil = nil

        ability:EndCooldown()

        if refreshed then
            ability.rasputinRefreshedAt = nil
            return
        end

        if cooldown > 0 then
            ability:StartCooldown(cooldown)
        end

    end

end
