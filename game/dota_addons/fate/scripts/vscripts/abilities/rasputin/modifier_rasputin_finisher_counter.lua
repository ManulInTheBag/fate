modifier_rasputin_finisher_counter = class({})

local DEFAULT_COOLDOWN_REFUND_PER_STACK = 1.5
local MAX_STACKS = 10


local MAX_STACKS_LINGER = 1.5

local MAX_STACKS_PARTICLE = "particles/rasputin/rasputin_max_stacks.vpcf"


local MAX_STACKS_RADIUS = 60


local ATTRIBUTE_ABILITIES = {
    rasputin_combat_movement = true,
    rasputin_territory_creation = true,
    rasputin_bk_curses = true,
    rasputin_keys = true,
}


function modifier_rasputin_finisher_counter:IsHidden()
    return true
end


function modifier_rasputin_finisher_counter:IsPurgable()
    return false
end


function modifier_rasputin_finisher_counter:RemoveOnDeath()
    return false
end


function modifier_rasputin_finisher_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_finisher_counter:AddStack(castToken)

    local stack = self:GetStackCount()

    if stack < MAX_STACKS then

        self:SetStackCount(stack + 1)

    end


    if self:GetStackCount() >= MAX_STACKS then
        self.max_stacks_particle_expire_time = nil
        self:CreateMaxStacksParticle()
    end

    -- кулдауны сокращаются один раз за факт попадания способностью:
    -- задел R трёх героев - сокращение всё равно одно
    if castToken ~= nil and castToken == self.lastRefundToken then return end

    self.lastRefundToken = castToken

    self:RefundCooldowns()

end


function modifier_rasputin_finisher_counter:CreateMaxStacksParticle()

    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent or parent:IsNull() then return end


    if self.max_stacks_particle then
        return
    end

    self.max_stacks_particle = ParticleManager:CreateParticle(
        RasputinFx(parent, MAX_STACKS_PARTICLE),
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )


    ParticleManager:SetParticleControl(
        self.max_stacks_particle,
        4,
        Vector(9999, 0, 0)
    )


    ParticleManager:SetParticleControl(
        self.max_stacks_particle,
        3,
        Vector(MAX_STACKS_RADIUS, 0, 0)
    )


    ParticleManager:SetParticleControl(
        self.max_stacks_particle,
        2,
        Vector(MAX_STACKS_RADIUS, 0, 0)
    )

end


function modifier_rasputin_finisher_counter:RemoveMaxStacksParticle()

    if not IsServer() then return end

    if not self.max_stacks_particle then
        return
    end


    ParticleManager:SetParticleControl(
        self.max_stacks_particle,
        4,
        Vector(MAX_STACKS_LINGER, 0, 0)
    )

    self.max_stacks_particle_expire_time =
        GameRules:GetGameTime() + MAX_STACKS_LINGER

end


function modifier_rasputin_finisher_counter:KillMaxStacksParticle()

    if not IsServer() then return end

    if not self.max_stacks_particle then return end

    ParticleManager:DestroyParticle(self.max_stacks_particle, true)
    ParticleManager:ReleaseParticleIndex(self.max_stacks_particle)

    self.max_stacks_particle = nil
    self.max_stacks_particle_expire_time = nil

end


function modifier_rasputin_finisher_counter:OnDestroy()

    if not IsServer() then return end

    self:KillMaxStacksParticle()

end


function modifier_rasputin_finisher_counter:UpdateMaxStacksParticle()

    if not IsServer() then return end

    local stack = self:GetStackCount()

    if stack >= MAX_STACKS then


        self.max_stacks_particle_expire_time = nil

        self:CreateMaxStacksParticle()

        return
    end


    if self.max_stacks_particle then


        if not self.max_stacks_particle_expire_time then
            self:RemoveMaxStacksParticle()
            return
        end


        if GameRules:GetGameTime() >= self.max_stacks_particle_expire_time then
            self:KillMaxStacksParticle()
        end

    end

end


function modifier_rasputin_finisher_counter:OnCreated()

    self:SetStackCount(0)

    self.max_stacks_particle = nil
    self.max_stacks_particle_expire_time = nil

    if not IsServer() then return end


    self.roundOn = _G.CurrentGameState == "FATE_ROUND_ONGOING"

    self:StartIntervalThink(0.1)

end


function modifier_rasputin_finisher_counter:DeclareFunctions()

    return {
        MODIFIER_EVENT_ON_DEATH,
    }

end


function modifier_rasputin_finisher_counter:OnDeath(params)

    if not IsServer() then return end

    if params.unit ~= self:GetParent() then return end


    self:SetStackCount(0)
    self:KillMaxStacksParticle()

    RasputinCancelAll(self:GetParent())

end


function modifier_rasputin_finisher_counter:OnIntervalThink()

    if not IsServer() then return end

    local roundOn = _G.CurrentGameState == "FATE_ROUND_ONGOING"


    if roundOn ~= self.roundOn then

        if self:GetStackCount() > 0 then
            self:SetStackCount(0)
        end

        self:KillMaxStacksParticle()

    end

    self.roundOn = roundOn


    local parent = self:GetParent()

    if IsNotNull(parent) and not parent:IsAlive() then

        if self:GetStackCount() > 0 then
            self:SetStackCount(0)
            self:KillMaxStacksParticle()
        end

    end

    self:UpdateMaxStacksParticle()

end


function modifier_rasputin_finisher_counter:RefundCooldowns()


    if not IsServer() then return end


    local parent = self:GetParent()


    if not parent or parent:IsNull() then return end


    local refund = DEFAULT_COOLDOWN_REFUND_PER_STACK

    local finisher = parent:FindAbilityByName("rasputin_finisher")


    if finisher then
        refund = finisher:GetLevelSpecialValueFor("cooldown_refund_per_stack", 0)
    end


    if refund <= 0 then return end


    local now = GameRules:GetGameTime()


    for i = 0, parent:GetAbilityCount() - 1 do


        local ability = parent:GetAbilityByIndex(i)


        if ability
            and not ability:IsNull()
            and not string.find(ability:GetAbilityName(), "_attribute")
            and not ATTRIBUTE_ABILITIES[ability:GetAbilityName()]
        then


            if ability.RefundChargeRestore then


                ability:RefundChargeRestore()


            elseif (tonumber(ability:GetKeyValue("AbilityCharges")) or 0) < 1 then

                if now < (ability.recastGapUntil or 0) then

                    ability.bankedCooldownRefund =
                    (ability.bankedCooldownRefund or 0) + refund

                elseif not ability:IsCooldownReady() then

                    local remaining = ability:GetCooldownTimeRemaining()

                    ability:EndCooldown()

                    if remaining > refund then
                        ability:StartCooldown(remaining - refund)
                    end

                end

            end


        end


    end


end
