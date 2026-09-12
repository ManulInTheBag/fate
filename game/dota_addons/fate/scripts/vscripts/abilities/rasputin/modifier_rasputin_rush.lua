require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_knife_dash')

modifier_rasputin_rush = class({})


-- Насколько цель может сместиться за кадр, пока рывок её ещё догоняет.
-- Обычный бег даёт заметно меньше, блинк и рывки — заметно больше.
local TARGET_ESCAPE_LIMIT = 300


function modifier_rasputin_rush:IsHidden()
    return false
end


function modifier_rasputin_rush:IsDebuff()
    return false
end


function modifier_rasputin_rush:RemoveOnDeath()
    return true
end


function modifier_rasputin_rush:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end


function modifier_rasputin_rush:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end


function modifier_rasputin_rush:GetModifierDisableTurning()
    return 1
end


function modifier_rasputin_rush:OnCreated(kv)

    if not IsServer() then return end


    self.parent = self:GetParent()
    self.ability = self:GetAbility()


    self.target = self.parent.dash_target

    if not self.target or self.target:IsNull() or not self.target:IsAlive() then
        self:Destroy()
        return
    end


    self.damage = kv.damage
    self.speed = kv.speed

    self.damage_dealth = false


    self.parent:Stop()

    self:StartDashPose()


    RasputinDashTrail(self.parent, function()
        return not self.destroyed
    end)

    RasputinDashShield(self.parent, function()
        return not self.destroyed
    end)

    RasputinAfterimageTrail(self.parent, function()
        return not self.destroyed
    end)


    local direction =
    (self.target:GetAbsOrigin() -
    self.parent:GetAbsOrigin()):Normalized()

    direction.z = 0

    self.parent:SetForwardVector(direction)

    self.targetpos = self.target:GetAbsOrigin()

    self.last_position = self.parent:GetAbsOrigin()

    self.lastMotionTime = GameRules:GetGameTime()


    self:StartIntervalThink(FrameTime())

    if self:ApplyHorizontalMotionController() == false then
        self:Destroy()
    end

end


function modifier_rasputin_rush:StartDashPose()

    local wait = RasputinBusyGestureRemaining(self.parent)

    if wait <= 0 then
        self.poseStarted = true
        RasputinPlayGesture(self.parent, ACT_DOTA_CAST_ABILITY_3, 0)
        return
    end

    Timers:CreateTimer(wait, function()

        if not IsNotNull(self) then return end


        if self.destroyed then return end

        if not IsNotNull(self.parent) then return end

        self.poseStarted = true

        RasputinPlayGesture(self.parent, ACT_DOTA_CAST_ABILITY_3, 0)

    end)

end


function modifier_rasputin_rush:UpdateHorizontalMotion(me, dt)

    self.lastMotionTime = GameRules:GetGameTime()

    if not self.target or self.target:IsNull() or not self.target:IsAlive() then
        self:Destroy()
        return
    end


    -- цель перестала быть валидной для способности (невидимость к цели, смена команды,
    -- неуязвимость) — рывок обрывается, как Battle drive у Hijikata
    if IsNotNull(self.ability) then

        local filter = UnitFilter(
            self.target,
            self.ability:GetAbilityTargetTeam(),
            self.ability:GetAbilityTargetType(),
            self.ability:GetAbilityTargetFlags(),
            self.parent:GetTeamNumber()
        )

        if filter ~= UF_SUCCESS then
            self:Destroy()
            return
        end

    end


    -- блинк и любой другой рывок цели прекращают погоню: сверяем позицию цели
    -- с прошлым кадром, скачок больше порога = обрыв (так же сделано у Hijikata)
    local target_origin = self.target:GetAbsOrigin()

    if (self.targetpos - target_origin):Length2D() > TARGET_ESCAPE_LIMIT then
        self:Destroy()
        return
    end

    self.targetpos = target_origin


    -- стан прекращает рывок
    if self.parent:IsStunned() then
        self:Destroy()
        return
    end


    local current_position = self.parent:GetAbsOrigin()


    local expected_step = self.speed * dt

    if (current_position - self.last_position):Length2D() > expected_step * 3 + 100 then

        self:Destroy()
        return

    end


    local distance =
    (self.target:GetAbsOrigin()
    -
    current_position):Length2D()


    if distance < 200 and not self.damage_dealth then

        if self:ShouldGrab() then
            self:StartGrab()
        else
            self:BOOM()
        end

        return

    end


    if distance < 80 then

        self:Destroy()
        return

    end


    local target_pos =
    self.target:GetAbsOrigin()


    local direction =
    (target_pos -
    current_position):Normalized()

    direction.z = 0


    local step = self.speed * dt

    if step > distance then
        step = distance
    end


    local new_position = current_position + direction * step

    self.parent:SetOrigin(new_position)

    self.last_position = new_position


    self.parent:FaceTowards(target_pos)

end


-- Сторож зависшего рывка. Блинк (и любой другой перехват моушена) умеет выбить
-- контроллер так, что UpdateHorizontalMotion больше не вызывается. Модификатор
-- бессрочный, поэтому раньше в этом случае навсегда оставались поза и трейл.
local MOTION_STALL_LIMIT = 0.25

function modifier_rasputin_rush:OnIntervalThink()

    if not IsServer() then return end

    if self.destroyed then return end

    if not IsNotNull(self.parent) or not self.parent:IsAlive() then
        self.interrupted = true
        self:Destroy()
        return
    end

    if GameRules:GetGameTime() - (self.lastMotionTime or 0) > MOTION_STALL_LIMIT then
        self.interrupted = true
        self:Destroy()
    end

end


function modifier_rasputin_rush:OnHorizontalMotionInterrupted()

    if not IsServer() then return end


    if self:ApplyHorizontalMotionController() == false then
        self.interrupted = true
        self:Destroy()
    end

end


function modifier_rasputin_rush:ShouldGrab()

    if not IsNotNull(self.ability) then return false end

    if not IsNotNull(self.target) then return false end


    -- иммунного к кнокбеку не поднимаем: он получит обычный урон рывка через BOOM
    if IsKnockbackImmune(self.target) then return false end


    -- по трупу граб не запускаем: StartGrab списывает кулдаун раньше,
    -- чем отложенный таймер успевает проверить живость цели
    if not self.target:IsAlive() then return false end


    if self.parent:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
        return false
    end

    local counter =
    self.parent:FindModifierByName(
        "modifier_rasputin_finisher_counter"
    )

    if not counter then return false end

    if counter:GetStackCount()
        < self.ability:GetSpecialValueFor("grab_stack_threshold")
    then
        return false
    end


    if not RasputinGrabReady(self.parent, self.ability) then
        return false
    end

    return true

end


function modifier_rasputin_rush:StartGrab()

    self.damage_dealth = true


    RasputinStartGrabCooldown(self.parent, self.ability)

    local caster = self.parent
    local target = self.target
    local ability = self.ability


    RasputinReleaseKnifeMark(target, self.ability)


    if IsSpellBlocked(target) then
        self:Destroy()
        return
    end

    local direction = target:GetAbsOrigin() - caster:GetAbsOrigin()
    direction.z = 0

    if direction:Length2D() == 0 then
        direction = caster:GetForwardVector()
        direction.z = 0
    end

    direction = direction:Normalized()


    caster:SetForwardVector(direction)


    local victimOrigin = target:GetAbsOrigin()

    local heroLanding =
    victimOrigin
    + direction * ability:GetSpecialValueFor("grab_hero_overshoot")

    local victimLanding =
    heroLanding
    + direction * ability:GetSpecialValueFor("grab_victim_lead")

    local grabKeys = {
        duration = ability:GetSpecialValueFor("grab_duration"),
        grab_duration = ability:GetSpecialValueFor("grab_duration"),
        height = ability:GetSpecialValueFor("grab_height"),
        victim_height = ability:GetSpecialValueFor("grab_victim_height"),
        hero_land_fraction = ability:GetSpecialValueFor("grab_hero_land_fraction"),
        victim_index = target:GetEntityIndex(),
    }


    RasputinPlayGesture(caster, ACT_DOTA_OVERRIDE_ABILITY_2)


    self.interrupted = true
    self:Destroy()


    Timers:CreateTimer(FrameTime(), function()

        if not IsNotNull(caster) or not IsNotNull(target) then return end

        if not IsNotNull(ability) then return end

        if not caster:IsAlive() or not target:IsAlive() then return end

        grabKeys.is_victim = 0
        grabKeys.dest_x = heroLanding.x
        grabKeys.dest_y = heroLanding.y
        caster:AddNewModifier(caster, ability, "modifier_rasputin_knife_grab", grabKeys)

        grabKeys.is_victim = 1
        grabKeys.dest_x = victimLanding.x
        grabKeys.dest_y = victimLanding.y
        target:AddNewModifier(caster, ability, "modifier_rasputin_knife_grab", grabKeys)

    end)

end


function modifier_rasputin_rush:BOOM()

    if self.damage_dealth then return end


    self.damage_dealth = true


    local caster = self.parent
    local target = self.target


    RasputinReleaseKnifeMark(target, self.ability)


    if IsSpellBlocked(target) then
        return
    end


    if not caster:HasModifier("modifier_rasputin_wide_kick_anim_lock") then


        local ARRIVAL_ANIM_RATE = 1.875

        local clip = RASPUTIN_CLIP[ACT_DOTA_ATTACK]

        RasputinPlayGesture(
            caster,
            ACT_DOTA_ATTACK,
            clip and clip / ARRIVAL_ANIM_RATE or nil,
            ARRIVAL_ANIM_RATE
        )

    end


    if IsNotNull(self.ability) then
        self.ability:DamageShields(target)
    end


    local position =
    target:GetAbsOrigin()


    local fx =
    ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf"),
        PATTACH_CUSTOMORIGIN,
        caster
    )


    ParticleManager:SetParticleControl(
        fx,
        0,
        position
    )


    ParticleManager:ReleaseParticleIndex(fx)


    if not target:IsMagicImmune() then


        Timers:CreateTimer(
        0.1,
        function()

            if not IsNotNull(caster) or not IsNotNull(target) then return end

            if not IsNotNull(self.ability) then return end

            if not caster:IsAlive() or not target:IsAlive() then return end


            local final_damage =
            self.damage


            RasputinHitFx(target, nil, caster)


            local hand = ParticleManager:CreateParticle(
                RasputinFx(caster, "particles/rasputin/rasputin_knife_dash_hit.vpcf"),
                PATTACH_POINT_FOLLOW,
                caster
            )

            ParticleManager:SetParticleControlEnt(
                hand,
                1,
                caster,
                PATTACH_POINT_FOLLOW,
                "attach_attack2",
                caster:GetAbsOrigin(),
                true
            )

            local facing = caster:GetForwardVector()
            facing.z = 0

            if facing:Length2D() > 0 then

                facing = facing:Normalized()

                local from = caster:GetAbsOrigin()

                local attach = caster:ScriptLookupAttachment("attach_attack2")

                if attach and attach > 0 then

                    local at = caster:GetAttachmentOrigin(attach)

                    if at and at:Length() > 0 then
                        from = at
                    end

                end

                ParticleManager:SetParticleControl(hand, 2, from + facing * 100)
                ParticleManager:SetParticleControl(hand, 3, from)
                RasputinAimParticle(hand, 3, facing)

            end

            ParticleManager:ReleaseParticleIndex(hand)

            DoDamage(
                caster,
                target,
                final_damage,
                DAMAGE_TYPE_PHYSICAL,
                0,
                self.ability,
                false
            )


            RasputinGrantStack(caster, self.ability, target)


        end)

    end


    EmitSoundOnLocationWithCaster(
        position,
        "rasputin_knife_dash_recast_hit",
        caster
    )

end


function modifier_rasputin_rush:OnDestroy()

    if not IsServer() then return end


    self.destroyed = true

    if not self.parent or self.parent:IsNull() then
        return
    end


    RasputinStopGesture(self.parent, ACT_DOTA_CAST_ABILITY_3)


    self.parent:RemoveHorizontalMotionController(self)


    if not self.interrupted then
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
    end

end


function modifier_rasputin_rush:CheckState()

    return {

        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,

    }

end
