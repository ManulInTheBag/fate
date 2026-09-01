RASPUTIN_ACTIVITIES = {
    ACT_DOTA_CAST_ABILITY_1,
    ACT_DOTA_CAST_ABILITY_2,
    ACT_DOTA_CAST_ABILITY_3,
    ACT_DOTA_CAST_ABILITY_4,
    ACT_DOTA_CAST_ABILITY_5,
    ACT_DOTA_CAST_ABILITY_6,
    ACT_DOTA_CAST_ABILITY_7,
    ACT_DOTA_OVERRIDE_ABILITY_1,
    ACT_DOTA_OVERRIDE_ABILITY_2,
    ACT_DOTA_OVERRIDE_ABILITY_4,
    ACT_DOTA_ATTACK2,
    ACT_DOTA_CHANNEL_ABILITY_1,
    ACT_DOTA_CHANNEL_ABILITY_6,
    ACT_DOTA_ATTACK,
}


do

    local checked = {}

    for _,act in pairs(RASPUTIN_ACTIVITIES) do
        if act then
            table.insert(checked, act)
        end
    end

    if #checked ~= #RASPUTIN_ACTIVITIES then
        print("[RASPUTIN] an activity constant is nil - check RASPUTIN_ACTIVITIES")
    end

    RASPUTIN_ACTIVITIES = checked

end


RASPUTIN_CLIP = {
    [ACT_DOTA_CAST_ABILITY_1]     = 1.70,
    [ACT_DOTA_CAST_ABILITY_2]     = 1.10,
    [ACT_DOTA_CAST_ABILITY_4]     = 0.60,
    [ACT_DOTA_CAST_ABILITY_5]     = 0.80,
    [ACT_DOTA_CAST_ABILITY_6]     = 1.35,
    [ACT_DOTA_OVERRIDE_ABILITY_1] = 0.65,
    [ACT_DOTA_OVERRIDE_ABILITY_2] = 1.40,


    [ACT_DOTA_OVERRIDE_ABILITY_3] = 1.32,
    [ACT_DOTA_ATTACK]             = 1.30,
}


RASPUTIN_KICK_ACTIVITIES = {
    ACT_DOTA_CAST_ABILITY_2,
    ACT_DOTA_CAST_ABILITY_4,
    ACT_DOTA_OVERRIDE_ABILITY_1,
}


local function ClearAll(unit)

    for _,act in ipairs(RASPUTIN_ACTIVITIES) do
        unit:RemoveGesture(act)
    end

end


function RasputinPlayGesture(unit, activity, length, rate)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if not activity then return end

    if length == nil then
        length = RASPUTIN_CLIP[activity]
    end

    if not rate or rate <= 0 then
        rate = 1
    end

    ClearAll(unit)


    unit.rasputin_gesture_until = {}

    unit:StartGestureWithPlaybackRate(activity, rate)

    if not length or length <= 0 then return end

    unit.rasputin_gesture_seq = unit.rasputin_gesture_seq or {}

    unit.rasputin_gesture_seq[activity] =
    (unit.rasputin_gesture_seq[activity] or 0) + 1

    local seq = unit.rasputin_gesture_seq[activity]


    unit.rasputin_gesture_until[activity] = GameRules:GetGameTime() + length

    Timers:CreateTimer(length, function()

        if not IsNotNull(unit) then return end

        if not unit.rasputin_gesture_seq then return end

        if unit.rasputin_gesture_seq[activity] ~= seq then return end

        if unit.rasputin_gesture_until then
            unit.rasputin_gesture_until[activity] = nil
        end

        unit:RemoveGesture(activity)

    end)

end


function RasputinStopGesture(unit, activity)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if unit.rasputin_gesture_seq and unit.rasputin_gesture_seq[activity] then

        unit.rasputin_gesture_seq[activity] =
        unit.rasputin_gesture_seq[activity] + 1

    end

    if unit.rasputin_gesture_until then
        unit.rasputin_gesture_until[activity] = nil
    end

    unit:RemoveGesture(activity)

end


function RasputinBusyGestureRemaining(unit)

    if not IsServer() then return 0 end

    if not IsNotNull(unit) then return 0 end

    if not unit.rasputin_gesture_until then return 0 end

    local now = GameRules:GetGameTime()
    local longest = 0

    for _,act in ipairs(RASPUTIN_KICK_ACTIVITIES) do

        local until_ = unit.rasputin_gesture_until[act]

        if until_ then

            local left = until_ - now

            if left > longest then
                longest = left
            end

        end

    end

    return longest

end


RASPUTIN_OWN_ROOTS = {
    "modifier_rasputin_low_kick_root",
    "modifier_rasputin_wide_kick_lock",
}


function RasputinIsRooted(unit)

    if not unit or unit:IsNull() then return false end

    if not unit:IsRooted() then return false end

    for _,name in ipairs(RASPUTIN_OWN_ROOTS) do
        if unit:HasModifier(name) then
            return false
        end
    end

    return true

end


RASPUTIN_DEATH_CANCEL_MODIFIERS = {
    "modifier_rasputin_finisher_channel",
    "modifier_rasputin_rush",
    "modifier_rasputin_knife_grab",
    "modifier_rasputin_low_kick_dash",
    "modifier_rasputin_low_kick_lunge",
    "modifier_rasputin_low_kick_root",
    "modifier_rasputin_low_kick_disarm",
}


function RasputinCancelAll(unit)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    RasputinCancelWideKick(unit)

    for _,name in ipairs(RASPUTIN_DEATH_CANCEL_MODIFIERS) do

        local modifier = unit:FindModifierByName(name)

        if modifier then
            modifier.interrupted = true
            modifier:Destroy()
        end

    end

    local finisher = unit:FindAbilityByName("rasputin_finisher")

    if finisher and not finisher:IsNull() and finisher.wallWatchers then
        finisher.wallWatchers.done = true
    end

    for _,act in ipairs(RASPUTIN_ACTIVITIES) do
        unit:RemoveGesture(act)
    end

end


function RasputinIsFacingLocked(unit)

    if not IsNotNull(unit) then return false end

    return unit:HasModifier("modifier_rasputin_wide_kick_lock")
        or unit:HasModifier("modifier_rasputin_wide_kick_anim_lock")

end


function RasputinCancelWideKick(unit)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if unit.rwk_active_wide_kick then

        unit.rwk_active_wide_kick = nil

        if unit.rwk_wide_kick_cancel then
            unit.rwk_wide_kick_cancel()
            unit.rwk_wide_kick_cancel = nil
        end

    end

    unit:RemoveModifierByName("modifier_rasputin_wide_kick_lock")
    unit:RemoveModifierByName("modifier_rasputin_wide_kick_anim_lock")

end


-- Токен каста: одно попадание способностью = одно сокращение кулдаунов,
-- сколько бы целей она ни задела
function RasputinCastToken(ability)

    if not IsNotNull(ability) then return nil end

    ability.rasputinCastSeq = (ability.rasputinCastSeq or 0) + 1

    return ability:GetAbilityName() .. ":" .. ability.rasputinCastSeq

end


function RasputinGrantStack(caster, ability, victim, castToken)

    if not IsServer() then return end

    if not IsNotNull(caster) then return end


    -- за попадание по крипу стак не даётся; крип-герой (иллюзии, призванные
    -- герои вроде солдат Искандера) считается целью
    if victim and IsNotNull(victim) and not victim:IsHero() then return end


    if _G.CurrentGameState == "FATE_POST_ROUND" then return end

    local counter =
    caster:FindModifierByName("modifier_rasputin_finisher_counter")


    if not counter then

        local owner =
        caster:FindAbilityByName("rasputin_finisher")
        or ability

        if IsNotNull(owner) then

            counter =
            caster:AddNewModifier(
                caster,
                owner,
                "modifier_rasputin_finisher_counter",
                {}
            )

        end

    end

    if not counter then return end

    counter:AddStack(castToken)

end


function RasputinOnSealRefresh(hero)

    if not IsServer() then return end

    if not IsNotNull(hero) then return end

    local now = GameRules:GetGameTime()

    -- rasputin_dodge сюда не входит: она в CannotReset, печать её не обновляет
    for _,name in ipairs({ "rasputin_knife_dash", "rasputin_low_kick" }) do

        local ability = hero:FindAbilityByName(name)

        if ability then
            ability.rasputinRefreshedAt = now
        end

    end


    RasputinClearGrabCooldown(hero)


    local charges = hero:FindModifierByName("modifier_rasputin_dash_charges")

    if charges then
        charges:SetStackCount(
            math.min(charges:GetStackCount() + 1, charges:GetMaxStackCount())
        )
    end

end


function RasputinWasRefreshed(ability, since)

    if not IsNotNull(ability) then return false end

    local at = ability.rasputinRefreshedAt

    if not at then return false end

    return at >= (since or 0)

end


RASPUTIN_SLAM_PARTICLE = "particles/rasputin/rasputin_slam.vpcf"


RASPUTIN_SWEEP_FLIP = -1


function RasputinAimParticle(fx, cp, direction)

    local forward = Vector(direction.x, direction.y, 0)

    if forward:Length2D() == 0 then return end

    forward = forward:Normalized()

    local up = Vector(0, 0, 1)


    local left = Vector(-forward.y, forward.x, 0)
    local right = Vector(forward.y, -forward.x, 0)


    ParticleManager:SetParticleControlOrientation(fx, cp, forward, right, up)

    if ParticleManager.SetParticleControlOrientationFLU then
        ParticleManager:SetParticleControlOrientationFLU(fx, cp, forward, left, up)
    end

end


function RasputinAimSweep(fx, cp, direction)

    RasputinAimParticle(fx, cp, direction * RASPUTIN_SWEEP_FLIP)

end


function RasputinFollowParticle(update, alive, duration, fx)

    if not IsServer() then return end

    update()

    local elapsed = 0

    local function Finish()

        if fx then
            ParticleManager:ReleaseParticleIndex(fx)
            fx = nil
        end

    end

    Timers:CreateTimer(FrameTime(), function()

        elapsed = elapsed + FrameTime()

        if duration and elapsed > duration then
            Finish()
            return
        end

        if alive and not alive() then
            Finish()
            return
        end

        update()

        return FrameTime()

    end)

end


RASPUTIN_GRAB_CD_MODIFIER = "modifier_rasputin_grab_cd"

LinkLuaModifier(RASPUTIN_GRAB_CD_MODIFIER, "abilities/rasputin/rasputin_gesture", LUA_MODIFIER_MOTION_NONE)

modifier_rasputin_grab_cd = class({})

function modifier_rasputin_grab_cd:IsHidden() return false end
function modifier_rasputin_grab_cd:IsDebuff() return true end
function modifier_rasputin_grab_cd:IsPurgable() return false end
function modifier_rasputin_grab_cd:RemoveOnDeath() return false end

function modifier_rasputin_grab_cd:GetTexture()
    return "custom/rasputin/rasputin_knife_dash_1"
end

function modifier_rasputin_grab_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function RasputinGrabReady(hero, ability)

    if not IsNotNull(hero) then return false end

    return not hero:HasModifier(RASPUTIN_GRAB_CD_MODIFIER)

end


function RasputinStartGrabCooldown(hero, ability)

    if not IsServer() then return end

    if not IsNotNull(hero) or not IsNotNull(ability) then return end

    local cooldown = ability:GetLevelSpecialValueFor("grab_cooldown", 0)

    local perLevel = ability:GetLevelSpecialValueFor("grab_cooldown_per_level", 0)

    if perLevel > 0 then

        cooldown = cooldown - hero:GetLevel() * perLevel

        local floor = ability:GetLevelSpecialValueFor("grab_cooldown_min", 0)

        if cooldown < floor then
            cooldown = floor
        end

    end

    if not cooldown or cooldown <= 0 then return end

    local owner = hero:FindAbilityByName("rasputin_knife_dash") or ability

    hero:AddNewModifier(
        hero,
        owner,
        RASPUTIN_GRAB_CD_MODIFIER,
        {
            duration = cooldown
        }
    )

end


function RasputinClearGrabCooldown(hero)

    if not IsServer() then return end

    if not IsNotNull(hero) then return end

    hero:RemoveModifierByName(RASPUTIN_GRAB_CD_MODIFIER)

end


RASPUTIN_FLURRY_ACTIVITIES = {
    ACT_DOTA_ATTACK,
    ACT_DOTA_ATTACK2,
    ACT_DOTA_CHANNEL_ABILITY_1,
    ACT_DOTA_CAST_ABILITY_2,
    ACT_DOTA_CAST_ABILITY_4,
}


do

    local checked = {}

    for _,act in pairs(RASPUTIN_FLURRY_ACTIVITIES) do
        if act then
            table.insert(checked, act)
        end
    end

    if #checked ~= #RASPUTIN_FLURRY_ACTIVITIES then
        print("[RASPUTIN] a flurry activity is nil - check RASPUTIN_FLURRY_ACTIVITIES")
    end

    RASPUTIN_FLURRY_ACTIVITIES = checked

end


RASPUTIN_FLURRY_RATE = 5


function RasputinPlayFlurryBlow(unit, hold)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if #RASPUTIN_FLURRY_ACTIVITIES == 0 then return end


    local pick = RASPUTIN_FLURRY_ACTIVITIES[
        RandomInt(1, #RASPUTIN_FLURRY_ACTIVITIES)
    ]

    if #RASPUTIN_FLURRY_ACTIVITIES > 1 then

        while pick == unit.rasputin_last_flurry do
            pick = RASPUTIN_FLURRY_ACTIVITIES[
                RandomInt(1, #RASPUTIN_FLURRY_ACTIVITIES)
            ]
        end

    end

    unit.rasputin_last_flurry = pick

    RasputinPlayGesture(unit, pick, hold, RASPUTIN_FLURRY_RATE)

    return pick

end


function RasputinWallStop(unit, duration, maxDepth, group, owner)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    maxDepth = maxDepth or 0

    local last = unit:GetAbsOrigin()
    local elapsed = 0

    local function Stop()

        unit:RemoveModifierByName("modifier_knockback")
        unit:InterruptMotionControllers(true)

        unit:SetAbsOrigin(last)

        FindClearSpaceForUnit(unit, last, true)

    end

    Timers:CreateTimer(0, function()

        if not IsNotNull(unit) then return end


        if owner and owner.done then return end

        elapsed = elapsed + FrameTime()

        if elapsed > duration then return end


        if group and group.blocked then
            Stop()
            return
        end

        local at = unit:GetAbsOrigin()

        if GridNav:IsTraversable(at) and not GridNav:IsBlocked(at) then
            last = at
            return FrameTime()
        end


        local past

        if maxDepth > 0 then

            local heading = at - last
            heading.z = 0

            if heading:Length2D() > 0 then
                past = RasputinClearPastObstacle(at, heading:Normalized(), maxDepth)
            end

        end

        if past then

            unit:SetAbsOrigin(Vector(past.x, past.y, at.z))

            last = unit:GetAbsOrigin()

            return FrameTime()

        end


        if group then
            group.blocked = true
        end

        Stop()

    end)

end


RASPUTIN_THIN_OBSTACLE = 100


function RasputinClearPastObstacle(from, direction, maxDepth)

    maxDepth = maxDepth or RASPUTIN_THIN_OBSTACLE

    local step = 25

    for i = 1, math.ceil(maxDepth / step) do

        local probe = from + direction * (step * i)

        if GridNav:IsTraversable(probe) and not GridNav:IsBlocked(probe) then
            return probe
        end

    end

    return nil

end


function RasputinRetreat(unit, direction, distance, duration)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if not distance or distance <= 0 then return end
    if not duration or duration <= 0 then return end

    local back = Vector(-direction.x, -direction.y, 0)

    if back:Length2D() == 0 then return end

    back = back:Normalized()

    local moved = 0


    local running = true


    RasputinBackDashFx(unit, function() return running end, back)


    local function Settle()

        running = false

        if not IsNotNull(unit) then return end

        if unit:HasModifier("modifier_rasputin_dash_move")
        or unit:HasModifier("modifier_rasputin_rush")
        or unit:HasModifier("modifier_rasputin_dodge_leap")
        then
            return
        end

        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)

    end

    Timers:CreateTimer(0, function()

        if not IsNotNull(unit) then
            running = false
            return
        end

        if not unit:IsAlive() then
            running = false
            return
        end

        local step = distance * FrameTime() / duration

        if moved + step > distance then
            step = distance - moved
        end

        if step <= 0 then
            running = false
            return
        end

        local to = unit:GetAbsOrigin() + back * step

        if not GridNav:IsTraversable(to) or GridNav:IsBlocked(to) then


            Settle()

            return

        end

        unit:SetAbsOrigin(to)

        moved = moved + step

        if moved >= distance then
            Settle()
            return
        end

        return FrameTime()

    end)

end


RASPUTIN_HIT_PARTICLE = "particles/rasputin/rasputin_hit.vpcf"


function RasputinHitFx(victim, spread, caster)

    if not IsServer() then return end

    if not IsNotNull(victim) then return end

    local fx = ParticleManager:CreateParticle(
        RasputinFx(caster, RASPUTIN_HIT_PARTICLE),
        PATTACH_POINT_FOLLOW,
        victim
    )

    if spread and spread > 0 then

        local attach = victim:ScriptLookupAttachment("attach_hitloc")

        local at = victim:GetAbsOrigin()

        if attach and attach > 0 then

            local origin = victim:GetAttachmentOrigin(attach)

            if origin and origin:Length() > 0 then
                at = origin
            end

        end

        ParticleManager:SetParticleControl(
            fx,
            3,
            at + Vector(
                RandomFloat(-spread, spread),
                RandomFloat(-spread, spread),
                RandomFloat(-spread, spread)
            )
        )

        ParticleManager:ReleaseParticleIndex(fx)

        return

    end


    ParticleManager:SetParticleControlEnt(
        fx,
        3,
        victim,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        victim:GetAbsOrigin(),
        true
    )

    ParticleManager:ReleaseParticleIndex(fx)

end


RASPUTIN_REBORN_FX = {}

do

    local copies = {
        "knife_throw",
        "rasputin_afterimage_test",


        "rasputin_afterimage_back",
        "rasputin_afterimage_fin_attack",
        "rasputin_afterimage_fin_attack2",
        "rasputin_afterimage_fin_channel1",
        "rasputin_afterimage_fin_cast2",
        "rasputin_afterimage_fin_cast4",
        "rasputin_dash_shield",
        "rasputin_dash_trail",
        "rasputin_dodge_flash",
        "rasputin_finisher_hit_enemy",
        "rasputin_finisher_hits",
        "rasputin_knife_dash_hit",
        "rasputin_knife_mark",
        "rasputin_low_kick_1",
        "rasputin_low_kick_2",
        "rasputin_max_stacks",
        "rasputin_skill_marker",
        "rasputin_slam",
        "rasputin_wide_kick",
        "rasputin_wide_kick_enemy",
    }

    for _,name in ipairs(copies) do

        RASPUTIN_REBORN_FX["particles/rasputin/" .. name .. ".vpcf"] =
            "particles/rasputin/" .. name .. "_bk.vpcf"

    end

end


function RasputinFx(unit, path)

    if not IsNotNull(unit) then return path end


    if not RasputinIsReborn then return path end

    if not RasputinIsReborn(unit) then return path end

    return RASPUTIN_REBORN_FX[path] or path

end


function RasputinSlam(unit, at, radius)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    local strike = at

    if not strike then

        local attach = unit:ScriptLookupAttachment("attach_attack2")

        if attach and attach > 0 then

            local origin = unit:GetAttachmentOrigin(attach)

            if origin and origin:Length() > 0 then
                strike = origin
            end

        end

    end

    strike = strike or unit:GetAbsOrigin()

    local ground = GetGroundPosition(strike, unit)

    local fx = ParticleManager:CreateParticle(
        RasputinFx(unit, RASPUTIN_SLAM_PARTICLE),
        PATTACH_CUSTOMORIGIN,
        unit
    )


    ParticleManager:SetParticleControl(fx, 0, ground)


    if radius and radius > 0 then
        ParticleManager:SetParticleControl(fx, 1, Vector(radius / 2, 0, 0))
    end

    ParticleManager:ReleaseParticleIndex(fx)

end


RASPUTIN_SHORT_DASH_SOUND = "rasputin_short_dash"


function RasputinScaleDamage(caster, ability, base)

    if not IsNotNull(caster) then return base end

    if not ability or ability:IsNull() then return base end

    local per = ability:GetLevelSpecialValueFor("damage_per_level", 0)

    if per == 0 then return base end

    return base + caster:GetLevel() * per

end

RASPUTIN_AFTERIMAGE_PARTICLE = "particles/rasputin/rasputin_afterimage_test.vpcf"


RASPUTIN_AFTERIMAGE_BACK_PARTICLE = "particles/rasputin/rasputin_afterimage_back.vpcf"

RASPUTIN_FLURRY_AFTERIMAGE = {
    [ACT_DOTA_ATTACK]             = "particles/rasputin/rasputin_afterimage_fin_attack.vpcf",
    [ACT_DOTA_ATTACK2]            = "particles/rasputin/rasputin_afterimage_fin_attack2.vpcf",
    [ACT_DOTA_CHANNEL_ABILITY_1]  = "particles/rasputin/rasputin_afterimage_fin_channel1.vpcf",
    [ACT_DOTA_CAST_ABILITY_2]     = "particles/rasputin/rasputin_afterimage_fin_cast2.vpcf",
    [ACT_DOTA_CAST_ABILITY_4]     = "particles/rasputin/rasputin_afterimage_fin_cast4.vpcf",
}


function RasputinFinisherAfterimage(unit, activity)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    local path = RASPUTIN_FLURRY_AFTERIMAGE[activity]

    if not path then return end

    Timers:CreateTimer(FrameTime(), function()

        if not IsNotNull(unit) then return end

        if not unit:IsAlive() then return end

        RasputinAfterimage(unit, nil, path, 0)

    end)

end

local AFTERIMAGE_INTERVAL = 0.05


local AFTERIMAGE_TRAIL_OFFSET = 50


local function RasputinFacing(unit)

    local forward = unit:GetForwardVector()
    forward.z = 0

    if forward:Length2D() == 0 then
        return Vector(1, 0, 0)
    end

    return forward:Normalized()

end


local function RasputinTravel(unit, travel)

    if travel then

        local dir = Vector(travel.x, travel.y, 0)

        if dir:Length2D() > 0 then
            return dir:Normalized()
        end

    end

    return RasputinFacing(unit)

end


function RasputinAfterimage(unit, travel, path, offset)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    if unit:HasModifier("modifier_rasputin_wide_kick_anim_lock") then return end


    if unit:HasModifier("modifier_rasputin_knife_grab") then return end

    local origin = unit:GetAbsOrigin()


    local moving = RasputinTravel(unit, travel)

    local fx = ParticleManager:CreateParticle(
        RasputinFx(unit, path or RASPUTIN_AFTERIMAGE_PARTICLE),
        PATTACH_CUSTOMORIGIN,
        unit
    )


    if offset == nil then
        offset = AFTERIMAGE_TRAIL_OFFSET
    end

    local at = origin - moving * offset

    ParticleManager:SetParticleControl(fx, 0, at)
    RasputinAimParticle(fx, 0, moving)


    ParticleManager:SetParticleControl(fx, 4, at + moving * 100)
    RasputinAimParticle(fx, 4, moving)

    ParticleManager:ReleaseParticleIndex(fx)

end


local AFTERIMAGE_MAX_DURATION = 3


RASPUTIN_DASH_TRAIL_PARTICLE = "particles/rasputin/rasputin_dash_trail.vpcf"


local DASH_TRAIL_OFFSET = 20


local DASH_EFFECT_LINGER = 0.12


RASPUTIN_DASH_SHIELD_PARTICLE = "particles/rasputin/rasputin_dash_shield.vpcf"


local DASH_SHIELD_BACK_OFFSET = 45


function RasputinDashShield(unit, IsRunning, travel)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end


    local fx = ParticleManager:CreateParticle(
        RasputinFx(unit, RASPUTIN_DASH_SHIELD_PARTICLE),
        travel and PATTACH_CUSTOMORIGIN or PATTACH_ABSORIGIN_FOLLOW,
        unit
    )

    local function Update()

        if not travel then return end

        local moving = RasputinTravel(unit, travel)

        ParticleManager:SetParticleControl(
            fx,
            0,
            unit:GetAbsOrigin() + moving * DASH_SHIELD_BACK_OFFSET
        )

        RasputinAimParticle(fx, 0, moving)

    end

    Update()

    local function Finish()

        if not fx then return end

        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)

        fx = nil

    end


    local linger = nil

    Timers:CreateTimer(FrameTime(), function()

        if not IsNotNull(unit) or not unit:IsAlive() then
            Finish()
            return
        end

        if not IsRunning() then

            linger = (linger or DASH_EFFECT_LINGER) - FrameTime()

            if linger <= 0 then
                Finish()
                return
            end

        end


        Update()

        return FrameTime()

    end)

end


function RasputinDashTrail(unit, IsRunning, travel)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    local fx = ParticleManager:CreateParticle(
        RasputinFx(unit, RASPUTIN_DASH_TRAIL_PARTICLE),
        PATTACH_CUSTOMORIGIN,
        unit
    )

    local function Update()

        local moving = RasputinTravel(unit, travel)

        local back = Vector(-moving.x, -moving.y, 0)

        ParticleManager:SetParticleControl(
            fx,
            3,
            unit:GetAbsOrigin() + back * DASH_TRAIL_OFFSET
        )


        RasputinAimParticle(fx, 3, back)

    end


    local function Finish()

        if not fx then return end

        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)

        fx = nil

    end

    Update()


    local linger = nil

    Timers:CreateTimer(FrameTime(), function()

        if not IsNotNull(unit) or not unit:IsAlive() then
            Finish()
            return
        end

        if not IsRunning() then

            linger = (linger or DASH_EFFECT_LINGER) - FrameTime()

            if linger <= 0 then
                Finish()
                return
            end

        end

        Update()

        return FrameTime()

    end)

end


function RasputinAfterimageTrail(unit, IsRunning, travel, path)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    RasputinAfterimage(unit, travel, path)

    local elapsed = 0

    Timers:CreateTimer(AFTERIMAGE_INTERVAL, function()

        if not IsNotNull(unit) then return end

        if not IsRunning() then return end

        elapsed = elapsed + AFTERIMAGE_INTERVAL

        if elapsed > AFTERIMAGE_MAX_DURATION then return end

        RasputinAfterimage(unit, travel, path)

        return AFTERIMAGE_INTERVAL

    end)

end


function RasputinBackDashFx(unit, IsRunning, travel)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end


    unit:EmitSound(RASPUTIN_SHORT_DASH_SOUND)

    RasputinDashShield(unit, IsRunning, travel)
    RasputinDashTrail(unit, IsRunning, travel)

    RasputinAfterimageTrail(
        unit,
        IsRunning,
        travel,
        RASPUTIN_AFTERIMAGE_BACK_PARTICLE
    )

end
