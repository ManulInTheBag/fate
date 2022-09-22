LinkLuaModifier("modifier_okita_sandanzuki_pepeg", "abilities/okita/okita_jet_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_jet_dash", "abilities/okita/okita_jet_2", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_okita_jet_dmg", "abilities/okita/okita_jet_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_jet_cd", "abilities/okita/okita_jet", LUA_MODIFIER_MOTION_NONE)

okita_jet = class({})

function okita_jet:OnSpellStart()
    local caster = self:GetCaster()
    --EmitSoundOn("Okita_Sandanzuki_Cast", caster)

    --caster:SwapAbilities("okita_jet", "okita_jet_charge1", false, true)

    EmitGlobalSound("okita_jet_cast")

    caster:AddNewModifier(caster, self, "modifier_okita_jet_cd", {duration = self:GetCooldown(1)})

    caster.jet_fx = ParticleManager:CreateParticle("particles/okita/okita_jet_fly.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(caster.jet_fx, 0, caster:GetAbsOrigin())
    Timers:CreateTimer(self:GetSpecialValueFor("window_duration") + 5.15, function()
        ParticleManager:DestroyParticle(caster.jet_fx, false)
    end)
    local fx1 = ParticleManager:CreateParticle("particles/okita/okita_jet_cast_runes.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(fx1, 0, caster:GetAbsOrigin())
end

function okita_jet:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") then
        return UF_FAIL_CUSTOM
    elseif IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    --[[elseif self:IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
        return UF_FAIL_CUSTOM]] --smth causes bugs here
    else
        return UF_SUCCESS
    end
end

function okita_jet:GetCustomCastErrorLocation(hLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") then
        return "#Sandanzuki_Active_Error"
    elseif not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return "#Wrong_Target_Location"
    end
end

function okita_jet:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    if bInterrupted then
        StopGlobalSound("okita_jet_cast")
        if caster:GetAbilityByIndex(3):GetName() ~= "okita_weak_constitution_summer" then
            caster:SwapAbilities("okita_weak_constitution_summer", caster:GetAbilityByIndex(3):GetName(), true, false)
        end
        return
    end
    caster:SwapAbilities(caster:GetAbilityByIndex(3):GetName(), "okita_jet_charge1", false, true)
    caster:AddNewModifier(caster, self, "modifier_okita_sandanzuki_pepeg", {duration = self:GetSpecialValueFor("window_duration")})
end

okita_jet_charge1 = class({})

function okita_jet_charge1:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_jet_charge1:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_jet_charge1:OnSpellStart()
    local caster = self:GetCaster()
    --[[LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)]]
    EmitGlobalSound("okita_jet21")
    caster:AddNewModifier(caster, self, "modifier_okita_jet_dash", {})
    caster:SwapAbilities("okita_jet_charge1", "okita_jet_charge2", false, true)
end

okita_jet_charge2 = class({})

function okita_jet_charge2:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_jet_charge2:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_jet_charge2:OnSpellStart()
    local caster = self:GetCaster()
    --[[LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zenitsu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)]]
    EmitGlobalSound("okita_jet22")
    caster:AddNewModifier(caster, self, "modifier_okita_jet_dash", {})
    caster:SwapAbilities("okita_jet_charge2", "okita_jet_release", false, true)
end

okita_jet_release = class({})

LinkLuaModifier("modifier_okita_jet_release", "abilities/okita/okita_jet_2", LUA_MODIFIER_MOTION_HORIZONTAL)

function okita_jet_release:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function okita_jet_release:GetCustomCastErrorLocation(hLocation)
    return "#Wrong_Target_Location"
end

function okita_jet_release:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function okita_jet_release:OnSpellStart()
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
    caster:AddNewModifier(caster, self, "modifier_okita_jet_release", {})
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
            bDeleteOnHit = false,
            vVelocity = direction * self:GetSpecialValueFor("speed")
        }

        local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
end

function okita_jet_release:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil or self.kappa == true then return end

    local caster = self:GetCaster()
    local ability = caster:FindAbilityByName("okita_sandanzuki")
    local damage = ability:GetSpecialValueFor("base_damage")
    if caster.IsKikuIchimonjiAcquired then
        damage = damage + caster:GetAgility()*self:GetSpecialValueFor("kiku_agi_ratio")
    end
    --self.kappa = true
    local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(slashIndex, 0, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))
    Timers:CreateTimer(0.4, function()
        local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, hTarget:GetAbsOrigin())
    end)
    Timers:CreateTimer(0.8, function()
        --EmitGlobalSound("Okita.Sandanzuki")
        DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
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

modifier_okita_jet_release = class({})
function modifier_okita_jet_release:IsHidden() return true end
function modifier_okita_jet_release:IsDebuff() return false end
function modifier_okita_jet_release:IsPurgable() return false end
function modifier_okita_jet_release:IsPurgeException() return false end
function modifier_okita_jet_release:RemoveOnDeath() return true end
function modifier_okita_jet_release:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_jet_release:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_jet_release:CheckState()
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
function modifier_okita_jet_release:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_jet_release:GetOverrideAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
function modifier_okita_jet_release:GetOverrideAnimationRate()
    return 2.0
end
function modifier_okita_jet_release:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       = self.ability:GetAOERadius()--self.ability:GetSpecialValueFor("distance")
        self.second_targets_damage = self.ability:GetSpecialValueFor("second_targets_damage") * 0.01

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance
        EmitGlobalSound("okita_jet23")
        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:StartIntervalThink(FrameTime())
    end
end
function modifier_okita_jet_release:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_okita_jet_release:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_okita_jet_release:UpdateHorizontalMotion(me, dt)
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
                next_pos = self.point
            end

            self.parent:SetOrigin(next_pos)
            self.parent:FaceTowards(self.point)

            --self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_okita_sandanzuki_pepeg")
            self:Destroy()
        end
    end
end
function modifier_okita_jet_release:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_okita_jet_release:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_okita_sandanzuki_pepeg = class({})
function modifier_okita_sandanzuki_pepeg:IsHidden() return true end
function modifier_okita_sandanzuki_pepeg:IsDebuff() return false end
function modifier_okita_sandanzuki_pepeg:IsPurgable() return false end
function modifier_okita_sandanzuki_pepeg:IsPurgeException() return false end
function modifier_okita_sandanzuki_pepeg:RemoveOnDeath() return true end
function modifier_okita_sandanzuki_pepeg:OnDestroy()
    ParticleManager:DestroyParticle(self.parent.jet_fx, false)
    if self:GetParent():GetAbilityByIndex(3):GetName() ~= "okita_weak_constitution_summer" then
        self:GetParent():SwapAbilities(self:GetParent():GetAbilityByIndex(3):GetName(), "okita_weak_constitution_summer", false, true)
    end
end
function modifier_okita_sandanzuki_pepeg:CheckState()
    local state =   {   --[MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                        [MODIFIER_STATE_FLYING] = true,
                    }
    return state
end
function modifier_okita_sandanzuki_pepeg:OnCreated()
    self.parent = self:GetParent()
    self.dash_fx = ParticleManager:CreateParticle("particles/okita/okita_afterimage_windrunner.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    self:StartIntervalThink(FrameTime())
end
function modifier_okita_sandanzuki_pepeg:OnIntervalThink()
    ParticleManager:SetParticleControl(self.dash_fx, 0, self.parent:GetAbsOrigin())

    self:AddParticle(self.dash_fx, false, false, -1, true, false)
end

modifier_okita_jet_dash = class({})
function modifier_okita_jet_dash:IsHidden() return true end
function modifier_okita_jet_dash:IsDebuff() return false end
function modifier_okita_jet_dash:IsPurgable() return false end
function modifier_okita_jet_dash:IsPurgeException() return false end
function modifier_okita_jet_dash:RemoveOnDeath() return true end
function modifier_okita_jet_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_jet_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_jet_dash:CheckState()
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
function modifier_okita_jet_dash:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_jet_dash:GetOverrideAnimation()
    return ACT_DOTA_RUN
end
function modifier_okita_jet_dash:GetOverrideAnimationRate()
    return 0.3
end
function modifier_okita_jet_dash:OnCreated(table)
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

        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin())
        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:AddParticle(dash_fx, false, false, -1, true, false)
        
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_okita_jet_dash:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_okita_jet_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_okita_jet_dash:UpdateHorizontalMotion(me, dt)
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
                next_pos = self.point
            end

            self.parent:SetOrigin(next_pos)
            self.parent:FaceTowards(self.point)

            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_okita_jet_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_okita_jet_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end