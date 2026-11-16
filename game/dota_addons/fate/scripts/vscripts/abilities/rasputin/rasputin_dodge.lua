require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

rasputin_dodge = class({})

LinkLuaModifier("modifier_rasputin_dodge_stance", "abilities/rasputin/rasputin_dodge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dodge_immune", "abilities/rasputin/rasputin_dodge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dodge_leap", "abilities/rasputin/rasputin_dodge", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_barrier_new", "modifiers/modifier_barrier_new", LUA_MODIFIER_MOTION_NONE)


LinkLuaModifier("modifier_rasputin_finisher_counter", "abilities/rasputin/modifier_rasputin_finisher_counter", LUA_MODIFIER_MOTION_NONE)


function rasputin_dodge:CastFilterResult()

    local caster = self:GetCaster()


    if caster:HasModifier("modifier_rasputin_low_kick_dash") then
        self.customCastError = "Cannot use while airborne from low kick"
        return UF_FAIL_CUSTOM
    end


    if caster:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
        self.customCastError = "Cannot use during the ultimate"
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS

end


function rasputin_dodge:GetCustomCastError()
    return self.customCastError or "Cannot use while airborne from low kick"
end


RASPUTIN_DODGE_START_SOUND = "rasputin_dodge_start"
RASPUTIN_DODGE_PROC_SOUND = "rasputin_dodge_proc"


function rasputin_dodge:OnSpellStart()

    local caster = self:GetCaster()

    caster:EmitSound(RASPUTIN_DODGE_START_SOUND)

    local flash_particle = ParticleManager:CreateParticle(
        RasputinFx(caster, "particles/rasputin/rasputin_dodge_flash.vpcf"),
        PATTACH_POINT_FOLLOW,
        caster
    )

    ParticleManager:SetParticleControlEnt(
        flash_particle,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_right_eye",
        caster:GetAbsOrigin(),
        true
    )

    ParticleManager:ReleaseParticleIndex(flash_particle)

    local window = self:GetSpecialValueFor("dodge_window")


    caster:RemoveModifierByName("modifier_rasputin_dodge_leap")

    for _,name in ipairs({ "modifier_rasputin_dash_move", "modifier_rasputin_rush" }) do

        local mover = caster:FindModifierByName(name)

        if mover then
            mover.interrupted = true
            mover:Destroy()
        end

    end


    caster:Stop()


    self.chainToken = (self.chainToken or 0) + 1


    if (self.dodgesUsed or 0) == 0 then
        self.chainStart = GameRules:GetGameTime()
    end


    self.recastGapUntil =
    GameRules:GetGameTime() + self:GetSpecialValueFor("recast_window")


    local immune = caster:FindModifierByName("modifier_rasputin_dodge_immune")

    local delay = 0

    if immune then
        delay = immune:GetRemainingTime()
    end

    if delay and delay > 0 then

        local token = self.chainToken

        Timers:CreateTimer(delay, function()

            if not IsNotNull(self) or not IsNotNull(caster) then return end


            if self.chainToken ~= token then return end

            if not caster:IsAlive() then return end

            self:OpenWindow(caster, window)

        end)

        return

    end

    self:OpenWindow(caster, window)

end


function rasputin_dodge:OpenWindow(caster, window)


    self.recastGapUntil =
    GameRules:GetGameTime()
    + window
    + self:GetSpecialValueFor("recast_window")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_dodge_stance",
        {
            duration = window
        }
    )

end


function rasputin_dodge:PerformDodge(caster, threatOrigin, barrierAmount)

    caster:EmitSound(RASPUTIN_DODGE_PROC_SOUND)


    -- прок снимает стан с самого Распутина (как Charisma у Жанны)
    caster:RemoveModifierByName("modifier_stunned")

    local away

    if threatOrigin then
        away = caster:GetAbsOrigin() - threatOrigin
        away.z = 0
    end


    if not away or away:Length2D() == 0 then
        away = -caster:GetForwardVector()
        away.z = 0
    end

    away = away:Normalized()


    local angle = self:GetSpecialValueFor("dodge_angle")

    if RandomInt(0, 1) == 0 then
        angle = -angle
    end

    local rad = math.rad(angle)

    local direction = Vector(
        away.x * math.cos(rad) - away.y * math.sin(rad),
        away.x * math.sin(rad) + away.y * math.cos(rad),
        0
    ):Normalized()


    if threatOrigin then

        local toThreat = threatOrigin - caster:GetAbsOrigin()
        toThreat.z = 0

        if toThreat:Length2D() > 0 then
            caster:SetForwardVector(toThreat:Normalized())
        end

    end

    local distance = self:GetSpecialValueFor("dodge_distance")
    local duration = self:GetSpecialValueFor("dodge_duration")


    if RasputinIsReborn(caster) then
        duration = duration
            / (1 + self:GetSpecialValueFor("reborn_dash_speed_pct") / 100)
    end


    if not RasputinIsRooted(caster) then

        caster:InterruptMotionControllers(true)

        caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_dodge_leap",
            {
                duration = duration + 0.25,
                direction_x = direction.x,
                direction_y = direction.y,
                distance = distance,
                speed = distance / duration
            }
        )

    end


    -- барьер за проглоченный удар живёт ровно столько же, сколько сам скользящий уход
    if barrierAmount and barrierAmount > 0 then

        caster:AddNewModifier(
            caster,
            self,
            "modifier_barrier_new",
            {
                duration = duration,
                beforeBScroll = false,
                ShouldEndChannel = false,
                decreaseDamageOnProck = 0,
                shield_amount = barrierAmount,
                HasCounter = false
            }
        )

    end


    local immunity =
    duration * self:GetSpecialValueFor("leap_immunity_fraction")

    if immunity > 0 then

        caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_dodge_immune",
            {
                duration = immunity
            }
        )

    end


    if caster.IsRasputinCombatMovementAcquired then
        caster:GiveMana(self:GetManaCost(self:GetLevel()))
    end

    self:ResolveDodge(caster)

end


function rasputin_dodge:ResolveDodge(caster)

    if not self.dodgePending then return end

    self.dodgePending = nil

    self:GrantStack(caster)


    self.dodgesUsed = (self.dodgesUsed or 0) + 1

    if self.dodgesUsed < self:GetSpecialValueFor("max_dodges") then
        self:EndCooldown()
        self:StartChainWatch()
    else
        self:EndDodgeChain()
    end

end


function rasputin_dodge:StartChainWatch()

    self.chainToken = (self.chainToken or 0) + 1

    local token = self.chainToken

    Timers:CreateTimer(self:GetSpecialValueFor("recast_window"), function()

        if not IsNotNull(self) then return end


        if self.chainToken ~= token then return end

        local caster = self:GetCaster()


        if not IsNotNull(caster) then
            self.dodgesUsed = 0
            return
        end


        if caster:HasModifier("modifier_rasputin_dodge_stance") then
            return
        end

        self:EndDodgeChain()

    end)

end


function rasputin_dodge:EndDodgeChain()

    self.dodgesUsed = 0


    self.chainToken = (self.chainToken or 0) + 1


    local refreshed = RasputinWasRefreshed(self, self.chainStart or 0)


    local cooldown =
    self:GetCooldown(self:GetLevel())
    * self:GetCaster():GetCooldownReduction()
    - (self.bankedCooldownRefund or 0)

    self.bankedCooldownRefund = nil
    self.recastGapUntil = nil
    self.chainStart = nil

    self:EndCooldown()

    if refreshed then
        self.rasputinRefreshedAt = nil
        return
    end

    if cooldown > 0 then
        self:StartCooldown(cooldown)
    end

end


function rasputin_dodge:GrantStack(caster)

    RasputinGrantStack(caster, self)

end


modifier_rasputin_dodge_stance = class({})

function modifier_rasputin_dodge_stance:IsHidden() return false end
function modifier_rasputin_dodge_stance:IsPurgable() return false end
function modifier_rasputin_dodge_stance:IsDebuff() return false end
function modifier_rasputin_dodge_stance:RemoveOnDeath() return true end

function modifier_rasputin_dodge_stance:GetTexture()
    return "custom/rasputin/rasputin_dodge"
end


function modifier_rasputin_dodge_stance:OnCreated(kv)

    if not IsServer() then return end

    self.triggered = false


    RasputinPlayGesture(self:GetParent(), ACT_DOTA_CHANNEL_ABILITY_6, 0)

end


function modifier_rasputin_dodge_stance:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }

end


function modifier_rasputin_dodge_stance:GetModifierDisableTurning()
    return 1
end


function modifier_rasputin_dodge_stance:CheckState()

    return {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
    }

end


-- Порог срабатывания: мелкие тычки стойку не тратят, средний удар гасится целиком
-- и превращается в барьер, а всё, что больше верхнего порога, просто срезается на него.
-- Снятие модификатора и рывок нельзя делать прямо здесь (движок идёт по модификаторам
-- текущего урона), поэтому они уезжают в таймер, как у modifier_barrier_new.
function modifier_rasputin_dodge_stance:GetModifierIncomingDamageConstant(keys)

    if not IsServer() then return 0 end

    if self.triggered then return 0 end


    local ability = self:GetAbility()

    if not IsNotNull(ability) then return 0 end


    local damage = keys.damage or 0

    if damage <= 0 then return 0 end


    local minDamage = ability:GetSpecialValueFor("min_damage")
    local maxDamage = ability:GetSpecialValueFor("max_damage")


    -- слабый урон стойку не проковывает и проходит как есть
    if damage < minDamage then return 0 end


    self.triggered = true

    ability.dodgePending = true


    local attacker = keys.attacker

    if IsNotNull(attacker) and attacker ~= self:GetParent() then
        self.threatOrigin = attacker:GetAbsOrigin()
    end


    local blocked
    local barrierAmount

    if damage <= maxDamage then
        blocked = damage
        barrierAmount = maxDamage - damage
    else
        blocked = maxDamage
        barrierAmount = nil
    end


    local parent = self:GetParent()
    local threatOrigin = self.threatOrigin

    Timers:CreateTimer(FrameTime(), function()

        if not IsNotNull(parent) or not IsNotNull(ability) then
            return
        end

        parent:RemoveModifierByName("modifier_rasputin_dodge_stance")

        ability:PerformDodge(parent, threatOrigin, barrierAmount)

    end)


    return -blocked

end


function modifier_rasputin_dodge_stance:OnDestroy()

    if not IsServer() then return end


    RasputinStopGesture(self:GetParent(), ACT_DOTA_CHANNEL_ABILITY_6)

    local ability = self:GetAbility()


    if self.triggered then


        Timers:CreateTimer(FrameTime() * 2, function()

            if not IsNotNull(ability) then return end

            local caster = ability:GetCaster()

            if not IsNotNull(caster) then return end

            ability:ResolveDodge(caster)

        end)

        return

    end

    if IsNotNull(ability) then
        ability:EndDodgeChain()
    end

end


modifier_rasputin_dodge_leap = class({})

function modifier_rasputin_dodge_leap:IsHidden() return true end
function modifier_rasputin_dodge_leap:IsPurgable() return false end


function modifier_rasputin_dodge_leap:OnCreated(kv)

    if not IsServer() then return end

    self.parent = self:GetParent()

    self.direction = Vector(kv.direction_x, kv.direction_y, 0):Normalized()
    self.speed = kv.speed
    self.distance = kv.distance
    self.traveled = 0


    RasputinPlayGesture(self.parent, ACT_DOTA_CAST_ABILITY_7, 0)


    local parent = self:GetParent()

    RasputinBackDashFx(
        parent,
        function()
            return parent:HasModifier("modifier_rasputin_dodge_leap")
        end,
        self.direction
    )

    if self:ApplyHorizontalMotionController() == false then
        self:Destroy()
    end

end


function modifier_rasputin_dodge_leap:UpdateHorizontalMotion(unit, dt)

    local step = self.speed * dt

    if self.traveled + step >= self.distance then
        step = self.distance - self.traveled
    end

    if step > 0 then

        local to = unit:GetAbsOrigin() + self.direction * step


        if not GridNav:IsTraversable(to) or GridNav:IsBlocked(to) then
            self:Destroy()
            return
        end

        unit:SetAbsOrigin(to)
        self.traveled = self.traveled + step

    end

    if self.traveled >= self.distance then
        self:Destroy()
    end

end


function modifier_rasputin_dodge_leap:OnHorizontalMotionInterrupted()

    if not IsServer() then return end


    self.interrupted = true
    self:Destroy()

end


function modifier_rasputin_dodge_leap:OnDestroy()

    if not IsServer() then return end

    if not IsNotNull(self.parent) then
        return
    end

    RasputinStopGesture(self.parent, ACT_DOTA_CAST_ABILITY_7)

    self.parent:RemoveHorizontalMotionController(self)


    if not self.interrupted then
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
    end

end


function modifier_rasputin_dodge_leap:CheckState()

    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

end


modifier_rasputin_dodge_immune = class({})

function modifier_rasputin_dodge_immune:IsHidden() return false end
function modifier_rasputin_dodge_immune:IsPurgable() return false end
function modifier_rasputin_dodge_immune:IsDebuff() return false end
function modifier_rasputin_dodge_immune:RemoveOnDeath() return true end


function modifier_rasputin_dodge_immune:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_AVOID_DAMAGE,
    }

end


function modifier_rasputin_dodge_immune:GetModifierAvoidDamage()

    return 1

end
