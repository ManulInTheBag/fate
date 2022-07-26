LinkLuaModifier("modifier_hrunting_artillery_launch", "abilities/kuro/modifiers/modifier_chloe_hrunting_possible_target", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hrunting_cooldown", "abilities/kuro/modifiers/modifier_chloe_hrunting_possible_target", LUA_MODIFIER_MOTION_NONE)

kuro_hrunting = class({})

function kuro_hrunting:GetCooldown(iLevel)
    local cooldown = self:GetSpecialValueFor("cooldown")
    return cooldown
end

function kuro_hrunting:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("cast_range")

    if self:GetCaster():HasModifier("modifier_kuro_eagle_eye") then
        range = range + self:GetSpecialValueFor("bonus_range")
    end

    return range
end

function kuro_hrunting:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function kuro_hrunting:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

    if(filter == UF_SUCCESS) then
        if hTarget:GetName() == "npc_dota_ward_base" then 
            return UF_FAIL_CUSTOM       
        elseif not self:GetCaster():HasModifier("modifier_projection_active") and not self:GetCaster():HasModifier("modifier_kuro_projection_overpower") then
            return UF_FAIL_CUSTOM
        else
            return UF_SUCCESS
        end
    else
        return filter
    end
end

function kuro_hrunting:GetCustomCastErrorTarget(hTarget)
    if hTarget:GetName() == "npc_dota_ward_base" then
        return "#Invalid_Target"    
    else
        return "#Cannot_Cast"
    end
end

function kuro_hrunting:OnSpellStart()
    local hCaster = self:GetCaster()
    local hPlayer = hCaster:GetPlayerOwner()

    hCaster:EmitSound("Hero_Invoker.EMP.Charge")

    hCaster:AddNewModifier(hCaster, self, "modifier_hrunting_cooldown", {duration = self:GetCooldown(1)})

    local tTargets = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

    for i = 1, #tTargets do
        if tTargets[i]:HasModifier("modifier_chloe_hrunting_possible_target") then
            tTargets[i]:AddNewModifier(hCaster, self, "modifier_hrunting_artillery_launch", { Duration = 4.1 })
        end
    end

    self.hrunting_particle = ParticleManager:CreateParticle( "particles/econ/events/ti4/teleport_end_ti4.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster )
    ParticleManager:SetParticleControl(self.hrunting_particle, 2, Vector( 255, 0, 0 ) )
    ParticleManager:SetParticleControlEnt(self.hrunting_particle, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", hCaster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.hrunting_particle, 3, hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", hCaster:GetAbsOrigin(), true)
end

function kuro_hrunting:OnChannelFinish(bInterrupted)
    local hCaster = self:GetCaster()
    local hPlayer = hCaster:GetPlayerOwner()
    local tTargets = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

    ParticleManager:DestroyParticle(self.hrunting_particle, false)
    ParticleManager:ReleaseParticleIndex(self.hrunting_particle)

    if bInterrupted then
        return
    end

    local damage = self:GetSpecialValueFor("damage") + (hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100)
    local bounce = self:GetSpecialValueFor("max_bounce")
    --[[if hCaster:HasModifier("modifier_projection_active") then
        if hCaster:HasModifier("modifier_kuro_projection") then
            bounce = self:GetSpecialValueFor("projection_bounce")
        end
        if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
            if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then      
                hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
            elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
                hCaster:RemoveModifierByName("modifier_projection_active")
            end
        end
    end]]

    hCaster:SpendMana(hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100, self)
    hCaster:StopSound("Hero_Invoker.EMP.Charge")
    EmitGlobalSound("chloe_crane_4")
    hCaster:RemoveModifierByName("modifier_hrunting_window")

    local tExtraData = { hrunt_damage = damage,
                         max_bounce = bounce, 
                         bounce_damage = self:GetSpecialValueFor("bounce_damage"), 
                         bounces = 0 }
    for i = 1, #tTargets do
        if tTargets[i]:HasModifier("modifier_hrunting_artillery_launch") then
           self:FireProjectile(tTargets[i], hCaster, tExtraData)
        end
    end
end

function kuro_hrunting:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    local fTargetDamage = tData["hrunt_damage"]
    local fRadius = self:GetSpecialValueFor("radius")
    local fStun = self:GetSpecialValueFor("stun_duration")

    if tData["bounces"] > 0 then
        fTargetDamage = fTargetDamage * (tData["bounce_damage"] / 100)
        fStun = fStun * (tData["bounce_damage"] / 100 / tData["bounces"])
    end
    
    if IsSpellBlocked(hTarget) or hTarget:IsMagicImmune() then return end

    local explosionParticleIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_hrunting_area.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
    ParticleManager:SetParticleControl( explosionParticleIndex, 0, hTarget:GetAbsOrigin() )
    ParticleManager:SetParticleControl( explosionParticleIndex, 1, Vector( 600, 600, 0 ) )
    
    hTarget:EmitSound("Archer.HruntHit")
    DoDamage(hCaster, hTarget, fTargetDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", {Duration = fStun})     

    if tData["bounces"] + 1 <= tData["max_bounce"] then
        local hBounceTarget = nil

        local tTargets = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
        for i=1, #tTargets do
            if tTargets[i] ~= hTarget then
                hBounceTarget = tTargets[i]
                break
            end
        end

        if hBounceTarget ~= nil then
            local tExtraData = { hrunt_damage = fTargetDamage,
                                 max_bounce = tData["max_bounce"], 
                                 bounce_damage = self:GetSpecialValueFor("bounce_damage"), 
                                 bounces = (tData["bounces"] + 1) }

            self:FireProjectile(hBounceTarget, hTarget, tExtraData)
        end
    end
end

function kuro_hrunting:FireProjectile(hTarget, hSource, tExtraData)
    local hCaster = self:GetCaster()

    local tProjectile = {
        Target = hTarget,
        Source = hSource,
        Ability = self,
        EffectName = "particles/custom/archer/archer_hrunting_orb.vpcf",
        iMoveSpeed = 3000,
        vSourceLoc = hSource:GetAbsOrigin(),
        bDodgeable = false,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        ExtraData = tExtraData
    }

    ProjectileManager:CreateTrackingProjectile(tProjectile)
end