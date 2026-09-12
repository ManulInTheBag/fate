require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

rasputin_low_kick = class({})

LinkLuaModifier("modifier_rasputin_low_kick_tracker","abilities/rasputin/modifier_rasputin_low_kick_tracker",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_low_kick_slow","abilities/rasputin/modifier_rasputin_low_kick_slow",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_low_kick_dash","abilities/rasputin/modifier_rasputin_low_kick_dash",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_low_kick_root","abilities/rasputin/rasputin_low_kick",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_low_kick_disarm","abilities/rasputin/rasputin_low_kick",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_low_kick_lunge","abilities/rasputin/rasputin_low_kick",LUA_MODIFIER_MOTION_HORIZONTAL)


local function IsDashing(unit)
    return unit:HasModifier("modifier_rasputin_dash_move")
        or unit:HasModifier("modifier_rasputin_rush")
end


local function InFront(unit, from, direction)

    local toUnit = unit:GetAbsOrigin() - from
    toUnit.z = 0

    if toUnit:Length2D() == 0 then
        return true
    end

    return direction:Dot(toUnit:Normalized()) >= 0

end


function rasputin_low_kick:CastFilterResultLocation(location)

    local caster = self:GetCaster()

    if RasputinIsRooted(caster) and self:CheckSequence() >= 2 then
        self.customCastError = "Cannot use while rooted"
        return UF_FAIL_CUSTOM
    end



    if caster:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
        self.customCastError = "Cannot use during the ultimate"
        return UF_FAIL_CUSTOM
    end


    if caster:HasModifier("modifier_rasputin_rush") then
        self.customCastError = "Cannot use while charging"
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS

end


function rasputin_low_kick:GetCustomCastErrorLocation(location)
    return self.customCastError or "Cannot use right now"
end


function rasputin_low_kick:GetAbilityTextureName()

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_rasputin_low_kick_tracker") then

        local stack =
        caster:GetModifierStackCount("modifier_rasputin_low_kick_tracker", caster)

        if stack >= 3 then
            return "custom/rasputin/rasputin_low_kicks3"
        end

        if stack == 2 then
            return "custom/rasputin/rasputin_low_kicks2"
        end

    end

    return "custom/rasputin/rasputin_low_kicks"

end


function rasputin_low_kick:CheckSequence()

    local caster = self:GetCaster()

    local modifier =
        caster:FindModifierByName(
            "modifier_rasputin_low_kick_tracker"
        )


    if modifier then

        return modifier:GetStackCount()

    end


    return 0

end


function rasputin_low_kick:SequenceSkill()

    local caster = self:GetCaster()

    local modifier =
    caster:FindModifierByName(
        "modifier_rasputin_low_kick_tracker"
    )


    if not modifier then

        modifier = caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_low_kick_tracker",
            {
                Duration = self:GetSpecialValueFor("sequence_window")
            }
        )


    else

        local stack = modifier:GetStackCount()

        if stack < 3 then
            modifier:SetStackCount(stack + 1)
        end


        modifier:SetDuration(
            self:GetSpecialValueFor("sequence_window"),
            true
        )

    end

end


function rasputin_low_kick:RecastGap(key, caster)

    local gap = self:GetSpecialValueFor(key)

    if gap < 0 then
        gap = 0
    end

    if RasputinIsReborn(caster) then

        local cut = self:GetSpecialValueFor("reborn_kick_gap_pct")

        if cut > 0 then

            if cut > 100 then
                cut = 100
            end

            gap = gap * (1 - cut / 100)

        end

    end

    return gap

end


function rasputin_low_kick:OnSpellStart()

    local caster = self:GetCaster()

    ProjectileManager:ProjectileDodge(caster)


    local seq = self:CheckSequence()


    if seq == 3 then

        self:LowKick3()


    elseif seq == 2 then

        self:LowKick2()


    else

        self:LowKick1()

    end

end


function rasputin_low_kick:LowKick1()

    local caster = self:GetCaster()

    local refundToken = RasputinCastToken(self)
    local length = self:GetSpecialValueFor("length")
    local width = self:GetSpecialValueFor("width")


    local damage =
    RasputinScaleDamage(caster, self, self:GetSpecialValueFor("damage_1"))
    local slowDuration = self:GetSpecialValueFor("slow_duration")


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_root",
        {
            duration = 0.1
        }
    )


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_disarm",
        {
            duration = self:GetSpecialValueFor("hitbox_duration")
        }
    )

    local position = self:GetCursorPosition()
    local origin = caster:GetAbsOrigin()

    local direction = (Vector(position.x, position.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()

    if direction:Length2D() == 0 then
        direction = caster:GetForwardVector()
    end

    direction.z = 0
    direction = direction:Normalized()

    if not IsDashing(caster) then


        caster:Stop()
        caster:SetForwardVector(direction)
    end


    RasputinPlayGesture(caster, ACT_DOTA_CAST_ABILITY_2)

    caster:EmitSound("rasputin_low_kick_1_swing")


    local hitboxDuration = self:GetSpecialValueFor("hitbox_duration")


    local markerBonus = self:GetSpecialValueFor("w1_marker_bonus")

    local swingFx = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_low_kick_1.vpcf"),
        PATTACH_CUSTOMORIGIN,
        caster
    )

    local markerFx = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_skill_marker.vpcf"),
        PATTACH_CUSTOMORIGIN,
        caster
    )

    ParticleManager:SetParticleShouldCheckFoW(markerFx, false)

    local function UpdateKickFx()

        local currentOrigin = caster:GetAbsOrigin()


        ParticleManager:SetParticleControl(swingFx, 3, currentOrigin)
        ParticleManager:SetParticleControl(swingFx, 4, currentOrigin)


        ParticleManager:SetParticleControl(swingFx, 5, Vector(length, width, 30))
        ParticleManager:SetParticleControl(swingFx, 6, Vector(0, -width, -10))


        RasputinAimParticle(swingFx, 3, direction)
        RasputinAimParticle(swingFx, 4, direction)


        ParticleManager:SetParticleControl(markerFx, 0, currentOrigin)
        ParticleManager:SetParticleControl(markerFx, 1, currentOrigin)
        ParticleManager:SetParticleControl(
            markerFx,
            2,
            currentOrigin + direction * (length + markerBonus)
        )
        ParticleManager:SetParticleControl(markerFx, 3, Vector(width, 0, 0))
        ParticleManager:SetParticleControl(markerFx, 11, Vector(hitboxDuration, 0, 0))

    end


    RasputinFollowParticle(
        UpdateKickFx,
        function() return IsNotNull(caster) and caster:IsAlive() end,
        hitboxDuration + 0.5,
        swingFx
    )

    Timers:CreateTimer(hitboxDuration + 0.5, function()
        ParticleManager:ReleaseParticleIndex(markerFx)
    end)

    local hitEnemies = {}

    local function CheckHits()

        local currentOrigin = caster:GetAbsOrigin()

        local enemies = FindUnitsInLine(
            caster:GetTeamNumber(),
            currentOrigin,
            currentOrigin + direction * length,
            nil,
            width,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE
        )

        for _,enemy in pairs(enemies) do

            if not hitEnemies[enemy] and InFront(enemy, currentOrigin, direction) then

                hitEnemies[enemy] = true

                caster:EmitSound("rasputin_low_kick_1_hit")

                RasputinHitFx(enemy, nil, caster)

                RasputinGrantStack(caster, self, enemy, refundToken)

                DoDamage(
                    caster,
                    enemy,
                    damage,
                    DAMAGE_TYPE_PHYSICAL,
                    0,
                    self,
                    false
                )

                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_rasputin_low_kick_slow",
                    {
                        Duration = slowDuration
                    }
                )

            end

        end

    end

    CheckHits()


    local elapsed = 0
    local checkInterval = 0.03

    Timers:CreateTimer(checkInterval, function()

        if not IsNotNull(caster) then return end

        if not caster:IsAlive() then return end

        CheckHits()

        elapsed = elapsed + checkInterval

        if elapsed < hitboxDuration then
            return checkInterval
        end

    end)

    self:SequenceSkill()
    self:EndCooldown()


    local recastGap = self:RecastGap("w1_recast_gap", caster)

    self:StartCooldown(recastGap)

    self.recastGapUntil = GameRules:GetGameTime() + recastGap

end


function rasputin_low_kick:LowKick2()

    local caster = self:GetCaster()

    local refundToken = RasputinCastToken(self)
    local length = self:GetSpecialValueFor("length")
    local width = self:GetSpecialValueFor("width")


    local damage =
    RasputinScaleDamage(caster, self, self:GetSpecialValueFor("damage_2"))


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_root",
        {
            duration = 0.1
        }
    )

    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_disarm",
        {
            duration = self:GetSpecialValueFor("hitbox_duration")
        }
    )

    local position = self:GetCursorPosition()
    local origin = caster:GetAbsOrigin()

    local direction = (Vector(position.x, position.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()

    if direction:Length2D() == 0 then
        direction = caster:GetForwardVector()
    end

    direction.z = 0
    direction = direction:Normalized()

    if not IsDashing(caster) then


        caster:Stop()
        caster:SetForwardVector(direction)
    end

    RasputinPlayGesture(caster, ACT_DOTA_CAST_ABILITY_4)

    caster:EmitSound("rasputin_low_kick_2_swing")


    local kickFx = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_low_kick_2.vpcf"),
        PATTACH_CUSTOMORIGIN,
        caster
    )

    local function UpdateKickFx()
        local origin = caster:GetAbsOrigin()
        ParticleManager:SetParticleControl(kickFx, 0, origin)
        ParticleManager:SetParticleControl(kickFx, 1, origin + direction * length)
        RasputinAimSweep(kickFx, 0, direction)
        RasputinAimSweep(kickFx, 1, direction)


        ParticleManager:SetParticleControl(kickFx, 3, origin)
        RasputinAimParticle(kickFx, 3, direction)
    end


    RasputinFollowParticle(
        UpdateKickFx,
        function() return IsNotNull(caster) and caster:IsAlive() end,
        self:GetSpecialValueFor("hitbox_duration") + 0.5,
        kickFx
    )


    local hitEnemies = {}

    local function CheckHits()

        local currentOrigin = caster:GetAbsOrigin()

        local enemies = FindUnitsInLine(
            caster:GetTeamNumber(),
            currentOrigin,
            currentOrigin + direction * length,
            nil,
            width,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE
        )

        for _,enemy in pairs(enemies) do

            if not hitEnemies[enemy] and InFront(enemy, currentOrigin, direction) then

                hitEnemies[enemy] = true

                caster:EmitSound("rasputin_low_kick_2_hit")

                RasputinHitFx(enemy, nil, caster)

                RasputinGrantStack(caster, self, enemy, refundToken)

                DoDamage(
                    caster,
                    enemy,
                    damage,
                    DAMAGE_TYPE_PHYSICAL,
                    0,
                    self,
                    false
                )

                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_knockback",
                    {

                        should_stun = 0,

                        knockback_duration =
                        self:GetSpecialValueFor(
                            "knockback_duration"
                        ),

                        duration =
                        self:GetSpecialValueFor(
                            "knockback_duration"
                        ),

                        knockback_distance =
                        self:GetSpecialValueFor(
                            "knockback_distance"
                        ),

                        knockback_height =
                        self:GetSpecialValueFor(
                            "knockback_height"
                        ),


                        center_x =
                        enemy:GetAbsOrigin().x-direction.x,

                        center_y =
                        enemy:GetAbsOrigin().y-direction.y,

                        center_z =
                        enemy:GetAbsOrigin().z

                    }
                )


                RasputinWallStop(
                    enemy,
                    self:GetSpecialValueFor("knockback_duration"),
                    RASPUTIN_THIN_OBSTACLE
                )


                -- вместо стана: рут и димлок на ту же длительность, что и отбрасывание
                giveUnitDataDrivenModifier(
                    caster,
                    enemy,
                    "rooted",
                    self:GetSpecialValueFor("knockback_duration")
                )

                giveUnitDataDrivenModifier(
                    caster,
                    enemy,
                    "locked",
                    self:GetSpecialValueFor("knockback_duration")
                )

            end

        end

    end

    CheckHits()


    local hitboxDuration = self:GetSpecialValueFor("hitbox_duration")
    local fxDuration = RASPUTIN_CLIP[ACT_DOTA_CAST_ABILITY_4] or hitboxDuration
    local elapsed = 0
    local checkInterval = 0.03

    Timers:CreateTimer(checkInterval, function()

        if not IsNotNull(caster) then return end

        if not caster:IsAlive() then return end

        UpdateKickFx()

        if elapsed < hitboxDuration then
            CheckHits()
        end

        elapsed = elapsed + checkInterval

        if elapsed < math.max(hitboxDuration, fxDuration) then
            return checkInterval
        end

    end)

    self:SequenceSkill()
    self:EndCooldown()


    local recastGap = self:RecastGap("w2_recast_gap", caster)

    self:StartCooldown(recastGap)

    self.recastGapUntil = GameRules:GetGameTime() + recastGap

end

function rasputin_low_kick:LowKick3()

    local caster = self:GetCaster()

    local refundToken = RasputinCastToken(self)

    local point = self:GetCursorPosition()

    caster:RemoveModifierByName(
        "modifier_rasputin_low_kick_tracker"
    )

    caster:EmitSound("rasputin_low_kick_3_swing")

    local origin = caster:GetAbsOrigin()

    local direction = (Vector(point.x, point.y, 0) - Vector(origin.x, origin.y, 0)):Normalized()

    if direction:Length2D() == 0 then
        direction = caster:GetForwardVector()
    end

    direction.z = 0
    direction = direction:Normalized()

    if not IsDashing(caster) then


        caster:Stop()
        caster:SetForwardVector(direction)
    end


    local distance =
    self:GetSpecialValueFor("knockback_distance")
    -
    self:GetSpecialValueFor("dash_distance_reduction")

    if distance < 0 then
        distance = 0
    end


    local jumpSpeed = self:GetSpecialValueFor("w3_jump_speed")


    if RasputinIsReborn(caster) then
        jumpSpeed = jumpSpeed * (1 + self:GetSpecialValueFor("reborn_dash_speed_pct") / 100)
    end

    local knockbackDuration = self:GetSpecialValueFor("knockback_duration")

    if jumpSpeed > 0 and distance > 0 then
        knockbackDuration = distance / jumpSpeed
    end


    local W3_ANIM_SPEEDUP_FRAMES = 2

    local clip = RASPUTIN_CLIP[ACT_DOTA_OVERRIDE_ABILITY_1]

    local gestureRate = 1

    if clip and clip > 0 and knockbackDuration > 0 then
        gestureRate = (clip + W3_ANIM_SPEEDUP_FRAMES / 30) / knockbackDuration
    end

    RasputinPlayGesture(
        caster,
        ACT_DOTA_OVERRIDE_ABILITY_1,
        knockbackDuration,
        gestureRate
    )


    local swingTime = knockbackDuration

    if gestureRate > 0 and clip and clip > 0 then
        swingTime = clip / gestureRate
    end

    Timers:CreateTimer(swingTime, function()

        if not IsNotNull(caster) then return end

        if not caster:IsAlive() then return end


        if not caster:HasModifier("modifier_rasputin_low_kick_dash") then return end

        RasputinPlayGesture(caster, ACT_DOTA_OVERRIDE_ABILITY_4, 0)

    end)


    for _,name in ipairs({
        "modifier_rasputin_low_kick_lunge",
        "modifier_rasputin_dash_move",
        "modifier_rasputin_rush",
    }) do

        local mover = caster:FindModifierByName(name)

        if mover then
            mover.interrupted = true
            mover:Destroy()
        end

    end

    caster:InterruptMotionControllers(true)

    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_lunge",
        {
            duration = knockbackDuration + 0.25,
            direction_x = direction.x,
            direction_y = direction.y,
            distance = distance,
            speed = jumpSpeed,


            wall_depth = RASPUTIN_THIN_OBSTACLE,
        }
    )


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_low_kick_dash",
        {
            duration = knockbackDuration
        }
    )


    Timers:CreateTimer(knockbackDuration, function()


        RasputinStopGesture(caster, ACT_DOTA_OVERRIDE_ABILITY_4)

        if not IsNotNull(caster) then return end

        if not caster:IsAlive() then return end

        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

        self:DashImpact(direction, refundToken)

    end)

end


function rasputin_low_kick:DashImpact(direction, refundToken)

    local caster = self:GetCaster()


    local radius = self:GetSpecialValueFor("w3_radius")


    local damage =
        RasputinScaleDamage(caster, self, self:GetSpecialValueFor("damage_3"))

    local origin = caster:GetAbsOrigin()


    if not IsDashing(caster) then
        caster:SetForwardVector(direction)
    end


    local impact =
    origin + direction * self:GetSpecialValueFor("w3_impact_offset")


    RasputinSlam(caster, impact, radius)


    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        impact,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )


    if #enemies > 0 then
        caster:EmitSound("rasputin_low_kick_3_hit")
    end


    for _,enemy in pairs(enemies) do


        RasputinHitFx(enemy, nil, caster)

        RasputinGrantStack(caster, self, enemy, refundToken)

        DoDamage(
            caster,
            enemy,
            damage,
            DAMAGE_TYPE_PHYSICAL,
            0,
            self,
            false
        )


    end

end


modifier_rasputin_low_kick_root = class({})

function modifier_rasputin_low_kick_root:IsHidden() return true end
function modifier_rasputin_low_kick_root:IsPurgable() return false end

function modifier_rasputin_low_kick_root:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end


modifier_rasputin_low_kick_disarm = class({})

function modifier_rasputin_low_kick_disarm:IsHidden() return true end
function modifier_rasputin_low_kick_disarm:IsPurgable() return false end
function modifier_rasputin_low_kick_disarm:RemoveOnDeath() return true end

function modifier_rasputin_low_kick_disarm:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
    }
end


modifier_rasputin_low_kick_lunge = class({})

function modifier_rasputin_low_kick_lunge:IsHidden() return true end
function modifier_rasputin_low_kick_lunge:IsPurgable() return false end

function modifier_rasputin_low_kick_lunge:OnCreated(kv)

    if not IsServer() then return end

    self.parent = self:GetParent()

    self.direction = Vector(kv.direction_x, kv.direction_y, 0):Normalized()
    self.speed = kv.speed
    self.distance = kv.distance
    self.traveled = 0


    self.wallDepth = kv.wall_depth or 0

    if self:ApplyHorizontalMotionController() == false then
        self:Destroy()
    end

end

function modifier_rasputin_low_kick_lunge:UpdateHorizontalMotion(unit, dt)

    if unit:IsStunned() or unit:IsNightmared() or unit:IsHexed() then
        self:Destroy()
        return
    end

    local step = self.speed * dt

    if self.traveled + step >= self.distance then
        step = self.distance - self.traveled
    end

    if step > 0 then

        local to = unit:GetAbsOrigin() + self.direction * step


        if self.wallDepth > 0
        and (not GridNav:IsTraversable(to) or GridNav:IsBlocked(to))
        then

            local past =
            RasputinClearPastObstacle(to, self.direction, self.wallDepth)

            if not past then

                self:Destroy()
                return
            end

            to = Vector(past.x, past.y, to.z)

        end

        unit:SetAbsOrigin(to)
        self.traveled = self.traveled + step

    end

    if self.traveled >= self.distance then
        self:Destroy()
    end

end

function modifier_rasputin_low_kick_lunge:OnHorizontalMotionInterrupted()

    if not IsServer() then return end

    if self:ApplyHorizontalMotionController() == false then
        self.interrupted = true
        self:Destroy()
    end

end

function modifier_rasputin_low_kick_lunge:OnDestroy()

    if not IsServer() then return end

    if not self.parent or self.parent:IsNull() then
        return
    end

    self.parent:RemoveHorizontalMotionController(self)

    if not self.interrupted then
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
    end

end
