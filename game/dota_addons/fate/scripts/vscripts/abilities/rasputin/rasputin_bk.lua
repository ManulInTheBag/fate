require('abilities/rasputin/rasputin_gesture')

RASPUTIN_BK_START_SOUND = "rasputin_bk_start"
RASPUTIN_BREAK_BURST_SOUND = "rasputin_curse_burst"

rasputin_dodge_break = class({})

LinkLuaModifier("modifier_rasputin_reborn", "abilities/rasputin/rasputin_bk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dodge_break", "abilities/rasputin/rasputin_bk", LUA_MODIFIER_MOTION_NONE)


function RasputinIsReborn(unit)

    if not unit or unit:IsNull() then return false end

    return unit:HasModifier("modifier_rasputin_reborn")

end


modifier_rasputin_curse_counter = class({})

function modifier_rasputin_curse_counter:IsHidden() return false end
function modifier_rasputin_curse_counter:IsPurgable() return false end
function modifier_rasputin_curse_counter:IsDebuff() return false end
function modifier_rasputin_curse_counter:RemoveOnDeath() return false end

function modifier_rasputin_curse_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_curse_counter:OnCreated()

    if not IsServer() then return end

    self:StartIntervalThink(0.25)

end


function modifier_rasputin_curse_counter:GetThreshold()

    local ability = self:GetAbility()

    if not IsNotNull(ability) then return 20 end

    return ability:GetSpecialValueFor("curse_stacks_to_revive")

end


function modifier_rasputin_curse_counter:AddStacks(amount)

    if not IsServer() then return end

    if not amount or amount <= 0 then return end

    self:SetStackCount(
        math.min(self:GetStackCount() + amount, self:GetThreshold())
    )

end


function modifier_rasputin_curse_counter:IsReady()
    return self:GetStackCount() >= self:GetThreshold()
end


function modifier_rasputin_curse_counter:DeclareFunctions()

    return {
        MODIFIER_EVENT_ON_DEATH,
    }

end


function modifier_rasputin_curse_counter:OnDeath(params)

    if not IsServer() then return end

    local parent = self:GetParent()

    if params.unit ~= parent then return end

    local ready = self:IsReady()


    self:SetStackCount(0)

    if not ready then return end

    local ability = self:GetAbility()
    local pos = parent:GetAbsOrigin()

    Timers:CreateTimer(1, function()

        if not IsNotNull(parent) then return end


        if IsTeamWiped(parent) then return end

        if _G.CurrentGameState ~= "FATE_ROUND_ONGOING" then return end

        local fx = ParticleManager:CreateParticle(
            "particles/items_fx/aegis_respawn.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            parent
        )

        ParticleManager:ReleaseParticleIndex(fx)

        parent:SetRespawnPosition(pos)
        parent:RespawnHero(false, false)
        parent:SetRespawnPosition(parent.RespawnPos)


        RasputinRefreshAbilities(parent)

        if IsNotNull(ability) then

            parent:AddNewModifier(
                parent,
                ability,
                "modifier_rasputin_reborn",
                {


                    duration = ability:GetSpecialValueFor("reborn_kill_window")
                }
            )

        end

    end)

end


function RasputinRefreshAbilities(unit)

    if not IsServer() then return end

    if not IsNotNull(unit) then return end

    for i = 0, unit:GetAbilityCount() - 1 do

        local ability = unit:GetAbilityByIndex(i)


        if ability
        and not ability:IsNull()
        and not string.find(ability:GetAbilityName(), "_attribute")
        and not string.find(ability:GetAbilityName(), "rasputin_combat_movement")
        and not string.find(ability:GetAbilityName(), "rasputin_territory_creation")
        and not string.find(ability:GetAbilityName(), "rasputin_bk_curses")
        and not string.find(ability:GetAbilityName(), "rasputin_keys")


        and ability:GetAbilityName() ~= "rasputin_dodge_break"
        then
            ability:EndCooldown()
        end

    end

    local charges = unit:FindModifierByName("modifier_rasputin_dash_charges")

    if charges then
        charges:SetStackCount(charges:GetMaxStackCount())
    end

end


function modifier_rasputin_curse_counter:OnIntervalThink()

    if not IsServer() then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    local roundOn = _G.CurrentGameState == "FATE_ROUND_ONGOING"

    if not roundOn then

        if self:GetStackCount() > 0 then
            self:SetStackCount(0)
        end


        if self.breakUsed then

            self.breakUsed = nil

            local break_ability = parent:FindAbilityByName("rasputin_dodge_break")

            if break_ability then
                break_ability:EndCooldown()
            end

        end

    end

    local break_ability = parent:FindAbilityByName("rasputin_dodge_break")

    if not break_ability then return end


    if self.breakUsed then

        self:SetBreakShown(parent, break_ability, false)

        return

    end

    self:SetBreakShown(parent, break_ability, self:ShouldShowBreak(parent))

end


function modifier_rasputin_curse_counter:ShouldShowBreak(parent)


    if not parent:IsAlive() then return false end


    if not parent:IsStunned() then
        return false
    end

    if parent:HasModifier("modifier_rasputin_finisher_channel") then
        return false
    end

    if parent:HasModifier("modifier_rasputin_knife_grab") then
        return false
    end

    return true

end


-- Curse Breakout занимает слот финишера (F), пока Распутин в стане
function modifier_rasputin_curse_counter:SetBreakShown(parent, break_ability, shown)

    local finisher = parent:FindAbilityByName("rasputin_finisher")

    if not finisher then return end


    self.breakSlot = self.breakSlot or finisher:GetAbilityIndex()

    if not self.breakSlot or self.breakSlot < 0 then return end

    local wanted = shown and break_ability or finisher

    if parent:GetAbilityByIndex(self.breakSlot) ~= wanted then
        parent:SwapAbilities("rasputin_finisher", "rasputin_dodge_break", not shown, shown)
    end

    break_ability:SetHidden(not shown)

    self.swapped = shown

end


function modifier_rasputin_curse_counter:MarkBreakUsed()

    if not IsServer() then return end



    self.breakUsed = true

end


modifier_rasputin_reborn = class({})

function modifier_rasputin_reborn:IsHidden() return false end
function modifier_rasputin_reborn:IsPurgable() return false end
function modifier_rasputin_reborn:IsDebuff() return false end
function modifier_rasputin_reborn:RemoveOnDeath() return true end


function modifier_rasputin_reborn:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH,
    }

end


function modifier_rasputin_reborn:OnCreated(kv)

    if not IsServer() then return end


    self.paid = kv and kv.no_death == 1

    if not self.paid then

        local parent = self:GetParent()

        if IsNotNull(parent) then
            parent:EmitSound(RASPUTIN_BK_START_SOUND)
        end

    end

    -- полоска Reborn в rasputin_hud рисуется у всех игроков; врагам она нужна
    -- только пока Распутин виден, иначе повиснет на последней известной точке
    self:PublishSeen()
    self:StartIntervalThink(0.1)

end


function modifier_rasputin_reborn:OnIntervalThink()
    if not IsServer() then return end
    self:PublishSeen()
end


function modifier_rasputin_reborn:PublishSeen()

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    local seen = parent:CanBeSeenByAnyOpposingTeam() and 1 or 0

    if self.lastSeen == seen then return end

    self.lastSeen = seen

    CustomNetTables:SetTableValue(
        "sync",
        "rasputin_reborn_" .. parent:entindex(),
        { seen = seen }
    )

end


function modifier_rasputin_reborn:OnDestroy()

    if not IsServer() then return end

    local seenParent = self:GetParent()

    if IsNotNull(seenParent) then
        CustomNetTables:SetTableValue(
            "sync",
            "rasputin_reborn_" .. seenParent:entindex(),
            { seen = 0 }
        )
    end


    if self.paid then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    if not parent:IsAlive() then return end

    parent:Kill(self:GetAbility(), parent)

end


function modifier_rasputin_reborn:OnDeath(params)

    if not IsServer() then return end

    if self.paid then return end

    if not IsNotNull(params.unit) then return end


    if not params.unit:IsRealHero() then return end


    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    if params.unit:GetTeamNumber() == parent:GetTeamNumber() then return end


    -- засчитывается собственный килл ИЛИ смерть вражеского Слуги рядом
    if params.attacker ~= parent then

        local radius =
        self:GetAbility() and self:GetAbility():GetSpecialValueFor("reborn_kill_radius") or 0

        if radius <= 0 then return end

        if (params.unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > radius then
            return
        end

    end


    self.paid = true


    local window =
    self:GetAbility():GetSpecialValueFor("reborn_kill_window")

    if window and window > 0 then
        self:SetDuration(window, true)
    end

end


function modifier_rasputin_reborn:GetModifierMoveSpeed_Absolute()
    return self:GetAbility():GetSpecialValueFor("reborn_movespeed")
end


function modifier_rasputin_reborn:GetModifierPercentageCooldown()
    return self:GetAbility():GetSpecialValueFor("reborn_cooldown_pct")
end


function rasputin_dodge_break:OnSpellStart()

    local caster = self:GetCaster()


    caster:EmitSound(RASPUTIN_BREAK_BURST_SOUND)

    local breakDuration = self:GetSpecialValueFor("break_duration")

    local rate = 1

    if breakDuration > 0 then
        rate = RASPUTIN_CLIP[ACT_DOTA_OVERRIDE_ABILITY_3] / breakDuration
    end

    RasputinPlayGesture(
        caster,
        ACT_DOTA_OVERRIDE_ABILITY_3,
        breakDuration,
        rate
    )


    local counter = caster:FindModifierByName("modifier_rasputin_curse_counter")

    if counter then
        counter:MarkBreakUsed()
    end



    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_dodge_break",
        {
            duration = self:GetSpecialValueFor("break_duration")
        }
    )

end


modifier_rasputin_dodge_break = class({})

function modifier_rasputin_dodge_break:IsHidden() return false end
function modifier_rasputin_dodge_break:IsPurgable() return false end
function modifier_rasputin_dodge_break:IsDebuff() return false end
function modifier_rasputin_dodge_break:RemoveOnDeath() return true end


local CURSE_BURST_AUTHORED_RADIUS = 200


function modifier_rasputin_dodge_break:OnCreated()

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()


    ApplyStrongDispel(parent)

    local duration = ability:GetSpecialValueFor("break_duration")
    local radius = ability:GetSpecialValueFor("break_radius")

    local fx = ParticleManager:CreateParticle(
        "particles/rasputin/rasputin_curse_burst.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )


    ParticleManager:SetParticleControl(
        fx,
        1,
        Vector(radius / CURSE_BURST_AUTHORED_RADIUS, 0, 0)
    )


    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)

    self:StartIntervalThink(ability:GetSpecialValueFor("break_tick"))

end


function modifier_rasputin_dodge_break:CheckState()

    return {
        [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
        [MODIFIER_STATE_ROOTED] = true,
    }

end


function modifier_rasputin_dodge_break:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }

end


function modifier_rasputin_dodge_break:GetModifierDisableTurning()
    return 1
end


function modifier_rasputin_dodge_break:GetModifierIncomingDamage_Percentage()

    return -self:GetAbility():GetSpecialValueFor("break_damage_reduction")

end


function modifier_rasputin_dodge_break:OnIntervalThink()

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not IsNotNull(parent) or not IsNotNull(ability) then return end

    local radius = ability:GetSpecialValueFor("break_radius")

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _,enemy in pairs(enemies) do

        DoDamage(
            parent,
            enemy,
            ability:GetSpecialValueFor("break_tick_damage"),
            DAMAGE_TYPE_PHYSICAL,
            0,
            ability,
            false
        )

    end

end


function modifier_rasputin_dodge_break:OnDestroy()

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not IsNotNull(parent) or not IsNotNull(ability) then return end

    local origin = parent:GetAbsOrigin()

    local distance = ability:GetSpecialValueFor("break_push_distance")
    local duration = ability:GetSpecialValueFor("break_push_duration")

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        origin,
        nil,
        ability:GetSpecialValueFor("break_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _,enemy in pairs(enemies) do

        if not IsKnockbackImmune(enemy) then

            enemy:AddNewModifier(
                parent,
                ability,
                "modifier_knockback",
                {
                    should_stun = 0,
                    duration = duration,
                    knockback_duration = duration,
                    knockback_distance = distance,
                    knockback_height = 0,
                    center_x = origin.x,
                    center_y = origin.y,
                    center_z = origin.z,
                }
            )

        end

    end

end
