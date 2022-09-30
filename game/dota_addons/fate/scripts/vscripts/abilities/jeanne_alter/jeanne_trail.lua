LinkLuaModifier("modifier_jeanne_trail", "abilities/jeanne_alter/jeanne_trail", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_trail_debuff", "abilities/jeanne_alter/jeanne_trail", LUA_MODIFIER_MOTION_NONE)

jeanne_trail = class({})

--[[function jeanne_trail:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = self:GetCaster():GetSecondsPerAttack()/1.2})

        return true
    end
end]]
function jeanne_trail:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration") + (caster.OblivionCorrectionAcquired and caster:FindAbilityByName("jeanne_trail_reactivate"):GetSpecialValueFor("additional_duration") or 0)

    --self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = 0.5})

    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
        if caster:FindAbilityByName("jeanne_lagron"):IsCooldownReady() 
            and caster:FindAbilityByName("jeanne_lagron_combo"):IsCooldownReady()  
            and caster:GetAbilityByIndex(5):GetName() == "jeanne_lagron"
            and caster:HasModifier("modifier_jeanne_lagron_combo_window") then
            caster:SwapAbilities("jeanne_lagron", "jeanne_lagron_combo", false, true)
            Timers:CreateTimer(4, function()
                caster:SwapAbilities("jeanne_lagron", "jeanne_lagron_combo", true, false)
            end)
        end
    end

    if caster.OblivionCorrectionAcquired and caster:FindAbilityByName("jeanne_trail_reactivate"):IsCooldownReady() then
        caster:SwapAbilities("jeanne_trail", "jeanne_trail_reactivate", false, true)
        Timers:CreateTimer(1, function()
            if caster:GetAbilityByIndex(0):GetName() == "jeanne_trail_reactivate" then
                caster:SwapAbilities("jeanne_trail", "jeanne_trail_reactivate", true, false)
            end
        end)
    end


    if not self.TrailTable then
        self.TrailTable = {}
    end

    --caster:EmitSound("Hero_Phoenix.FireSpirits.Launch")

    local trailDummy = CreateUnitByName("sight_dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
    trailDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
    trailDummy:SetDayTimeVisionRange(0)
    trailDummy:SetNightTimeVisionRange(0)
    --trailDummy:FaceTowards(self:GetCursorPosition())

    trailDummy:AddNewModifier(caster, self, "modifier_jeanne_trail", {duration = duration + self:GetSpecialValueFor("delay")})

    table.insert(self.TrailTable, trailDummy)

    for i = 1, #self.TrailTable do
        --PrintTable(self.TrailTable[i])
    end

    --[[local charge_fx = ParticleManager:CreateParticle("particles/jeanne_alter/unholy_judgement_rope.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(charge_fx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(charge_fx, 2, caster:GetAbsOrigin() + caster:GetForwardVector()*1000)
    ParticleManager:SetParticleControl(charge_fx, 4, Vector(200/2, 0, 0))
    ParticleManager:SetParticleControl(charge_fx, 5, Vector(1, 0, 0))]]


    --[[local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        500,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
        caster:EmitSound("Hero_DragonKnight.BreathFire")
        local caster_angle = caster:GetAnglesAsVector().y
        local origin_difference = caster:GetAbsOrigin() - enemy:GetAbsOrigin()
        local damage = self:GetSpecialValueFor("damage")

        if caster.OblivionCorrectionAcquired and enemy:GetHealth()/enemy:GetMaxHealth() >= 0.7 then
            damage = damage*1.5
        end

        local origin_difference_vector = origin_difference:Normalized()

        local flame = 
        {
            Ability = self,
            EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
            iMoveSpeed = 2000,
            vSpawnOrigin = caster:GetAbsOrigin(),
            fDistance = 300,
            fStartRadius = 100,
            fEndRadius = 200,
            Source = caster,
            bHasFrontalCone = true,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 0.5,
            bDeleteOnHit = false,
            vVelocity = -Vector(origin_difference_vector.x, origin_difference_vector.y, 0) * 1500
        }
        ProjectileManager:CreateLinearProjectile(flame)

        local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

        origin_difference_radian = origin_difference_radian * 180
        local enemy_angle = origin_difference_radian / math.pi

        enemy_angle = enemy_angle + 180.0

        local result_angle = enemy_angle - caster_angle
        result_angle = math.abs(result_angle)

        if result_angle <= 110 then
            if not enemy:IsMagicImmune() then
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                if enemy:HasModifier("modifier_jeanne_curse_active") and caster.OblivionCorrectionAcquired then
                    enemy:AddNewModifier(caster, caster:FindAbilityByName("jeanne_curse"), "modifier_jeanne_curse_active", {duration = caster:FindAbilityByName("jeanne_curse"):GetSpecialValueFor("duration")})
                end
            end
            caster:PerformAttack( enemy, true, true, true, true, false, false, true )
        end
    end]]
end

function jeanne_trail:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    --print("iampepeg")
end

jeanne_trail_reactivate = class({})

function jeanne_trail_reactivate:OnSpellStart()
    local caster = self:GetCaster()
    local ability = caster:FindAbilityByName("jeanne_trail")
    caster:SwapAbilities("jeanne_trail", "jeanne_trail_reactivate", true, false)
    for i = 1, #ability.TrailTable do
        ability.TrailTable[i]:FindModifierByName("modifier_jeanne_trail"):ReExplode()
    end
end


modifier_jeanne_trail = class({})

function modifier_jeanne_trail:IsHidden()            return false end
function modifier_jeanne_trail:IsDebuff()            return false end
function modifier_jeanne_trail:IsPurgable()          return false end
function modifier_jeanne_trail:IsPurgeException()    return false end
function modifier_jeanne_trail:RemoveOnDeath()       return true end
function modifier_jeanne_trail:OnCreated(args)
    if IsServer() then
        self.caster = self:GetCaster()
        self.parent  = self:GetParent()
        self.ability = self:GetAbility()
        self.vector = self:GetCaster():GetForwardVector()
        self.origin = self:GetCaster():GetAbsOrigin()
        self.range = self.ability:GetSpecialValueFor("range")
        self.width = self.ability:GetSpecialValueFor("width")
        self.delay = self.ability:GetSpecialValueFor("delay")
        self.add_duration = (self.caster.OblivionCorrectionAcquired and self.caster:FindAbilityByName("jeanne_trail_reactivate"):GetSpecialValueFor("additional_duration") or 0)

        EmitSoundOnLocationWithCaster(self.origin, "Hero_VoidSpirit.Dissimilate.Portals", self.caster)

        CreateGlobalParticle("particles/jeanne_alter/unholy_judgement_rope.vpcf",
                                                                                         {[0] = self.origin,
                                                                                        [2] = self.origin + self.vector*self.range,
                                                                                        [4] = Vector(self.width, 0, 0),
                                                                                        [5] = Vector(self.delay + 0.5, 0, 0)},
                                                                                        self.delay)
        Timers:CreateTimer(self.delay, function()
            --[[CreateGlobalParticle("particles/jeanne_alter/unholy_judgement_rope_2.vpcf",
                                                                                        {[0] = self.origin,
                                                                                        [2] = self.origin + self.vector*self.range,
                                                                                        [4] = Vector(200, 0, 0),
                                                                                        [5] = Vector(self.ability:GetSpecialValueFor("duration"), 0, 0)},
                                                                                        self.ability:GetSpecialValueFor("duration"))]]

            CreateGlobalParticle("particles/jeanne_alter/unholy_judgement_flametrail.vpcf",
                                                                                        {[0] = self.origin,
                                                                                        [1] = Vector(self.ability:GetSpecialValueFor("duration") + self.add_duration, 0, 0),
                                                                                        [2] = self.origin + self.vector*self.range},
                                                                                        self.ability:GetSpecialValueFor("duration") + self.add_duration)
            self:Explode()
            self:StartIntervalThink(0.25)
        end)
    end
end

function modifier_jeanne_trail:OnIntervalThink()
    if IsServer() then
        local enemies = FindUnitsInLine(
                                            self.caster:GetTeamNumber(),
                                            self.origin,
                                            self.origin + self.vector*self.range,
                                            nil,
                                            self.width,
                                            self.ability:GetAbilityTargetTeam(),
                                            self.ability:GetAbilityTargetType(),
                                            self.ability:GetAbilityTargetFlags()
                                        )

        for _, enemy in pairs(enemies) do
            DoDamage(self.caster, enemy, self.ability:GetSpecialValueFor("burn_damage")/4, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            if self.caster.CursedGroundAcquired then
                if enemy:HasModifier("modifier_jeanne_curse_active") then
                    local modifier = enemy:FindModifierByName("modifier_jeanne_curse_active")
                    local modifier2 = enemy:AddNewModifier(self.caster, self.caster:FindAbilityByName("jeanne_curse"), "modifier_jeanne_curse_active", {duration = modifier.duration_remaining + 0.25})
                    modifier2.duration_remaining = modifier2.duration_remaining + 0.25
                else
                    if enemy:IsHero() then
                        self.caster:FindAbilityByName("jeanne_curse"):WeakCurse(enemy)
                    end
                end
            end
            --[[enemy:AddNewModifier(self.caster, enemy, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
            ApplyAirborneOnly(enemy, 3000, 0.2, 1500)
            Timers:CreateTimer(0.2, function()
                enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))
            end)]]

            --enemy:EmitSound("jtr_slash")
        end
    end
end

function modifier_jeanne_trail:Explode()
    if IsServer() then
        EmitSoundOnLocationWithCaster(self.parent:GetAbsOrigin(), "Gilles_Cthulhu_Root", self.caster)
        local enemies = FindUnitsInLine(
                                            self.caster:GetTeamNumber(),
                                            self.origin,
                                            self.origin + self.vector*self.range,
                                            nil,
                                            self.width,
                                            self.ability:GetAbilityTargetTeam(),
                                            self.ability:GetAbilityTargetType(),
                                            self.ability:GetAbilityTargetFlags()
                                        )

        for _, enemy in pairs(enemies) do
            DoDamage(self.caster, enemy, self.ability:GetSpecialValueFor("initial_damage"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            EmitSoundOnLocationWithCaster(enemy:GetAbsOrigin(), "Gilles_Cthulhu_Root", self.caster)
            enemy:AddNewModifier(self.caster, self, "modifier_jeanne_trail_debuff", {Duration = self.ability:GetSpecialValueFor("stun_duration")})
            --enemy:EmitSound("jtr_slash")
        end
    end
end

function modifier_jeanne_trail:ReExplode()
    if IsServer() then
        EmitSoundOnLocationWithCaster(self.origin, "Hero_VoidSpirit.Dissimilate.Portals", self.caster)

        CreateGlobalParticle("particles/jeanne_alter/unholy_judgement_rope.vpcf",
                                                                                         {[0] = self.origin,
                                                                                        [2] = self.origin + self.vector*self.range,
                                                                                        [4] = Vector(self.width, 0, 0),
                                                                                        [5] = Vector(self.delay + 0.5, 0, 0)},
                                                                                        self.delay)

        Timers:CreateTimer(self.delay, function()
            EmitSoundOnLocationWithCaster(self.origin, "Gilles_Cthulhu_Root", self.caster)
            local enemies = FindUnitsInLine(
                                                self.caster:GetTeamNumber(),
                                                self.origin,
                                                self.origin + self.vector*self.range,
                                                nil,
                                                self.width,
                                                self.ability:GetAbilityTargetTeam(),
                                                self.ability:GetAbilityTargetType(),
                                                self.ability:GetAbilityTargetFlags()
                                            )

            for _, enemy in pairs(enemies) do
                DoDamage(self.caster, enemy, self.ability:GetSpecialValueFor("initial_damage"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                EmitSoundOnLocationWithCaster(enemy:GetAbsOrigin(), "Gilles_Cthulhu_Root", self.caster)
                enemy:AddNewModifier(self.caster, enemy, "modifier_jeanne_trail_debuff", {Duration = self.ability:GetSpecialValueFor("stun_duration")})
                --enemy:EmitSound("jtr_slash")
            end
        end)
    end
end

function modifier_jeanne_trail:OnDestroy()
    if IsServer() then
        local index = false
        for i = 1, #self.ability.TrailTable do
            if (self.ability.TrailTable[i] == self:GetParent()) then
                index = i
            end
        end

        if index then
            --print("success")
            table.remove(self.ability.TrailTable, index)
        else
            --print("something went wrong")
        end

        self.parent:ForceKill(false)
        UTIL_Remove(self.parent)
    end
end

modifier_jeanne_trail_debuff = class({})

function modifier_jeanne_trail_debuff:CheckState()
    return { [MODIFIER_STATE_SILENCED] = true,
             [MODIFIER_STATE_ROOTED] = true }
end

function modifier_jeanne_trail_debuff:IsHidden() return false end
function modifier_jeanne_trail_debuff:IsDebuff() return true end
function modifier_jeanne_trail_debuff:RemoveOnDeath() return true end

function modifier_jeanne_trail_debuff:OnCreated(keys)
    self.parent = self:GetParent()
    local burn_fx = ParticleManager:CreateParticle("particles/jeanne_alter/underlord_pitofmalice_stun_round.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)    
    self:AddParticle(burn_fx, false, false, -1, false, false)
end