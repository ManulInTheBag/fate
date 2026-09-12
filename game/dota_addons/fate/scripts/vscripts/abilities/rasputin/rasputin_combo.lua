require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')


rasputin_combo = class({})

LinkLuaModifier("modifier_rasputin_combo_field", "abilities/rasputin/rasputin_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_combo_haul", "abilities/rasputin/rasputin_combo", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_rasputin_combo_cd", "abilities/rasputin/rasputin_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_curse", "abilities/rasputin/modifier_rasputin_curse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_reborn", "abilities/rasputin/rasputin_bk", LUA_MODIFIER_MOTION_NONE)


LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_3", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)


LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)


function rasputin_combo:Value(key)
    return self:GetLevelSpecialValueFor(key, 0)
end


local HAUL_CLAIM_GRACE = 0.6

local FALL_TRAIL_LINGER = 0.1


modifier_rasputin_combo_cd = class({})

function modifier_rasputin_combo_cd:GetTexture()
    return "custom/rasputin/rasputin_combo"
end

function modifier_rasputin_combo_cd:IsHidden() return false end
function modifier_rasputin_combo_cd:IsDebuff() return true end
function modifier_rasputin_combo_cd:IsPurgable() return false end
function modifier_rasputin_combo_cd:RemoveOnDeath() return false end

function modifier_rasputin_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function RasputinCurse(caster, ability, victim, amount)

    if not IsServer() then return end

    if not IsNotNull(victim) then return end

    if victim:IsMagicImmune() then return end

    local curse = victim:FindModifierByName("modifier_rasputin_curse")

    if not curse then

        if not amount or amount <= 0 then return end

        curse = victim:AddNewModifier(
            caster,
            ability,
            "modifier_rasputin_curse",
            {}
        )

    end

    if curse then
        curse:Feed(amount)
    end

end


function rasputin_combo:OnSpellStart()

    local caster = self:GetCaster()

    local duration = self:Value("duration")


    local targets = {}

    for _,enemy in pairs(self.targets or {}) do

        if IsNotNull(enemy) and enemy:IsAlive() then
            table.insert(targets, enemy)
        end

    end


    local anchor = caster:GetAbsOrigin()

    if #targets > 0 then

        local sum = Vector(0, 0, 0)

        for _,enemy in pairs(targets) do
            sum = sum + enemy:GetAbsOrigin()
        end

        anchor = sum / #targets

    end


    local ground = GetGroundPosition(anchor, caster).z

    local grail =
    Vector(anchor.x, anchor.y, ground + self:Value("grail_height"))

    local grailFx =
    Vector(anchor.x, anchor.y, ground + self:Value("grail_fx_height"))

    self.grail = grail

    caster:EmitSound("rasputin_finisher_end")


    if caster.IsRasputinBkCursesAcquired then

        caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_reborn",
            {
                duration = duration,
                no_death = 1,
            }
        )

    end

    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_combo_field",
        {
            duration = duration,
            x = grail.x,
            y = grail.y,
            z = grail.z,
            fx_z = grailFx.z,
        }
    )


    Timers:CreateTimer(self:Value("haul_delay"), function()

        if not IsNotNull(caster) then return end


        local finisher = caster:FindAbilityByName("rasputin_finisher")

        if finisher and not finisher:IsNull() and finisher.wallWatchers then
            finisher.wallWatchers.done = true
        end

        for _,enemy in pairs(targets) do

            if IsNotNull(enemy) and enemy:IsAlive() then

                enemy:RemoveModifierByName("modifier_knockback")
                enemy:InterruptMotionControllers(true)

                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_rasputin_combo_haul",
                    {
                        dest_x = grail.x,
                        dest_y = grail.y,
                        dest_z = grail.z,


                        duration =
                        self:Value("lift_rise_time")
                        + self:Value("lift_hang_time")
                        + self:Value("lift_fall_time")
                        + HAUL_CLAIM_GRACE
                        + 0.25,
                    }
                )

            end

        end

    end)

end


RASPUTIN_GRAIL_FORWARD = Vector(1, 0, 0)
RASPUTIN_GRAIL_RIGHT = Vector(0, 1, 0)
RASPUTIN_GRAIL_UP = Vector(0, 0, 1)

RASPUTIN_COMBO_FALL_PARTICLE =
"particles/rasputin/rasputin_combo_fall_trail.vpcf"

RASPUTIN_COMBO_SOUND = "rasputin_combo"
RASPUTIN_COMBO_AMBIENT = "rasputin_combo_ambient1"
RASPUTIN_COMBO_AMBIENT_END = "rasputin_combo_ambient_end"


local COMBO_AMBIENT_TAIL = 1

modifier_rasputin_combo_field = class({})

function modifier_rasputin_combo_field:IsHidden() return false end
function modifier_rasputin_combo_field:IsPurgable() return false end
function modifier_rasputin_combo_field:IsDebuff() return false end


function modifier_rasputin_combo_field:OnCreated(kv)

    if not IsServer() then return end

    self.grail = Vector(kv.x, kv.y, kv.z)


    self.grailFx = Vector(kv.x, kv.y, kv.fx_z)

    local ability = self:GetAbility()


    self:GetParent():EmitSound(RASPUTIN_COMBO_AMBIENT)


    local parent = self:GetParent()

    parent.rasputinComboAmbient = (parent.rasputinComboAmbient or 0) + 1

    self.ambientToken = parent.rasputinComboAmbient

    self.fx = ParticleManager:CreateParticle(
        "particles/kirei/kirei_dragon/kirei_dragon_ring_base.vpcf",
        PATTACH_CUSTOMORIGIN,
        self:GetParent()
    )


    ParticleManager:SetParticleShouldCheckFoW(self.fx, false)

    ParticleManager:SetParticleControl(self.fx, 0, self.grailFx)

    ParticleManager:SetParticleControlOrientation(
        self.fx,
        0,
        RASPUTIN_GRAIL_FORWARD,
        RASPUTIN_GRAIL_RIGHT,
        RASPUTIN_GRAIL_UP
    )


    local radius = ability:GetLevelSpecialValueFor("aura_radius", 0)
    local life = ability:GetLevelSpecialValueFor("duration", 0)

    self.groundFx = ParticleManager:CreateParticle(
        "particles/rasputin/rasputin_combo_territory.vpcf",
        PATTACH_CUSTOMORIGIN,
        self:GetParent()
    )

    ParticleManager:SetParticleShouldCheckFoW(self.groundFx, false)

    ParticleManager:SetParticleControl(
        self.groundFx,
        0,
        GetGroundPosition(self.grail, self:GetParent())
    )

    ParticleManager:SetParticleControl(
        self.groundFx,
        1,
        Vector(radius, life, 0)
    )

    self.tick = ability:GetLevelSpecialValueFor("curse_tick", 0)


    self.damageEvery = ability:GetLevelSpecialValueFor("field_damage_tick", 0)


    self.sinceDamage =
    self.damageEvery
    - ability:GetLevelSpecialValueFor("haul_delay", 0)

    self.elapsed = 0
    self.waveDelay = ability:GetLevelSpecialValueFor("wave_start_delay", 0)
    self.waveEvery = self.damageEvery
    self.sinceWave = self.waveEvery

    self:StartIntervalThink(self.tick)

end


function modifier_rasputin_combo_field:PlayWave()

    if not IsServer() then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    if not self.wavePlayed then
        self.wavePlayed = true
        parent:EmitSound(RASPUTIN_COMBO_SOUND)
    end

    local fx = ParticleManager:CreateParticle(
        "particles/rasputin/rasputin_combo_test.vpcf",
        PATTACH_CUSTOMORIGIN,
        parent
    )


    ParticleManager:SetParticleShouldCheckFoW(fx, false)

    ParticleManager:SetParticleControl(
        fx,
        0,
        GetGroundPosition(self.grail, parent)
    )

    ParticleManager:ReleaseParticleIndex(fx)

end


function modifier_rasputin_combo_field:OnIntervalThink()

    if not IsServer() then return end

    local ability = self:GetAbility()

    if not IsNotNull(ability) then return end

    local caster = self:GetCaster()

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        self.grail,
        nil,
        ability:GetLevelSpecialValueFor("aura_radius", 0),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    self.sinceDamage = self.sinceDamage + self.tick

    local burn = false

    if self.damageEvery > 0 and self.sinceDamage >= self.damageEvery then
        self.sinceDamage = self.sinceDamage - self.damageEvery
        burn = true
    end


    self.elapsed = self.elapsed + self.tick

    if self.elapsed >= self.waveDelay then

        self.sinceWave = self.sinceWave + self.tick

        if self.waveEvery > 0 and self.sinceWave >= self.waveEvery then
            self.sinceWave = self.sinceWave - self.waveEvery
            self:PlayWave()
        end

    end


    local perLevel = ability:GetLevelSpecialValueFor("curse_stacks_per_level", 0)
    local gainTime = ability:GetLevelSpecialValueFor("curse_gain_time", 0)

    local gain = 0

    if gainTime > 0 then
        gain = perLevel / gainTime * self.tick
    end

    for _,enemy in pairs(enemies) do


        if enemy:IsAlive()
        and not enemy:HasModifier("modifier_rasputin_combo_haul")
        then

            RasputinCurse(caster, ability, enemy, gain)

            if burn then

                DoDamage(
                    caster,
                    enemy,
                    ability:GetLevelSpecialValueFor("field_damage", 0),
                    DAMAGE_TYPE_PHYSICAL,
                    0,
                    ability,
                    false
                )

            end

        end

    end

end


function modifier_rasputin_combo_field:OnDestroy()

    if not IsServer() then return end


    for _,key in ipairs({ "fx", "groundFx" }) do

        if self[key] then
            ParticleManager:DestroyParticle(self[key], false)
            ParticleManager:ReleaseParticleIndex(self[key])
            self[key] = nil
        end

    end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end


    local token = self.ambientToken

    Timers:CreateTimer(COMBO_AMBIENT_TAIL, function()

        if not IsNotNull(parent) then return end


        if parent.rasputinComboAmbient ~= token then return end

        parent:StopSound(RASPUTIN_COMBO_AMBIENT)
        parent:EmitSound(RASPUTIN_COMBO_AMBIENT_END)

    end)

end


modifier_rasputin_combo_haul = class({})

function modifier_rasputin_combo_haul:IsHidden() return true end


function modifier_rasputin_combo_haul:IsPurgable() return false end
function modifier_rasputin_combo_haul:RemoveOnDeath() return true end

function modifier_rasputin_combo_haul:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_combo_haul:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_combo_haul:GetModifierProvidesFOWVision()
    return 1
end


function modifier_rasputin_combo_haul:Value(key)

    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return 0 end

    return ability:GetLevelSpecialValueFor(key, 0)

end


function modifier_rasputin_combo_haul:OnCreated(kv)

    if not IsServer() then return end

    self.parent = self:GetParent()

    self.dest = Vector(kv.dest_x, kv.dest_y, kv.dest_z)

    self.startPos = self.parent:GetAbsOrigin()
    self.groundZ = self.startPos.z

    self.rise = self:Value("lift_rise_time")
    self.hang = self:Value("lift_hang_time")
    self.fall = self:Value("lift_fall_time")


    local scatter = self:Value("lift_scatter")
    local scatterMin = self:Value("lift_scatter_min")

    if scatterMin > scatter then
        scatterMin = scatter
    end

    local angle = RandomFloat(0, 2 * math.pi)
    local reach = RandomFloat(scatterMin, scatter)

    self.landing =
    Vector(
        self.dest.x + math.cos(angle) * reach,
        self.dest.y + math.sin(angle) * reach,
        0
    )

    self.landing = GetGroundPosition(self.landing, self.parent)


    self.startedAt = nil

    self.damageTick = self:Value("hang_damage_tick")


    self.hangCurseRate = 0

    if self.hang > 0 then

        self.hangCurseRate =
        self:Value("curse_max_level")
        * self:Value("curse_stacks_per_level")
        / self.hang

    end


    self.kbImmune = self.parent:AddNewModifier(
        self:GetCaster(),
        self:GetAbility(),
        "modifier_kb_immune",
        {}
    )

    self:StartIntervalThink(self.damageTick)


    if self:TryStart() then return end


    local expire = GameRules:GetGameTime() + HAUL_CLAIM_GRACE

    Timers:CreateTimer(FrameTime(), function()

        if self:IsNull() or self.done then return end

        if not IsNotNull(self.parent) then return end


        if self.startedAt then return end

        if self:TryStart() then return end

        if GameRules:GetGameTime() >= expire then


            print("[RASPUTIN combo] haul could not take the motion controller")

            self:Finish()

            return

        end

        return FrameTime()

    end)

end


function modifier_rasputin_combo_haul:ClearMovers()

    if self.clearing then return end

    if not IsNotNull(self.parent) then return end

    self.clearing = true

    local guard = 0

    while self.parent:HasModifier("modifier_knockback") and guard < 8 do
        self.parent:RemoveModifierByName("modifier_knockback")
        guard = guard + 1
    end

    self.parent:InterruptMotionControllers(true)

    self.clearing = false

end


function modifier_rasputin_combo_haul:TryStart()

    if not IsServer() then return false end

    if not IsNotNull(self.parent) then return false end

    self:ClearMovers()

    if not self:Claim() then return false end


    self.startedAt = GameRules:GetGameTime()

    return true

end


function modifier_rasputin_combo_haul:Claim()

    if not IsServer() then return false end

    if self:ApplyHorizontalMotionController() == false then
        return false
    end

    if self:ApplyVerticalMotionController() == false then

        if IsNotNull(self.parent) then
            self.parent:RemoveHorizontalMotionController(self)
        end

        return false

    end

    return true

end


function modifier_rasputin_combo_haul:Elapsed()

    if not self.startedAt then return 0 end

    local t = GameRules:GetGameTime() - self.startedAt

    if t < 0 then return 0 end

    return t

end


function modifier_rasputin_combo_haul:Length()
    return (self.rise or 0) + (self.hang or 0) + (self.fall or 0)
end


function modifier_rasputin_combo_haul:Finish()

    if self.done then return end

    self.done = true

    Timers:CreateTimer(0, function()

        if self:IsNull() then return end

        self:Destroy()

    end)

end


function modifier_rasputin_combo_haul:CheckState()

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


function modifier_rasputin_combo_haul:OnIntervalThink()

    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()

    if not IsNotNull(ability) or not IsNotNull(caster) then return end

    if not IsNotNull(self.parent) or not self.parent:IsAlive() then return end

    local elapsed = self:Elapsed()


    if elapsed >= self:Length() then
        self:Finish()
        return
    end

    if elapsed < self.rise
    or elapsed > self.rise + self.hang
    then
        RasputinCurse(caster, ability, self.parent, 0)
        return
    end

    RasputinCurse(
        caster,
        ability,
        self.parent,
        self.hangCurseRate * self.damageTick
    )

    RasputinHitFx(self.parent, nil, caster)

    DoDamage(
        caster,
        self.parent,
        self:Value("hang_damage"),
        DAMAGE_TYPE_PHYSICAL,
        DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
        ability,
        false
    )

end


function modifier_rasputin_combo_haul:Sample()

    local t = self:Elapsed()

    if t < self.rise then

        local p = self.rise > 0 and (t / self.rise) or 1


        local drawn = p * p

        return drawn, drawn, false

    end

    t = t - self.rise

    if t < self.hang then
        return 1, 1, true
    end

    t = t - self.hang

    local q = self.fall > 0 and (t / self.fall) or 1

    if q > 1 then
        q = 1
    end


    return 1 - q * q, 1, true

end


function modifier_rasputin_combo_haul:UpdateHorizontalMotion(unit, dt)

    local _, drawn, dropping = self:Sample()

    local from = self.startPos
    local to = self.dest

    if dropping then
        from = self.dest
        to = self.landing

        local t = self:Elapsed() - self.rise - self.hang

        local q = self.fall > 0 and math.min(t / self.fall, 1) or 1

        if q < 0 then
            q = 0
        end

        drawn = 1 - (1 - q) * (1 - q)

        if t >= 0 and not self.fallFx then

            self.fallFx = ParticleManager:CreateParticle(
                RASPUTIN_COMBO_FALL_PARTICLE,
                PATTACH_CUSTOMORIGIN,
                unit
            )

            ParticleManager:SetParticleControl(
                self.fallFx,
                0,
                unit:GetAbsOrigin()
            )

            ParticleManager:SetParticleControlEnt(
                self.fallFx,
                3,
                unit,
                PATTACH_POINT_FOLLOW,
                "attach_hitloc",
                unit:GetAbsOrigin(),
                true
            )

            ParticleManager:SetParticleShouldCheckFoW(self.fallFx, false)

        end
    end

    local pos = from + (to - from) * drawn

    unit:SetAbsOrigin(Vector(pos.x, pos.y, unit:GetAbsOrigin().z))

    if self:Elapsed() >= self:Length() then
        self:Finish()
    end

end


function modifier_rasputin_combo_haul:UpdateVerticalMotion(unit, dt)

    local height = self:Sample()

    local origin = unit:GetAbsOrigin()

    local top = self.dest.z - self.groundZ

    unit:SetAbsOrigin(
        Vector(origin.x, origin.y, self.groundZ + top * height)
    )


    if self:Elapsed() >= self:Length() then
        self:Finish()
    end

end


function modifier_rasputin_combo_haul:Reclaim()


    if not IsServer() then return end

    if not self.rise then return end


    if self:Elapsed() >= self:Length() then
        self:Finish()
        return
    end


    self:ClearMovers()

    if not self:Claim() then
        self:Finish()
    end

end


function modifier_rasputin_combo_haul:ScheduleReclaim()

    if not IsServer() then return end

    if self.done or self.reclaimQueued then return end

    self.reclaimQueued = true

    Timers:CreateTimer(FrameTime(), function()

        if self:IsNull() then return end

        self.reclaimQueued = false

        if self.done then return end

        self:Reclaim()

    end)

end


function modifier_rasputin_combo_haul:OnHorizontalMotionInterrupted()
    self:ScheduleReclaim()
end


function modifier_rasputin_combo_haul:OnVerticalMotionInterrupted()
    self:ScheduleReclaim()
end


function modifier_rasputin_combo_haul:OnDestroy()

    if not IsServer() then return end

    self.done = true


    if self.kbImmune and not self.kbImmune:IsNull() then
        self.kbImmune:Destroy()
    end

    if self.fallFx then

        local fx = self.fallFx

        self.fallFx = nil

        Timers:CreateTimer(FALL_TRAIL_LINGER, function()
            ParticleManager:DestroyParticle(fx, false)
            ParticleManager:ReleaseParticleIndex(fx)
        end)

    end

    self.kbImmune = nil

    if not IsNotNull(self.parent) then return end

    self.parent:InterruptMotionControllers(true)


    local at = self.parent:GetAbsOrigin()

    self.parent:SetAbsOrigin(GetGroundPosition(at, self.parent))

    FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)

end
