local function PlayFlurry(caster, ability)

    local forward = caster:GetForwardVector()
    forward.z = 0

    if forward:Length2D() == 0 then return end

    forward = forward:Normalized()


    local start =
    caster:GetAbsOrigin()
    + forward * ability:GetSpecialValueFor("hit_fx_offset")
    + Vector(0, 0, ability:GetSpecialValueFor("hit_fx_height"))

    local length = ability:GetSpecialValueFor("hit_fx_length")

    local fx = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_finisher_hits.vpcf"),
        PATTACH_CUSTOMORIGIN,
        caster
    )

    ParticleManager:SetParticleControl(fx, 0, start)
    ParticleManager:SetParticleControl(fx, 1, start + forward * (length * 0.5))
    ParticleManager:SetParticleControl(fx, 2, start + forward * length)


    ParticleManager:SetParticleControl(fx, 3, start)
    RasputinAimParticle(fx, 3, forward)
    RasputinAimParticle(fx, 0, forward)


    ParticleManager:ReleaseParticleIndex(fx)

end


local function PlayHitWave(caster, victim, ability)

    local fx = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_finisher_hit_enemy.vpcf"),
        PATTACH_POINT_FOLLOW,
        victim
    )


    local behind = victim:GetAbsOrigin() - caster:GetAbsOrigin()
    behind.z = 0

    if behind:Length2D() > 0 then
        behind = behind:Normalized()
    else
        behind = caster:GetForwardVector()
        behind.z = 0
        behind = behind:Normalized()
    end

    local attach = victim:ScriptLookupAttachment("attach_hitloc")

    local hit = victim:GetAbsOrigin()

    if attach and attach > 0 then

        local origin = victim:GetAttachmentOrigin(attach)

        if origin and origin:Length() > 0 then
            hit = origin
        end

    end

    ParticleManager:SetParticleControl(
        fx,
        1,
        hit + behind * ability:GetSpecialValueFor("hit_wave_offset")
    )


    RasputinAimParticle(fx, 1, behind)

    ParticleManager:ReleaseParticleIndex(fx)

end


local FINISHER_TICK = 0.1


modifier_rasputin_finisher_channel = class({})


function modifier_rasputin_finisher_channel:IsHidden()
    return true
end


function modifier_rasputin_finisher_channel:IsPurgable()
    return false
end


function modifier_rasputin_finisher_channel:OnCreated(kv)

    if not IsServer() then return end


    self.parent = self:GetParent()

    self.ability = self:GetAbility()


    self.damage =
    RasputinScaleDamage(
        self:GetCaster(),
        self.ability,
        self.ability:GetSpecialValueFor("tick_damage")
    )
    * (self.ability.tickScale or 1)


    self.duration =
    kv.duration


    self:StartIntervalThink(FINISHER_TICK)

end


function modifier_rasputin_finisher_channel:CheckState()


    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

end


function modifier_rasputin_finisher_channel:StepToNext(caster, ability, targets)

    if #targets < 2 then return end

    self.strike = (self.strike or 0) + 1

    local victim = targets[(self.strike - 1) % #targets + 1]

    if not IsNotNull(victim) then return end


    local approach = caster:GetAbsOrigin() - victim:GetAbsOrigin()
    approach.z = 0

    if approach:Length2D() == 0 then
        approach = caster:GetForwardVector()
        approach.z = 0
    end

    approach = approach:Normalized()

    local spot =
    victim:GetAbsOrigin()
    + approach * ability:GetSpecialValueFor("strike_offset")

    caster:SetAbsOrigin(GetGroundPosition(spot, caster))

    caster:SetForwardVector(-approach)

end


function modifier_rasputin_finisher_channel:OnIntervalThink()


    local ability =
    self:GetAbility()


    local caster =
    self:GetCaster()


    if not IsNotNull(ability) or not IsNotNull(caster) or not caster:IsAlive() then
        self:Destroy()
        return
    end


    -- разлетевшуюся группу отсеиваем перед ударом: по отставшим ни прыжка, ни урона
    if ability.PruneFarTargets then
        ability:PruneFarTargets()
    end


    local bAnyHit = false

    local alive = 0

    for _,enemy in pairs(ability.targets or {}) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() then
            alive = alive + 1
        end
    end

    if alive == 0 then
        self:Destroy()
        return
    end


    for _,enemy in pairs(
        ability.targets or {}
    )
    do


        if enemy and not enemy:IsNull() then


            DoDamage(
                caster,
                enemy,
                self.damage,
                DAMAGE_TYPE_PHYSICAL,
                0,
                ability,
                false
            )


            ability:HealFromDamage(self.damage)

            PlayHitWave(caster, enemy, ability)


            RasputinHitFx(enemy, ability:GetSpecialValueFor("hit_spark_spread"), caster)

            bAnyHit = true


        end

    end


    if bAnyHit then


        self:StepToNext(caster, ability, ability.targets or {})


        RasputinFinisherAfterimage(
            caster,
            RasputinPlayFlurryBlow(caster, FINISHER_TICK)
        )

        caster:EmitSound(
            "rasputin_finisher_hit_" .. math.random(1, 5)
        )


        PlayFlurry(caster, ability)

    end


end


function modifier_rasputin_finisher_channel:OnDestroy()


    if not IsServer() then return end


    local ability = self:GetAbility()

    if not IsNotNull(ability) then return end


    -- Распутин умер посреди серии: добивающий удар и комбо отменяются,
    -- иначе труп доносил урон и швырял цели
    local caster = self:GetCaster()

    if not IsNotNull(caster) or not caster:IsAlive() then return end


    ability:DealFinishDamage()


    ability:StartArmedCombo()


end
