require('abilities/rasputin/rasputin_gesture')

modifier_rasputin_knife_grab = class({})


LinkLuaModifier(
    "modifier_rasputin_wide_kick_target",
    "abilities/rasputin/modifier_rasputin_wide_kick_target",
    LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)


function modifier_rasputin_knife_grab:IsHidden() return true end
function modifier_rasputin_knife_grab:IsPurgable() return false end
function modifier_rasputin_knife_grab:RemoveOnDeath() return true end


function modifier_rasputin_knife_grab:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_knife_grab:GetModifierProvidesFOWVision()
    return 1
end


function modifier_rasputin_knife_grab:OnCreated(kv)

    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    self.isVictim = kv.is_victim == 1


    if not self.isVictim then

        local shared = self:GetCaster()

        if IsNotNull(shared) then
            shared.rasputin_grab_blocked = nil
        end

    end
    self.victim = EntIndexToHScript(kv.victim_index)

    self.duration = kv.grab_duration


    self.heroLand = kv.hero_land_fraction
    self.apex = self.heroLand * 0.5

    self.height = kv.height

    if self.isVictim then
        self.height = kv.victim_height
    end

    self.startPos = self.parent:GetAbsOrigin()
    self.groundZ = self.startPos.z


    self.destPos = Vector(kv.dest_x, kv.dest_y, self.startPos.z)


    self.parent:AddNewModifier(
        self:GetCaster(),
        self.ability,
        "modifier_kb_immune",
        {
            duration = self.duration
        }
    )


    self.elapsed = 0
    self.tick = { 0, 0, 0 }

    if self:ApplyHorizontalMotionController() == false then
        self:Destroy()
        return
    end

    if self:ApplyVerticalMotionController() == false then
        self:Destroy()
        return
    end

end


function modifier_rasputin_knife_grab:SyncTime(iAxis, dt)

    if self.tick[2] == self.tick[3] then
        self.tick[1] = self.tick[1] + 1
        self.elapsed = self.elapsed + dt
    end

    self.tick[iAxis] = self.tick[1]

end


function modifier_rasputin_knife_grab:GetProgress()

    if not self.duration or self.duration <= 0 then
        return 1
    end

    local t = self.elapsed / self.duration

    if t > 1 then
        t = 1
    end

    return t

end


function modifier_rasputin_knife_grab:GetLegProgress()

    local t = self:GetProgress()

    if not self.isVictim then

        if not self.heroLand or self.heroLand <= 0 then
            return 1
        end

        local heroProgress = t / self.heroLand

        if heroProgress > 1 then
            heroProgress = 1
        end

        return heroProgress

    end


    if t <= self.apex then
        return 0
    end

    local span = 1 - self.apex

    if span <= 0 then
        return 1
    end

    return (t - self.apex) / span

end


function modifier_rasputin_knife_grab:UpdateHorizontalMotion(unit, dt)

    self:SyncTime(2, dt)

    local pos =
    self.startPos
    + (self.destPos - self.startPos) * self:GetLegProgress()

    pos = Vector(pos.x, pos.y, unit:GetAbsOrigin().z)


    local shared = self:GetCaster()

    if self.stopped or (IsNotNull(shared) and shared.rasputin_grab_blocked) then
        self.stopped = true
        return
    end

    if not GridNav:IsTraversable(pos) or GridNav:IsBlocked(pos) then

        local direction = self.destPos - self.startPos
        direction.z = 0

        if direction:Length2D() > 0 then

            local past =
            RasputinClearPastObstacle(pos, direction:Normalized())

            if past then
                pos = Vector(past.x, past.y, pos.z)
            else
                self.stopped = true

                if IsNotNull(shared) then
                    shared.rasputin_grab_blocked = true
                end

                return
            end

        else

            self.stopped = true

            if IsNotNull(shared) then
                shared.rasputin_grab_blocked = true
            end

            return

        end

    end

    unit:SetAbsOrigin(pos)

end


function modifier_rasputin_knife_grab:UpdateVerticalMotion(unit, dt)

    self:SyncTime(3, dt)


    if self.stopped then

        local origin = unit:GetAbsOrigin()

        unit:SetAbsOrigin(Vector(origin.x, origin.y, self.groundZ))

        return

    end

    local origin = unit:GetAbsOrigin()

    unit:SetAbsOrigin(
        Vector(
            origin.x,
            origin.y,
            self.groundZ
            + self.height * math.sin(math.pi * self:GetLegProgress())
        )
    )

end


function modifier_rasputin_knife_grab:OnHorizontalMotionInterrupted()

    if not IsServer() then return end

    self:Destroy()

end


function modifier_rasputin_knife_grab:OnVerticalMotionInterrupted()

    if not IsServer() then return end

    self:Destroy()

end


function modifier_rasputin_knife_grab:CheckState()

    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

end


function modifier_rasputin_knife_grab:OnDestroy()

    if not IsServer() then return end

    if not IsNotNull(self.parent) then return end

    self.parent:InterruptMotionControllers(true)

    FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)

    if not self.isVictim then
        self:DealSlamDamage()
    end

end


function modifier_rasputin_knife_grab:DealSlamDamage()

    local caster = self.parent
    local victim = self.victim
    local ability = self.ability

    if not IsNotNull(victim) or not IsNotNull(ability) then return end


    local missing = (100 - victim:GetHealthPercent()) / 100

    local damage =
    RasputinScaleDamage(caster, ability, ability:GetSpecialValueFor("damage2"))
    * (1 + missing)
    * ability:GetSpecialValueFor("grab_damage_multiplier")

    local impact = victim:GetAbsOrigin()


    RasputinSlam(caster, impact, ability:GetSpecialValueFor("grab_radius"))


    ability:DamageShields(victim)

    RasputinHitFx(victim, nil, caster)

    DoDamage(caster, victim, damage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)


    local stunAfter = ability:GetSpecialValueFor("grab_stun_after")

    if stunAfter > 0 then

        victim:AddNewModifier(
            caster,
            ability,
            "modifier_stunned",
            {
                duration = stunAfter
            }
        )

    end


    local markDuration = ability:GetSpecialValueFor("grab_mark_duration")


    local nearby = FindUnitsInRadius(
        caster:GetTeamNumber(),
        impact,
        nil,
        ability:GetSpecialValueFor("grab_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    if markDuration > 0 then

        victim:AddNewModifier(
            caster,
            ability,
            "modifier_rasputin_wide_kick_target",
            {
                duration = markDuration
            }
        )

    end

    for _,enemy in pairs(nearby) do

        if enemy ~= victim then

            RasputinHitFx(enemy, nil, caster)

            DoDamage(
                caster,
                enemy,
                damage,
                DAMAGE_TYPE_PHYSICAL,
                0,
                ability,
                false
            )


            if markDuration > 0 then

                enemy:AddNewModifier(
                    caster,
                    ability,
                    "modifier_rasputin_wide_kick_target",
                    {
                        duration = markDuration
                    }
                )

            end

        end

    end


    RasputinGrantStack(caster, ability, victim)

    EmitSoundOnLocationWithCaster(
        impact,
        "rasputin_knife_dash_recast_hit",
        caster
    )

end
