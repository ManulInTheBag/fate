LinkLuaModifier("modifier_okita_sandanzuki_charge", "abilities/okita/okita_sandanzuki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_sandanzuki_dash", "abilities/okita/okita_sandanzuki", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_okita_sandanzuki_dmg", "abilities/okita/okita_sandanzuki", LUA_MODIFIER_MOTION_NONE)

okita_sandanzuki = class({})

function okita_sandanzuki:CastFilterResult()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_sandanzuki:GetCustomCastError()
    return "#Sandanzuki_Active_Error"
end

function okita_sandanzuki:OnAbilityPhaseStart()
    EmitSoundOn("okita_first_step", self:GetCaster())
    return true
end

function okita_sandanzuki:OnAbilityPhaseInterrupted()
    StopSoundOn("okita_first_step", self:GetCaster())
end

function okita_sandanzuki:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_charge", {duration = self:GetSpecialValueFor("window_duration")})
    EmitSoundOn("Okita_Sandanzuki_Cast", caster)

    caster:SwapAbilities("okita_sandanzuki", "okita_sandanzuki_charge1", false, true)
end

function okita_sandanzuki:OnUpgrade()
    local ability = self:GetCaster():FindAbilityByName("okita_sandanzuki_release")
    if ability and ability:GetLevel() < self:GetLevel() then
        ability:SetLevel(self:GetLevel())
    end
end

okita_sandanzuki_charge1 = class({})

function okita_sandanzuki_charge1:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_sandanzuki_charge1:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_sandanzuki_charge1:OnSpellStart()
    local caster = self:GetCaster()
    --[[LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)]]
    EmitSoundOn("okita_second_step", caster)
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_dash", {})
    caster:SwapAbilities("okita_sandanzuki_charge1", "okita_sandanzuki_charge2", false, true)
end

okita_sandanzuki_charge2 = class({})

function okita_sandanzuki_charge2:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_sandanzuki_charge2:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_sandanzuki_charge2:OnSpellStart()
    local caster = self:GetCaster()
    --[[LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)]]
    EmitSoundOn("okita_third_step", caster)
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_dash", {})
    caster:SwapAbilities("okita_sandanzuki_charge2", "okita_sandanzuki_release", false, true)
end

okita_sandanzuki_charge3 = class({})

function okita_sandanzuki_charge3:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_sandanzuki_charge3:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_sandanzuki_charge3:OnSpellStart()
    local caster = self:GetCaster()
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    EmitSoundOn("okita_third_step", caster)
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_dash", {})
    caster:SwapAbilities("okita_sandanzuki_charge3", "okita_sandanzuki_release", false, true)
end

okita_sandanzuki_release = class({})

LinkLuaModifier("modifier_okita_sandanzuki_release", "abilities/okita/okita_sandanzuki", LUA_MODIFIER_MOTION_HORIZONTAL)

function okita_sandanzuki_release:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_sandanzuki_release:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end


function okita_sandanzuki_release:OnUpgrade()
    local ability = self:GetCaster():FindAbilityByName("okita_sandanzuki")
    if ability and ability:GetLevel() < self:GetLevel() then
        ability:SetLevel(self:GetLevel())
    end
end
function okita_sandanzuki_release:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function okita_sandanzuki_release:GetCastPoint()
    if self:GetCaster():HasModifier("modifier_tennen_active") and self:GetCaster():HasModifier("modifier_kenjitsu_attribute") then
        return self:GetSpecialValueFor("reduced_castpoint")
    else
        return self:GetSpecialValueFor("normal_castpoint")
    end
end

function okita_sandanzuki_release:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition() + RandomVector(1)
    local direction = (point - caster:GetAbsOrigin()):Normalized()
    --[[LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)]]
    self.kappa = false
    direction.z    = 0

    --caster:SwapAbilities("okita_sandanzuki", caster:GetAbilityByIndex(5):GetName(), true, false)
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_release", {})
    local qdProjectile = 
        {
            Ability = self,
            EffectName = nil, --"particles/custom/false_assassin/fa_quickdraw.vpcf",
            iMoveSpeed = self:GetSpecialValueFor("speed"),
            vSpawnOrigin = caster:GetOrigin(),
            fDistance = self:GetAOERadius(),
            fStartRadius = 200,
            fEndRadius = 200,
            Source = caster,
            bHasFrontalCone = true,
            bReplaceExisting = true,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 2.0,
            bDeleteOnHit = true,
            vVelocity = direction * self:GetSpecialValueFor("speed")
        }

        local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
end

function okita_sandanzuki_release:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil or self.kappa == true then return end

    local caster = self:GetCaster()
    local ability = self
    local damage = ability:GetSpecialValueFor("base_damage")
    if caster.IsKikuIchimonjiAcquired then
        damage = damage + caster:GetAgility()*self:GetSpecialValueFor("kiku_agi_ratio")
    end
    self.kappa = true
    --hTarget:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.9})
    local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(slashIndex, 0, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))
    Timers:CreateTimer(0.4, function()
        local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, hTarget:GetAbsOrigin())
    end)
    Timers:CreateTimer(0.8, function()
        EmitGlobalSound("Okita.Sandanzuki")
        DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        hTarget:RemoveModifierByName("modifier_master_intervention")
        hTarget:EmitSound("Tsubame_Slash_" .. math.random(1,3))
    end)
    Timers:CreateTimer(0.9, function()
        DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        hTarget:RemoveModifierByName("modifier_master_intervention")
        hTarget:EmitSound("Tsubame_Slash_" .. math.random(1,3))
    end)
    Timers:CreateTimer(1.0, function()
        DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PURE, 0, self, false)
        hTarget:RemoveModifierByName("modifier_master_intervention")
        hTarget:EmitSound("Tsubame_Focus")
    end)

end

modifier_okita_sandanzuki_release = class({})
function modifier_okita_sandanzuki_release:IsHidden() return true end
function modifier_okita_sandanzuki_release:IsDebuff() return false end
function modifier_okita_sandanzuki_release:IsPurgable() return false end
function modifier_okita_sandanzuki_release:IsPurgeException() return false end
function modifier_okita_sandanzuki_release:RemoveOnDeath() return true end
function modifier_okita_sandanzuki_release:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_sandanzuki_release:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_sandanzuki_release:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_okita_sandanzuki_release:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_sandanzuki_release:GetOverrideAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
function modifier_okita_sandanzuki_release:GetOverrideAnimationRate()
    return 2.0
end
function modifier_okita_sandanzuki_release:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       = self.ability:GetAOERadius()--self.ability:GetSpecialValueFor("distance")
        self.damage         = self.ability:GetSpecialValueFor("damage_per_hit")
        self.crit           = self.ability:GetSpecialValueFor("crit")
        self.delay_duration = self.ability:GetSpecialValueFor("delay_duration")

        self.second_targets_damage = self.ability:GetSpecialValueFor("second_targets_damage") * 0.01

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        self.AttackedTargets    = {}
        self.FirstTarget        = nil
        
        self.DamageToTargetsPercentTable = {}

        --self.parent:SetModifierStackCount("modifier_zenitsu_fear", self.parent, self.parent:GetModifierStackCount("modifier_zenitsu_fear", self.parent) + self.fear_charge)

        EmitGlobalSound("okita_mumyo")

        --[[local dash_fx = ParticleManager:CreateParticle("particles/heroes/anime_hero_zenitsu/zenitsu_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
                        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
                        ParticleManager:SetParticleControl(dash_fx, 2, self.parent:GetOrigin())
                        ParticleManager:SetParticleControl(dash_fx, 5, self.parent:GetOrigin())]]
        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:StartIntervalThink(FrameTime())
        
        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_okita_sandanzuki_release:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_okita_sandanzuki_release:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_okita_sandanzuki_release:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.parent:IsStunned() then
            return nil
        end

        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt

            if distance_will < 0 then
                --next_pos = self.point
            end

            self.parent:SetOrigin(next_pos)
            self.parent:FaceTowards(self.point)

            --self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_okita_sandanzuki_charge")
            self:Destroy()
        end
    end
end
function modifier_okita_sandanzuki_release:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_okita_sandanzuki_release:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_okita_sandanzuki_charge = class({})
function modifier_okita_sandanzuki_charge:IsHidden() return true end
function modifier_okita_sandanzuki_charge:IsDebuff() return false end
function modifier_okita_sandanzuki_charge:IsPurgable() return false end
function modifier_okita_sandanzuki_charge:IsPurgeException() return false end
function modifier_okita_sandanzuki_charge:RemoveOnDeath() return true end
function modifier_okita_sandanzuki_charge:OnDestroy()
    self:GetParent():SwapAbilities(self:GetParent():GetAbilityByIndex(5):GetName(), "okita_sandanzuki", false, true)
end
function modifier_okita_sandanzuki_charge:CheckState()
    local state =   {   --[MODIFIER_STATE_ROOTED] = true,
                        --[MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_okita_sandanzuki_charge:OnCreated()
    self.parent = self:GetParent()
    self.dash_fx = ParticleManager:CreateParticle("particles/okita/okita_afterimage_windrunner.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    self:StartIntervalThink(FrameTime())
end
function modifier_okita_sandanzuki_charge:OnIntervalThink()
    ParticleManager:SetParticleControl(self.dash_fx, 0, self.parent:GetAbsOrigin())

    self:AddParticle(self.dash_fx, false, false, -1, true, false)
end

modifier_okita_sandanzuki_dash = class({})
function modifier_okita_sandanzuki_dash:IsHidden() return true end
function modifier_okita_sandanzuki_dash:IsDebuff() return false end
function modifier_okita_sandanzuki_dash:IsPurgable() return false end
function modifier_okita_sandanzuki_dash:IsPurgeException() return false end
function modifier_okita_sandanzuki_dash:RemoveOnDeath() return true end
function modifier_okita_sandanzuki_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_sandanzuki_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_sandanzuki_dash:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_okita_sandanzuki_dash:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_sandanzuki_dash:GetOverrideAnimation()
    return ACT_DOTA_RUN
end
function modifier_okita_sandanzuki_dash:GetOverrideAnimationRate()
    return 0.3
end
function modifier_okita_sandanzuki_dash:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("dash_speed")
        self.distance       = self.ability:GetSpecialValueFor("distance")--self.ability:GetSpecialValueFor("distance")

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        --[[local dash_fx = ParticleManager:CreateParticle("particles/heroes/anime_hero_zenitsu/zenitsu_flash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
                        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
                        ParticleManager:SetParticleControl(dash_fx, 2, self.parent:GetOrigin())
                        ParticleManager:SetParticleControl(dash_fx, 5, self.parent:GetOrigin())]]
        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin())
        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:AddParticle(dash_fx, false, false, -1, true, false)
        
        --self.AttackedTargets = {}
        self:StartIntervalThink(FrameTime())

        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_okita_sandanzuki_dash:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_okita_sandanzuki_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_okita_sandanzuki_dash:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.parent:IsStunned() then
            return nil
        end

        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt

            if distance_will < 0 then
                --next_pos = self.point
            end

            self.parent:SetOrigin(next_pos)
            self.parent:FaceTowards(self.point)

            self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_okita_sandanzuki_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_okita_sandanzuki_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_okita_sandanzuki_dash:PlayEffects()
    --[[local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                        self.parent:GetAbsOrigin(),
                                        nil,
                                        self.parent:Script_GetAttackRange(),
                                        self.ability:GetAbilityTargetTeam(),
                                        self.ability:GetAbilityTargetType(),
                                        self.ability:GetAbilityTargetFlags(),
                                        FIND_CLOSEST,
                                        false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            self.AttackedTargets[enemy:entindex()] = true

            local damage_table =    {   victim       = enemy,
                                        attacker     = self.parent,
                                        damage       = self.parent:GetIdealSpeed() * 0.01 * ( self.ability:GetSpecialValueFor("dash_damage_ms") + self.caster:FindTalentValue("special_bonus_anime_zenitsu_15r") ),
                                        damage_type  = self.ability:GetAbilityDamageType(),
                                        --damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
                                        ability      = self.ability }

            ApplyDamage(damage_table)

            EmitSoundOn("Zenitsu.Flash.Cast.1", enemy)
        end
    end]]
end