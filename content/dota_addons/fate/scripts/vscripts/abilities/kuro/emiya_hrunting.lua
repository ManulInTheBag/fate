emiya_hrunting = class({})

function emiya_hrunting:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("cast_range")

    if self:GetCaster():HasModifier("modifier_eagle_eye") then
        range = range + self:GetSpecialValueFor("bonus_range")
    end

    return range
end

function emiya_hrunting:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function emiya_hrunting:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()
    self.hTarget = hTarget

    self:EndCooldown()
    hCaster:GiveMana(self:GetManaCost(-1))

    hCaster:EmitSound("Hero_Invoker.EMP.Charge")

    self.pcMarker = ParticleManager:CreateParticleForTeam("particles/custom/archer/archer_broken_phantasm/archer_broken_phantasm_crosshead.vpcf", PATTACH_OVERHEAD_FOLLOW, hTarget, hCaster:GetTeamNumber())
    ParticleManager:SetParticleControl(self.pcMarker, 0, hTarget:GetAbsOrigin() + Vector(0,0,100)) 
    ParticleManager:SetParticleControl(self.pcMarker, 1, hTarget:GetAbsOrigin() + Vector(0,0,100))

    self.hrunting_particle = ParticleManager:CreateParticle( "particles/econ/events/ti4/teleport_end_ti4.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster )
    ParticleManager:SetParticleControl(self.hrunting_particle, 2, Vector( 255, 0, 0 ) )
    ParticleManager:SetParticleControlEnt(self.hrunting_particle, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", hCaster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.hrunting_particle, 3, hCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", hCaster:GetAbsOrigin(), true)

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if hTarget:IsHero()then
            Say(hPlayer, "Hrunting targets " .. FindName(hTarget:GetName()) .. ".", true)
        end
    end
end

function emiya_hrunting:OnChannelFinish(bInterrupted)
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()

    ParticleManager:DestroyParticle(self.pcMarker, false)
    ParticleManager:ReleaseParticleIndex(self.pcMarker)
    ParticleManager:DestroyParticle(self.hrunting_particle, false)
    ParticleManager:ReleaseParticleIndex(self.hrunting_particle)

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if bInterrupted or not hCaster:CanEntityBeSeenByMyTeam(hTarget) or not IsInSameRealm(hCaster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then 
            Say(hPlayer, "Hrunting failed.", true)
            return
        end
    end

    self:StartCooldown(self:GetCooldown(self:GetLevel()))
    local damage = self:GetSpecialValueFor("damage") + (hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100)
    hCaster:SpendMana(hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100, self)
    hCaster:StopSound("Hero_Invoker.EMP.Charge")
    hCaster:EmitSound("Emiya_Hrunt2")
    hCaster:RemoveModifierByName("modifier_hrunting_window")

    local tExtraData = { hrunt_damage = damage,
                         max_bounce = self:GetSpecialValueFor("max_bounce"), 
                         bounce_damage = self:GetSpecialValueFor("bounce_damage"), 
                         bounces = 0 }

    self:FireProjectile(hTarget, hCaster, tExtraData)
end

function emiya_hrunting:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
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
                                 max_bounce = self:GetSpecialValueFor("max_bounce"), 
                                 bounce_damage = self:GetSpecialValueFor("bounce_damage"), 
                                 bounces = (tData["bounces"] + 1) }

            self:FireProjectile(hBounceTarget, hTarget, tExtraData)
        end
    end
end

function emiya_hrunting:FireProjectile(hTarget, hSource, tExtraData)
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