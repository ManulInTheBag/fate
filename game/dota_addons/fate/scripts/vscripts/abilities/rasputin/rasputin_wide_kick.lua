require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

LinkLuaModifier("modifier_rasputin_wide_kick_knockback", "abilities/rasputin/rasputin_wide_kick", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_rasputin_wide_kick_lock", "abilities/rasputin/rasputin_wide_kick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_wide_kick_anim_lock", "abilities/rasputin/rasputin_wide_kick", LUA_MODIFIER_MOTION_NONE)

rasputin_wide_kick = class({})


local function FindEnemiesInCone(teamNumber, origin, direction, length, coneAngle, targetTeam, targetType, targetFlags, closeRadius)

    local halfAngle = math.rad(coneAngle / 2)
    local halfAngleCos = math.cos(halfAngle)


    local search = length

    if halfAngleCos > 0 then
        search = length / halfAngleCos
    end

    if closeRadius and closeRadius > search then
        search = closeRadius
    end

    local candidates = FindUnitsInRadius(
        teamNumber,
        origin,
        nil,
        search,
        targetTeam,
        targetType,
        targetFlags,
        FIND_ANY_ORDER,
        false
    )

    local results = {}

    for _,unit in pairs(candidates) do

        local toUnit = unit:GetAbsOrigin() - origin
        toUnit.z = 0

        local distance = toUnit:Length2D()

        if distance == 0 then

            -- стоит ровно в Распутине: считаем попаданием
            table.insert(results, unit)

        else

            local forward = direction:Dot(toUnit)

            local inCone =
            forward <= length
            and direction:Dot(toUnit:Normalized()) >= halfAngleCos

            -- ближний хитбокс: полукруг перед Распутиным. Сзади не бьёт -
            -- forward >= 0 отсекает всё, что за спиной
            local inClose =
            closeRadius
            and closeRadius > 0
            and distance <= closeRadius

            if forward >= 0 and (inCone or inClose) then

                table.insert(results, unit)

            end

        end

    end

    return results

end


local function IsDashing(unit)
    return unit:HasModifier("modifier_rasputin_dash_move")
        or unit:HasModifier("modifier_rasputin_rush")
end


function rasputin_wide_kick:GetCastPoint()
    return 0
end

function rasputin_wide_kick:CastFilterResult()

    local caster = self:GetCaster()


    if caster:HasModifier("modifier_rasputin_low_kick_dash") then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS

end

function rasputin_wide_kick:GetCustomCastError()
    return self.customCastError or "Cannot use while airborne from low kick"
end


-- способность POINT, поэтому движок спрашивает именно Location-фильтр
function rasputin_wide_kick:CastFilterResultLocation(location)

    local caster = self:GetCaster()

    if not caster or caster:IsNull() then
        return UF_FAIL_CUSTOM
    end


    -- предыдущий взмах ещё не закончился
    if caster:HasModifier("modifier_rasputin_wide_kick_lock")
    or caster:HasModifier("modifier_rasputin_wide_kick_anim_lock")
    then
        self.customCastError = "Sweeping Kick is not finished yet"
        return UF_FAIL_CUSTOM
    end


    if caster:HasModifier("modifier_rasputin_low_kick_dash") then
        self.customCastError = "Cannot use while airborne from low kick"
        return UF_FAIL_CUSTOM
    end

    self.customCastError = nil

    return UF_SUCCESS

end


function rasputin_wide_kick:GetCustomCastErrorLocation(location)
    return self.customCastError or "Cannot use right now"
end

function rasputin_wide_kick:OnSpellStart()

    local caster = self:GetCaster()

    local castDelay = self:GetSpecialValueFor("cast_delay")
    local hitboxDuration = self:GetSpecialValueFor("hitbox_duration")


    if RasputinIsReborn(caster) then
        castDelay = castDelay / self:GetSpecialValueFor("reborn_ult_delay_divisor")
        hitboxDuration = hitboxDuration
            * (1 - self:GetSpecialValueFor("reborn_ult_hitbox_cut_pct") / 100)
    end


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_wide_kick_lock",
        {
            duration = castDelay + hitboxDuration
        }
    )


    RasputinPlayGesture(caster, ACT_DOTA_CAST_ABILITY_6)


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_wide_kick_anim_lock",
        {
            duration = castDelay + hitboxDuration
        }
    )

    caster:EmitSound("rasputin_wide_kick_swing")


    local castOrigin = caster:GetAbsOrigin()
    local cursor = self:GetCursorPosition()

    local direction = (Vector(cursor.x, cursor.y, 0) - Vector(castOrigin.x, castOrigin.y, 0)):Normalized()

    if direction:Length2D() == 0 then
        direction = caster:GetForwardVector()
    end

    direction.z = 0
    direction = direction:Normalized()

    if not IsDashing(caster) then
        caster:SetForwardVector(direction)
    end

    local radius = self:GetSpecialValueFor("length")
    local coneAngle = self:GetSpecialValueFor("cone_angle")


    local indicatorFx = ParticleManager:CreateParticle(
        "particles/rasputin/rasputin_skill_mark_wide.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )

    ParticleManager:SetParticleShouldCheckFoW(indicatorFx, false)


    local halfAngle = math.rad(coneAngle / 2)

    local markerLength = radius
    local markerWidth = radius * math.tan(halfAngle)


    local function UpdateIndicator()
        local origin = caster:GetAbsOrigin()
        ParticleManager:SetParticleControl(indicatorFx, 0, origin)
        ParticleManager:SetParticleControl(indicatorFx, 1, origin)
        ParticleManager:SetParticleControl(indicatorFx, 2, origin + direction * markerLength)


        ParticleManager:SetParticleControl(indicatorFx, 3, Vector(markerWidth, 0, 0))
        ParticleManager:SetParticleControl(indicatorFx, 4, Vector(255, 255, 255))
        ParticleManager:SetParticleControl(indicatorFx, 6, Vector(1, 0, 0))
    end


    local indicatorLive = true

    local function DestroyIndicator()

        if not indicatorLive then return end

        indicatorLive = false

        ParticleManager:DestroyParticle(indicatorFx, true)
        ParticleManager:ReleaseParticleIndex(indicatorFx)

    end


    RasputinFollowParticle(
        UpdateIndicator,
        function()
            return indicatorLive and IsNotNull(caster) and caster:IsAlive()
        end,
        castDelay + hitboxDuration + 1
    )


    -- повторный каст отменяет предыдущий: иначе его индикатор и мах остаются висеть
    if caster.rwk_wide_kick_cancel then
        caster.rwk_wide_kick_cancel()
        caster.rwk_wide_kick_cancel = nil
    end

    caster.rwk_cast_seq = (caster.rwk_cast_seq or 0) + 1
    local castId = caster.rwk_cast_seq

    -- один токен на весь взмах: прямые попадания, полёт и цепочка
    local refundToken = "rasputin_wide_kick:" .. castId


    caster.rwk_active_wide_kick = castId
    caster.rwk_wide_kick_cancel = DestroyIndicator

    caster.rwk_launched = caster.rwk_launched or {}
    caster.rwk_launched[castId] = {}

    caster.rwk_chain_hit = caster.rwk_chain_hit or {}
    caster.rwk_chain_hit[castId] = {}


    local launchTime =
    self:GetSpecialValueFor("distance") / self:GetSpecialValueFor("speed")

    local setLifetime =
    castDelay
    + hitboxDuration
    + launchTime
    + self:GetSpecialValueFor("chain_push_duration")
    + 1

    Timers:CreateTimer(setLifetime, function()

        if not IsNotNull(caster) then return end

        if caster.rwk_launched then
            caster.rwk_launched[castId] = nil
        end

        if caster.rwk_chain_hit then
            caster.rwk_chain_hit[castId] = nil
        end

    end)

    local launchedSet = caster.rwk_launched[castId]

    local function CheckHits()

        local origin = caster:GetAbsOrigin()

        local enemies = FindEnemiesInCone(
            caster:GetTeamNumber(),
            origin,
            direction,
            radius,
            coneAngle,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            self:GetSpecialValueFor("close_radius")
        )


        local damage =
        RasputinScaleDamage(caster, self, self:GetSpecialValueFor("damage"))
        local distance = self:GetSpecialValueFor("distance")
        local speed = self:GetSpecialValueFor("speed")

        for _,enemy in pairs(enemies) do

            if not launchedSet[enemy] then

                launchedSet[enemy] = true

                RasputinGrantStack(caster, self, enemy, refundToken)

                caster:EmitSound("rasputin_wide_kick_hit")

                RasputinHitFx(enemy, nil, caster)

                ApplyDamage({
                    victim = enemy,
                    attacker = caster,
                    damage = damage,
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                })

                -- иммунный к кнокбеку получает только урон: ни полёта, ни стана, ни метки
                if not IsKnockbackImmune(enemy) then

                    enemy:AddNewModifier(
                        caster,
                        self,
                        "modifier_rasputin_wide_kick_knockback",
                        {
                            duration = distance / speed + 0.5,
                            dir_x = direction.x,
                            dir_y = direction.y,
                            distance = distance,
                            speed = speed,
                            cast_id = castId
                        }
                    )

                    enemy:AddNewModifier(
                        caster,
                        self,
                        "modifier_rasputin_wide_kick_target",
                        {
                            duration = distance / speed
                        }
                    )

                end

            end

        end

    end

    Timers:CreateTimer(castDelay, function()

        if not IsNotNull(caster) then return end


        if caster.rwk_active_wide_kick ~= castId then
            DestroyIndicator()
            return
        end

        if not caster:IsAlive() then
            DestroyIndicator()
            return
        end


        local kickFx = ParticleManager:CreateParticle(
            RasputinFx(caster, "particles/rasputin/rasputin_wide_kick.vpcf"),
            PATTACH_CUSTOMORIGIN,
            caster
        )


        local function UpdateKickFx()
            local origin = caster:GetAbsOrigin()
            ParticleManager:SetParticleControl(kickFx, 0, origin)
            ParticleManager:SetParticleControl(kickFx, 1, origin + direction * radius)


            RasputinAimSweep(kickFx, 0, direction)
            RasputinAimSweep(kickFx, 1, direction)


            ParticleManager:SetParticleControl(kickFx, 3, origin)
            RasputinAimParticle(kickFx, 3, direction)
        end

        local kickFxLive = true

        local function DestroyKickFx()
            if not kickFxLive then return end
            kickFxLive = false
            ParticleManager:ReleaseParticleIndex(kickFx)
        end


        caster.rwk_wide_kick_cancel = function()
            DestroyIndicator()
            DestroyKickFx()
        end

        RasputinFollowParticle(
            UpdateKickFx,
            function() return indicatorLive and IsNotNull(caster) and caster:IsAlive() end,
            hitboxDuration + 1
        )

        CheckHits()


        local elapsed = 0
        local checkInterval = 0.03

        Timers:CreateTimer(checkInterval, function()

            if not IsNotNull(caster) then return end

            if caster.rwk_active_wide_kick ~= castId then
                DestroyIndicator()
                DestroyKickFx()
                return
            end

            if not caster:IsAlive() then
                DestroyIndicator()
                DestroyKickFx()
                return
            end


            CheckHits()

            elapsed = elapsed + checkInterval


            if elapsed < hitboxDuration
            and caster:HasModifier("modifier_rasputin_wide_kick_lock")
            then
                return checkInterval
            end

            DestroyIndicator()
            DestroyKickFx()

        end)

    end)

end


local HIT_FX_PULLBACK = 40


modifier_rasputin_wide_kick_knockback = class({})

function modifier_rasputin_wide_kick_knockback:IsHidden() return true end
function modifier_rasputin_wide_kick_knockback:IsPurgable() return true end

function modifier_rasputin_wide_kick_knockback:OnCreated(kv)

    if not IsServer() then return end

    self.direction = Vector(kv.dir_x, kv.dir_y, 0):Normalized()
    self.distance = kv.distance
    self.speed = kv.speed
    self.castId = kv.cast_id

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.traveled = 0


    self:PlayHitFx()


    self.stackGranted = false


    if self.speed > 0 and self.distance > 0 then

        self:GetParent():AddNewModifier(
            self.caster,
            self.ability,
            "modifier_stunned",
            {
                duration = self.distance / self.speed
            }
        )

    end

    if self:ApplyHorizontalMotionController() == false then
        self:Destroy()
    end
end


function modifier_rasputin_wide_kick_knockback:OnRefresh(kv)

    if not IsServer() then return end

    self.direction = Vector(kv.dir_x, kv.dir_y, 0):Normalized()
    self.distance = kv.distance
    self.speed = kv.speed
    self.castId = kv.cast_id


    self.traveled = 0

    self.stopped = nil

    self:PlayHitFx()

end


function modifier_rasputin_wide_kick_knockback:PlayHitFx()

    if self.hitFx then
        ParticleManager:DestroyParticle(self.hitFx, false)
        ParticleManager:ReleaseParticleIndex(self.hitFx)
        self.hitFx = nil
    end


    self.hitFx = ParticleManager:CreateParticle(
        RasputinFx(self.caster, "particles/rasputin/rasputin_wide_kick_enemy.vpcf"),
        PATTACH_CUSTOMORIGIN,
        self:GetParent()
    )

    self:UpdateHitFx()

end


function modifier_rasputin_wide_kick_knockback:UpdateHitFx()

    if not self.hitFx then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end


    ParticleManager:SetParticleControl(
        self.hitFx,
        0,
        parent:GetAbsOrigin() - self.direction * HIT_FX_PULLBACK
    )

    RasputinAimParticle(self.hitFx, 0, self.direction)

end


function modifier_rasputin_wide_kick_knockback:GrantStackOnce()

    if self.stackGranted then return end

    self.stackGranted = true

    RasputinGrantStack(self.caster, self.ability, self:GetParent(), "rasputin_wide_kick:" .. tostring(self.castId))

end

function modifier_rasputin_wide_kick_knockback:UpdateHorizontalMotion(unit, dt)

    local oldPos = unit:GetAbsOrigin()
    local move = self.direction * self.speed * dt
    local newPos = oldPos + move

    if not GridNav:IsTraversable(newPos) or GridNav:IsBlocked(newPos) then


        local clearPos = self:FindClearPastObstacle(newPos)

        if clearPos then

            unit:SetAbsOrigin(clearPos)
            self.traveled = self.traveled + (clearPos - oldPos):Length2D()

        else

            self:ApplyWallStun(unit)
            self:Destroy()
            return

        end

    else

        unit:SetAbsOrigin(newPos)
        self.traveled = self.traveled + move:Length2D()

    end

    self:UpdateHitFx()

    self:CheckBystanders(unit)

    if self.traveled >= self.distance then
        self:Destroy()
    end
end

function modifier_rasputin_wide_kick_knockback:FindClearPastObstacle(blockedPos)

    local maxDepth = self.ability:GetSpecialValueFor("thin_wall_max_depth")
    local step = 50
    local steps = math.ceil(maxDepth / step)

    for i = 1, steps do

        local probe = blockedPos + self.direction * (step * i)

        if GridNav:IsTraversable(probe) and not GridNav:IsBlocked(probe) then
            return probe
        end

    end

    return nil

end

function modifier_rasputin_wide_kick_knockback:ApplyWallStun(unit)

    local ability = self.ability


    unit:EmitSound("rasputin_wallstun")

    self:GrantStackOnce()

    -- урон об стену растёт от уровня героя так же, как основной удар
    DoDamage(
        self.caster,
        unit,
        RasputinScaleDamage(self.caster, ability, ability:GetSpecialValueFor("wallstun_damage")),
        DAMAGE_TYPE_PHYSICAL,
        0,
        ability,
        false
    )

    unit:AddNewModifier(
        self.caster,
        ability,
        "modifier_stunned",
        {
            duration = ability:GetSpecialValueFor("wallstun_duration")
        }
    )

end

function modifier_rasputin_wide_kick_knockback:CheckBystanders(unit)

    local ability = self.ability

    local launchedSet =
    self.caster.rwk_launched
    and self.caster.rwk_launched[self.castId]

    local chainHitSet =
    self.caster.rwk_chain_hit
    and self.caster.rwk_chain_hit[self.castId]

    if not launchedSet or not chainHitSet then return end

    local bystanders = FindUnitsInRadius(
        self.caster:GetTeamNumber(),
        unit:GetAbsOrigin(),
        nil,
        ability:GetSpecialValueFor("chain_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _,enemy in pairs(bystanders) do


        if enemy ~= unit and not launchedSet[enemy] and not chainHitSet[enemy] then

            chainHitSet[enemy] = true

            RasputinHitFx(enemy, nil, self.caster)


            enemy:EmitSound("rasputin_flying_enemy_hit")


            RasputinGrantStack(self.caster, self.ability, enemy, "rasputin_wide_kick:" .. tostring(self.castId))

            -- подхваченный получает столько же, сколько прилетает от удара о стену
            local damage =
            RasputinScaleDamage(self.caster, ability, ability:GetSpecialValueFor("wallstun_damage"))

            ApplyDamage({
                victim = enemy,
                attacker = self.caster,
                damage = damage,
                damage_type = ability:GetAbilityDamageType(),
                ability = ability
            })

            local chainStun = ability:GetSpecialValueFor("chain_stun_duration")

            -- иммунный к кнокбеку получает только урон: ни полёта, ни стана, ни метки
            if not IsKnockbackImmune(enemy) then

                enemy:AddNewModifier(
                    self.caster,
                    ability,
                    "modifier_rasputin_wide_kick_target",
                    {
                        duration = chainStun
                    }
                )

                enemy:AddNewModifier(
                    self.caster,
                    ability,
                    "modifier_stunned",
                    {
                        duration = chainStun
                    }
                )


                local chainDistance = ability:GetSpecialValueFor("chain_push_distance")
                local chainDuration = ability:GetSpecialValueFor("chain_push_duration")

                enemy:AddNewModifier(
                    self.caster,
                    ability,
                    "modifier_rasputin_wide_kick_knockback",
                    {
                        duration = chainDuration + 0.5,
                        dir_x = self.direction.x,
                        dir_y = self.direction.y,
                        distance = chainDistance,
                        speed = chainDistance / chainDuration,
                        cast_id = self.castId
                    }
                )

            end

        end

    end

end

function modifier_rasputin_wide_kick_knockback:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

function modifier_rasputin_wide_kick_knockback:OnDestroy()

    if not IsServer() then return end


    if self.hitFx then
        ParticleManager:DestroyParticle(self.hitFx, false)
        ParticleManager:ReleaseParticleIndex(self.hitFx)
        self.hitFx = nil
    end

    self:GetParent():RemoveHorizontalMotionController(self)
    FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
end


modifier_rasputin_wide_kick_anim_lock = class({})

function modifier_rasputin_wide_kick_anim_lock:IsHidden() return true end
function modifier_rasputin_wide_kick_anim_lock:IsPurgable() return false end
function modifier_rasputin_wide_kick_anim_lock:RemoveOnDeath() return true end


modifier_rasputin_wide_kick_lock = class({})

function modifier_rasputin_wide_kick_lock:IsHidden() return true end
function modifier_rasputin_wide_kick_lock:IsPurgable() return false end
function modifier_rasputin_wide_kick_lock:RemoveOnDeath() return true end

function modifier_rasputin_wide_kick_lock:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end

function modifier_rasputin_wide_kick_lock:GetModifierDisableTurning()
    return 1
end

function modifier_rasputin_wide_kick_lock:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end
