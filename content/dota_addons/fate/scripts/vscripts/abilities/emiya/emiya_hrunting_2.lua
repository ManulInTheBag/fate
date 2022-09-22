emiya_hrunting_2 = class({})

LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function emiya_hrunting_2:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("cast_range")

    if self:GetCaster():HasModifier("modifier_eagle_eye") then
        range = range + self:GetSpecialValueFor("bonus_range")
    end

    return range
end

function emiya_hrunting_2:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function emiya_hrunting_2:OnChannelThink(fInterval)
    self.ChannelTime = (self.ChannelTime or 0) + fInterval
end

function emiya_hrunting_2:OnSpellStart()
    local hCaster = self:GetCaster()
    self.TargetPos = self:GetCursorPosition()
    self.hTarget = CreateUnitByName("hrunt_illusion", self.TargetPos, true, hCaster, nil, hCaster:GetOpposingTeamNumber())
    self.hTarget:SetModel("models/development/invisiblebox.vmdl")
    self.hTarget:SetOriginalModel("models/development/invisiblebox.vmdl")
    self.hTarget:SetModelScale(1)
    self.hTarget:SetBaseMagicalResistanceValue(0)
    self.hTarget.IsHruntDummy = true
    local unseen = self.hTarget:FindAbilityByName("dummy_unit_passive")
    unseen:SetLevel(1)
    Timers:CreateTimer(0.033, function()
        self.hTarget:SetBaseMaxHealth(9999999)
        self.hTarget:SetMaxHealth(9999999)
        self.hTarget:ModifyHealth(9999999, nil, false, 0)
    end)
    Timers:CreateTimer(10, function()
        if IsValidEntity(self.hTarget) and not self.hTarget:IsNull() then 
            self.hTarget:ForceKill(false)
            self.hTarget:AddEffects(EF_NODRAW)
            --illusion:SetAbsOrigin(Vector(10000,10000,0))
        end
    end)
    local hPlayer = hCaster:GetPlayerOwner()
    local hTarget = self.hTarget
    self.ChannelTime = 0

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

function emiya_hrunting_2:OnChannelFinish(bInterrupted)
    local hCaster = self:GetCaster()
    --self.hTarget = CreateUnitByName("pseudo_illusion", illusionSpawnLoc, true, target, nil, target:GetTeamNumber())
    local hPlayer = hCaster:GetPlayerOwner()
    local hTarget = self.hTarget

    ParticleManager:DestroyParticle(self.pcMarker, false)
    ParticleManager:ReleaseParticleIndex(self.pcMarker)
    ParticleManager:DestroyParticle(self.hrunting_particle, false)
    ParticleManager:ReleaseParticleIndex(self.hrunting_particle)

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if bInterrupted or not IsInSameRealm(hCaster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then 
            Say(hPlayer, "Hrunting failed.", true)
            return
        end
    end

    if self.ChannelTime < 1.5 then return end

    self:StartCooldown(self:GetCooldown(self:GetLevel()))
    local damage = self:GetSpecialValueFor("damage") + (hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100)
    hCaster:SpendMana(hCaster:GetMana() * self:GetSpecialValueFor("mana_used") / 100, self)    

    local enemy = PickRandomEnemy(hCaster)

    if enemy then
        hCaster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 3 })
    end

    hCaster:StopSound("Hero_Invoker.EMP.Charge")
    --hCaster:EmitSound("Emiya_Hrunt" .. math.random(1,2))
    EmitGlobalSound("Emiya_Hrunt" .. math.random(1,2))
    hCaster:RemoveModifierByName("modifier_hrunting_window")

    local tExtraData = { hrunt_damage = damage,
                         max_bounce = self:GetSpecialValueFor("max_bounce"), 
                         bounce_damage = self:GetSpecialValueFor("bounce_damage"), 
                         bounces = 0 }

    self:FireProjectile(hTarget, hCaster, tExtraData)
end

function emiya_hrunting_2:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    local fTargetDamage = tData["hrunt_damage"]
    local fStun = self:GetSpecialValueFor("stun_duration")

    local explosionParticleIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_hrunting_area.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
    ParticleManager:SetParticleControl( explosionParticleIndex, 0, hTarget:GetAbsOrigin() )
    ParticleManager:SetParticleControl( explosionParticleIndex, 1, Vector( 600, 600, 0 ) )
    
    hTarget:EmitSound("Archer.HruntHit")
    local targets = FindUnitsInRadius(hCaster:GetTeam(), self.TargetPos, nil, 600, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(targets) do
        DoDamage(hCaster, v, fTargetDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        v:AddNewModifier(hCaster, v, "modifier_stunned", {Duration = fStun})
    end
end

function emiya_hrunting_2:FireProjectile(hTarget, hSource, tExtraData)
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