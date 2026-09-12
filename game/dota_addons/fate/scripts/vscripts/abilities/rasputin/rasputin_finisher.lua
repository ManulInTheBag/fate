require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

RASPUTIN_FINISH_TRAIL_PARTICLE =
"particles/rasputin/rasputin_fall_trail_finisher.vpcf"

rasputin_finisher = class({})


LinkLuaModifier("modifier_rasputin_finisher_counter","abilities/rasputin/modifier_rasputin_finisher_counter",LUA_MODIFIER_MOTION_NONE)


function rasputin_finisher:GetIntrinsicModifierName()
    return "modifier_rasputin_finisher_counter"
end


LinkLuaModifier(
"modifier_rasputin_finisher_channel",
"abilities/rasputin/modifier_rasputin_finisher_channel",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_rasputin_territory",
"abilities/rasputin/modifier_rasputin_territory",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_rasputin_curse_counter",
"abilities/rasputin/rasputin_bk",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_rasputin_combo_cd",
"abilities/rasputin/rasputin_combo",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_rasputin_wide_kick_target",
"abilities/rasputin/modifier_rasputin_wide_kick_target",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_rasputin_seen",
"abilities/rasputin/modifier_rasputin_wide_kick_target",
LUA_MODIFIER_MOTION_NONE
)


LinkLuaModifier(
"modifier_kb_immune",
"abilities/zlodemon_nasral/modifier_kb_immune",
LUA_MODIFIER_MOTION_NONE
)


local function FindWideKickTargets(caster, radius)

    local targets = {}

    local enemies =
    FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius or 9999,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO +
        DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _,enemy in pairs(enemies) do

        if enemy:HasModifier(
            "modifier_rasputin_wide_kick_target"
        )
        then

            table.insert(
                targets,
                enemy
            )

        end

    end

    return targets

end


local function FindWideKickGroup(caster, point, groupRadius, clicked, castRadius)

    local marked = FindWideKickTargets(caster, castRadius)

    if #marked == 0 then
        return {}
    end

    local primary


    if clicked and not clicked:IsNull() and clicked:IsAlive() then

        for _,enemy in pairs(marked) do

            if enemy == clicked then
                primary = clicked
                break
            end

        end

    end

    if not primary then

        local bestDistance

        for _,enemy in pairs(marked) do

            local distance =
            (enemy:GetAbsOrigin() - point):Length2D()

            if not bestDistance or distance < bestDistance then
                primary = enemy
                bestDistance = distance
            end

        end

    end

    if not primary then
        return {}
    end

    local origin = primary:GetAbsOrigin()

    -- основная цель всегда первая: по ней меряется разлёт группы
    local group = { primary }

    for _,enemy in pairs(marked) do

        if enemy ~= primary
        and (enemy:GetAbsOrigin() - origin):Length2D() <= groupRadius
        then
            table.insert(group, enemy)
        end

    end

    return group

end


function rasputin_finisher:ComboReady()

    local caster = self:GetCaster()


    if not caster:HasModifier("modifier_rasputin_finisher_channel") then
        return false
    end

    if not self.comboArmedAt then return false end

    if GameRules:GetGameTime() < self.comboArmedAt then return false end

    if not caster:FindAbilityByName("rasputin_combo") then
        print("[RASPUTIN combo] rasputin_combo is not on the hero")
        return false
    end


    if not GetComboAvailability then
        print("[RASPUTIN combo] GetComboAvailability is missing")
        return false
    end

    local ready = GetComboAvailability(caster)

    if ready ~= 0 then


        print(string.format(
            "[RASPUTIN combo] not ready (%s). str %.1f agi %.1f int %.1f, combo %s",
            ready == -1 and "stats or registry" or "on cooldown",
            caster:GetStrength(),
            caster:GetAgility(),
            caster:GetIntellect(),
            GetHeroCombo and GetHeroCombo(caster) or "?"
        ))

        return false

    end

    return true

end


function rasputin_finisher:TryCombo()

    if not self:ComboReady() then return false end

    local caster = self:GetCaster()

    local combo = caster:FindAbilityByName("rasputin_combo")


    combo.targets = self.targets

    self.comboArmedAt = nil


    self.comboArmed = true


    local cooldown = combo:GetCooldown(combo:GetLevel())

    combo:StartCooldown(cooldown)


    if cooldown and cooldown > 0 then

        caster:AddNewModifier(
            caster,
            combo,
            "modifier_rasputin_combo_cd",
            {
                duration = cooldown,
            }
        )

    end

    return true

end


function rasputin_finisher:StartArmedCombo()

    if not self.comboArmed then return end

    self.comboArmed = nil

    local caster = self:GetCaster()

    local combo = caster:FindAbilityByName("rasputin_combo")

    if not combo then return end


    local delay = combo:GetLevelSpecialValueFor("combo_start_delay", 0)

    local targets = self.targets or {}

    combo.targets = targets


    for _,enemy in pairs(targets) do

        if IsNotNull(enemy) and enemy:IsAlive() then

            enemy:AddNewModifier(
                caster,
                self,
                "modifier_stunned",
                {
                    duration = delay + combo:GetLevelSpecialValueFor("haul_delay", 0)
                }
            )

        end

    end

    Timers:CreateTimer(delay, function()

        if not IsNotNull(caster) or not IsNotNull(combo) then return end

        if not caster:IsAlive() then return end

        combo:OnSpellStart()

    end)

end


function rasputin_finisher:CastFilterResultLocation(location)

    local caster = self:GetCaster()

    if RasputinIsRooted(caster) then
        self.customCastError = "Cannot use while rooted"
        return UF_FAIL_CUSTOM
    end


    -- в стане финишер недоступен; собственный стан от серии ударов не считается,
    -- иначе нельзя было бы нажать F второй раз на комбо
    if IsServer()
    and caster:IsStunned()
    and not caster:HasModifier("modifier_rasputin_finisher_channel")
    then
        self.customCastError = "Cannot use while stunned"
        return UF_FAIL_CUSTOM
    end


    if not caster then
        return UF_FAIL_CUSTOM
    end


    if not IsServer() then
        return UF_SUCCESS
    end


    if self:ComboReady() then
        return UF_SUCCESS
    end

    -- второе нажатие во время серии, но комбо не взведено (мало стаков)
    if caster:HasModifier("modifier_rasputin_finisher_channel") then
        self.customCastError =
        "Combo needs " .. self:GetSpecialValueFor("combo_stacks_required") .. " charges"
        return UF_FAIL_CUSTOM
    end


    local counter =
    caster:FindModifierByName(
        "modifier_rasputin_finisher_counter"
    )


    if not counter then
        self.customCastError = "Need at least 1 stack"
        return UF_FAIL_CUSTOM
    end


    if counter:GetStackCount() < 1 then
        self.customCastError = "Need at least 1 stack"
        return UF_FAIL_CUSTOM
    end


    -- цель дальше cast_radius финишером не достаётся
    if #FindWideKickTargets(
        caster,
        self:GetSpecialValueFor("cast_radius")
    ) == 0
    then
        self.customCastError = "No enemies in range"
        return UF_FAIL_CUSTOM
    end


    return UF_SUCCESS

end


function rasputin_finisher:CastFilterResultTarget(target)

    return self:CastFilterResultLocation(
        target and not target:IsNull() and target:GetAbsOrigin() or nil
    )

end


function rasputin_finisher:GetCustomCastErrorTarget(target)

    return self.customCastError or "Need at least 1 stack"

end


function rasputin_finisher:GetCustomCastErrorLocation(location)

    return self.customCastError or "Need at least 1 stack"

end


function rasputin_finisher:GetCustomCastError()

    return self.customCastError or "Need at least 1 stack"

end


function rasputin_finisher:CreateTerritory(stacks)

    local caster = self:GetCaster()

    if not caster.IsRasputinTerritoryAcquired then return end

    local cap = self:GetSpecialValueFor("territory_max_stacks")


    local t = 0

    if cap > 1 then
        t = (math.min(stacks, cap) - 1) / (cap - 1)
    end

    if t < 0 then t = 0 end

    local radius =
    self:GetSpecialValueFor("territory_radius_min")
    + t * (self:GetSpecialValueFor("territory_radius_max")
         - self:GetSpecialValueFor("territory_radius_min"))

    local duration = self:GetSpecialValueFor("territory_duration")

    -- суммарное восстановление за всю территорию на максимальных стаках
    -- растёт от уровня героя; меньше стаков - пропорционально меньше
    local total =
    self:GetSpecialValueFor("territory_heal_total")
    + self:GetSpecialValueFor("territory_heal_per_level") * math.max(caster:GetLevel() - 1, 0)

    local minPct = self:GetSpecialValueFor("territory_heal_min_pct") / 100

    total = total * (minPct + t * (1 - minPct))

    local regen = 0

    if duration > 0 then
        regen = total / duration
    end

    local perWave = self:GetSpecialValueFor("territory_stacks_per_wave")

    local waves = 0

    if perWave > 0 then
        waves = math.floor(stacks / perWave)
    end


    local maxWaves = 1

    if perWave > 0 then
        maxWaves = math.max(math.floor(cap / perWave), 1)
    end


    -- новая территория не продлевает старую, а заменяет её целиком:
    -- старая гаснет (недоигранная волна очистки срабатывает сразу),
    -- новая создаётся с нуля со своими радиусом/регеном/волнами/партиклем
    local old = caster:FindModifierByName("modifier_rasputin_territory")

    if old then
        old:FinishEarly()
        old:Destroy()
    end


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_territory",
        {
            duration      = duration,
            radius        = radius,
            regen         = regen,
            waves         = waves,
            wave_interval = duration / maxWaves,
        }
    )

end


function rasputin_finisher:BankCurseStacks(stacks)

    local caster = self:GetCaster()

    if not caster.IsRasputinBkCursesAcquired then return end

    if not stacks or stacks < 1 then return end

    local counter =
    caster:FindModifierByName("modifier_rasputin_curse_counter")

    if not counter then

        counter =
        caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_curse_counter",
            {}
        )

    end

    if counter then
        counter:AddStacks(stacks)
    end

end


function rasputin_finisher:HealFromDamage(amount)

    if not amount or amount <= 0 then return end

    local caster = self:GetCaster()

    if not IsNotNull(caster) then return end

    if not caster.IsRasputinCombatMovementAcquired then return end


    local pct =
    self:GetSpecialValueFor("heal_pct")
    + (100 - caster:GetHealthPercent())

    local cap = self:GetSpecialValueFor("heal_pct_max")

    if pct > cap then
        pct = cap
    end

    caster:Heal(amount * pct / 100, self)


    caster:GiveMana(amount * self:GetSpecialValueFor("mana_pct") / 100)

end


function rasputin_finisher:OnSpellStart()

    local caster = self:GetCaster()


    if self:TryCombo() then
        return
    end


    local targets =
    FindWideKickGroup(
        caster,
        self:GetCursorPosition(),
        self:GetSpecialValueFor("group_radius"),
        self:GetCursorTarget(),
        self:GetSpecialValueFor("cast_radius")
    )

    if #targets == 0 then
        return
    end


    caster:RemoveModifierByName("modifier_rasputin_wide_kick_anim_lock")


    RasputinPlayGesture(caster, ACT_DOTA_CAST_ABILITY_5)


    RasputinCancelWideKick(caster)

    local pushDirection =
    Vector(
        caster:GetForwardVector().x,
        caster:GetForwardVector().y,
        0
    ):Normalized()

    self.pushDirection = pushDirection

        local counter =
    caster:FindModifierByName(
        "modifier_rasputin_finisher_counter"
    )

    local stacks = 1

    if counter then
        stacks = counter:GetStackCount()
    end

    self.stacksUsed = stacks

    local duration = 0.1 + stacks * 0.1

    local minPush = self:GetSpecialValueFor("push_distance_min")
    local maxPush = self:GetSpecialValueFor("push_distance_max")

    local pushDistance =
    minPush
    +
    (stacks - 1) / 9
    *
    (maxPush - minPush)


    local center = Vector(0,0,0)


    for _,enemy in pairs(targets) do

        center =
        center +
        enemy:GetAbsOrigin()

    end


    center =
    center / #targets

    for _,enemy in pairs(targets) do
    enemy:RemoveModifierByName("modifier_knockback")
    enemy:InterruptMotionControllers(true)

    end


    local standOff =
    center - pushDirection * self:GetSpecialValueFor("teleport_offset")

    caster:SetAbsOrigin(standOff)


    FindClearSpaceForUnit(
        caster,
        standOff,
        true
    )


    self:CreateTerritory(stacks)
    self:BankCurseStacks(stacks)


    local walkGroup = {}


    self.wallWatchers = {}

    local function ApplyWalk(unit)


        unit:AddNewModifier(
            caster,
            self,
            "modifier_kb_immune",
            {
                duration = duration
            }
        )

        local walkOrigin =
        unit:GetAbsOrigin()
        -
        pushDirection * 10000

        unit:AddNewModifier(
            caster,
            self,
            "modifier_knockback",
            {
                duration = duration,
                knockback_duration = duration,
                knockback_distance = pushDistance,
                knockback_height = 0,
                center_x = walkOrigin.x,
                center_y = walkOrigin.y,
                center_z = walkOrigin.z
            }
        )


        RasputinWallStop(unit, duration, 0, walkGroup, self.wallWatchers)

    end


    if #targets == 1 then

        ApplyWalk(caster)

    else

        caster:AddNewModifier(
            caster,
            self,
            "modifier_kb_immune",
            {
                duration = duration
            }
        )

    end


    caster:AddNewModifier(
        caster,
        self,
        "modifier_rasputin_finisher_channel",
        {
            duration = duration
        }
    )


    -- второе нажатие F открывает комбо только с полного счётчика
    self.comboArmedAt = nil

    if stacks >= self:GetSpecialValueFor("combo_stacks_required") then
        self.comboArmedAt =
        GameRules:GetGameTime() + self:GetSpecialValueFor("combo_press_gap")
    end


    local seenFor =
    duration
    + self:GetSpecialValueFor("finish_push_duration")
    + self:GetSpecialValueFor("finish_stun_after")
    + self:GetSpecialValueFor("vision_linger")

    for _,enemy in pairs(targets) do

        enemy:AddNewModifier(
            caster,
            self,
            "modifier_stunned",
            {
                duration = duration
            }
        )

        enemy:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_seen",
            {
                duration = seenFor
            }
        )

        ApplyWalk(enemy)

    end


    self.targets = targets


    if counter then

        counter:SetStackCount(0)

    end

end


-- Цель, которую унесло дальше drop_radius от основной, выпадает из серии:
-- Распутин к ней больше не прыгает и не наносит ей урон, включая добивающий.
function rasputin_finisher:PruneFarTargets()

    local targets = self.targets

    if not targets or #targets < 2 then return end


    local anchor

    for _,enemy in pairs(targets) do

        if IsNotNull(enemy) and enemy:IsAlive() then
            anchor = enemy
            break
        end

    end

    if not anchor then return end


    local origin = anchor:GetAbsOrigin()

    local limit = self:GetSpecialValueFor("drop_radius")


    local kept = {}

    for _,enemy in pairs(targets) do

        if IsNotNull(enemy)
        and (
            enemy == anchor
            or (enemy:GetAbsOrigin() - origin):Length2D() <= limit
        )
        then
            table.insert(kept, enemy)
        end

    end

    self.targets = kept

end


function rasputin_finisher:DealFinishDamage()


    local caster = self:GetCaster()

    self:PruneFarTargets()


    if caster and not caster:IsNull() then

        FindClearSpaceForUnit(
            caster,
            caster:GetAbsOrigin(),
            true
        )

    end


    caster:EmitSound("rasputin_finisher_end")


    -- Добивающий удар считается от номинальной суммы серии: сколько зарядов
    -- потрачено, столько ударов и берём по значению из KV (реально нанесённый
    -- урон не в счёт), и умножаем на finish_damage_percent.
    local hits = self.stacksUsed or 0

    local perHit =
    RasputinScaleDamage(
        caster,
        self,
        self:GetSpecialValueFor("tick_damage")
    )
    * (self.tickScale or 1)


    local finishDamage =
    hits
    * perHit
    * self:GetSpecialValueFor("finish_damage_percent")
    / 100

    local pushDirection =
    self.pushDirection
    or Vector(0,0,0)


    for _,enemy in pairs(self.targets or {}) do


        if enemy and not enemy:IsNull() then


            FindClearSpaceForUnit(
                enemy,
                enemy:GetAbsOrigin(),
                true
            )


            local damage = finishDamage

            DoDamage(
                caster,
                enemy,
                damage,
                DAMAGE_TYPE_PHYSICAL,
                0,
                self,
                false
            )

            self:HealFromDamage(damage)


            do

                local finishDuration =
                self:GetSpecialValueFor("finish_push_duration")

                local throwOrigin =
                enemy:GetAbsOrigin() - pushDirection * 10000

                enemy:RemoveModifierByName("modifier_knockback")
                enemy:InterruptMotionControllers(true)

                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_kb_immune",
                    {
                        duration = finishDuration
                    }
                )

                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_knockback",
                    {
                        duration = finishDuration,
                        knockback_duration = finishDuration,
                        knockback_distance =
                        self:GetSpecialValueFor("finish_push_distance"),
                        knockback_height =
                        self:GetSpecialValueFor("finish_push_height"),
                        center_x = throwOrigin.x,
                        center_y = throwOrigin.y,
                        center_z = throwOrigin.z
                    }
                )


                enemy:AddNewModifier(
                    caster,
                    self,
                    "modifier_stunned",
                    {
                        duration =
                        finishDuration
                        + self:GetSpecialValueFor("finish_stun_after")
                    }
                )


                RasputinWallStop(
                    enemy,
                    finishDuration,
                    RASPUTIN_THIN_OBSTACLE,
                    nil,
                    self.wallWatchers
                )

                local trailFx = ParticleManager:CreateParticle(
                    RASPUTIN_FINISH_TRAIL_PARTICLE,
                    PATTACH_CUSTOMORIGIN,
                    enemy
                )

                ParticleManager:SetParticleControl(
                    trailFx,
                    0,
                    enemy:GetAbsOrigin()
                )

                ParticleManager:SetParticleControlEnt(
                    trailFx,
                    3,
                    enemy,
                    PATTACH_POINT_FOLLOW,
                    "attach_hitloc",
                    enemy:GetAbsOrigin(),
                    true
                )

                ParticleManager:SetParticleShouldCheckFoW(trailFx, false)

                Timers:CreateTimer(finishDuration, function()
                    ParticleManager:DestroyParticle(trailFx, false)
                    ParticleManager:ReleaseParticleIndex(trailFx)
                end)

                Timers:CreateTimer(finishDuration + 0.1, function()

                    if enemy and not enemy:IsNull() then
                        FindClearSpaceForUnit(enemy, enemy:GetAbsOrigin(), true)
                    end

                end)

            end

        end

    end


end
