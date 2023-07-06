kuro_broken_phantasm = class({})

--require('libraries/attachments')

function kuro_broken_phantasm:GetCooldown(iLevel)
    local cooldown = self:GetSpecialValueFor("cooldown")

    --[[if self:GetCaster():HasModifier("modifier_kuro_projection") then
        cooldown = cooldown - (cooldown * 35 / 100)
    end]]

    return cooldown
end

function kuro_broken_phantasm:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("cast_range")

    if self:GetCaster():HasModifier("modifier_kuro_eagle_eye") then
        range = range + self:GetSpecialValueFor("bonus_range")
    end

    return range
end

function kuro_broken_phantasm:GetAOERadius()
    return 350
end

function kuro_broken_phantasm:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()
    self.hTarget = hTarget
	
    self:EndCooldown()
    hCaster:GiveMana(self:GetManaCost(-1))

    --print(Attachments:GetAttachmentDatabase())

    --[[local attach_property = { pitch = 0,
                              yaw = 92,
                              roll = 180,
                              XPos = 0,
                              YPos = 0,
                              ZPos = 0,
                              Animation = ACT_DOTA_IDLE }

    Attachments:AttachProp(hCaster, "attach_attack2", "models/kuro/kuro_bow.vmdl", 1, attach_property)]]

    --[[self.prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/kuro/kuro_bow.vmdl", DefaultAnim=ACT_DOTA_IDLE, targetname=DoUniqueString("prop_dynamic")})
    self.prop:SetModelScale(1)
    self.prop:SetParent(hCaster, "attach_attack2")]]

    self.pcMarker = ParticleManager:CreateParticleForTeam("particles/custom/archer/archer_broken_phantasm/archer_broken_phantasm_crosshead.vpcf", PATTACH_OVERHEAD_FOLLOW, hTarget, hCaster:GetTeamNumber())
    ParticleManager:SetParticleControl(self.pcMarker, 0, hTarget:GetAbsOrigin() + Vector(0,0,100)) 
    ParticleManager:SetParticleControl(self.pcMarker, 1, hTarget:GetAbsOrigin() + Vector(0,0,100))

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if hTarget:IsHero()then
            Say(hPlayer, "Broken Phantasm targets " .. FindName(hTarget:GetName()) .. ".", true)
        end
    end
end

function kuro_broken_phantasm:OnChannelFinish(bInterrupted)
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local hPlayer = hCaster:GetPlayerOwner()
   
    if(self.pcMarker ~= null) then
        ParticleManager:DestroyParticle(self.pcMarker, false)
        ParticleManager:ReleaseParticleIndex(self.pcMarker)
    end
    if IsSpellBlocked(hTarget) then 
        Say(hPlayer, "Broken Phantasm failed.", true)
        self:StartCooldown(self:GetCooldown(self:GetLevel()))
        hCaster:SpendMana(self:GetManaCost(-1), self)
        return 
    end
    --[[local prop = Attachments:GetCurrentAttachment(hCaster, "attach_attack2")
    if not prop:IsNull() then prop:RemoveSelf() end]]

    if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
        if bInterrupted or not hCaster:CanEntityBeSeenByMyTeam(hTarget) or hCaster:GetRangeToUnit(hTarget) > 4500 or hCaster:GetMana() < self:GetManaCost(-1) or not IsInSameRealm(hCaster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then 
            Say(hPlayer, "Broken Phantasm failed.", true)
            return
        end
    end

    self:StartCooldown(self:GetCooldown(self:GetLevel()))
    hCaster:SpendMana(self:GetManaCost(-1), self)
    hCaster:EmitSound("chloe_broken")

    local tProjectile = {
        Target = hTarget,
        Source = hCaster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf",
        iMoveSpeed = 3000,
        vSourceLoc = hCaster:GetAbsOrigin(),
        bDodgeable = true,
        bIsAttack = true,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    }
    ProjectileManager:CreateTrackingProjectile(tProjectile)
end

function kuro_broken_phantasm:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    local fTargetDamage = self:GetSpecialValueFor("target_damage") + self:GetSpecialValueFor("splash_damage")
    local fSplashDamage = self:GetSpecialValueFor("splash_damage")
    if hCaster:HasModifier("modifier_projection_active") then
        fTargetDamage = self:GetSpecialValueFor("target_damage") + self:GetSpecialValueFor("splash_damage") + hCaster:GetAbilityByIndex(5):GetSpecialValueFor("broken_damage")*hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()
        fSplashDamage = self:GetSpecialValueFor("splash_damage") + hCaster:GetAbilityByIndex(5):GetSpecialValueFor("broken_damage")*hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()/2
    end
    --hCaster:RemoveModifierByName("modifier_projection_active")
    local fRadius = self:GetSpecialValueFor("radius")
    local fStun = self:GetSpecialValueFor("stun_duration")
    
     

    local pcExplosion = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
    ParticleManager:SetParticleControl(pcExplosion, 3, hTarget:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pcExplosion)
    
    hTarget:EmitSound("Misc.Crash")
    DoDamage(hCaster, hTarget, fTargetDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    if not hTarget:IsMagicImmune() then
        hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", {Duration = fStun})
    end
    local tTargets = FindUnitsInRadius(hCaster:GetTeam(), hTarget:GetAbsOrigin(), nil, fRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
    for k,v in pairs(tTargets) do
        if v ~= hTarget then
            DoDamage(hCaster, v, fSplashDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
    end
end

--[[function kuro_broken_phantasm:OnUpgrade()
    local hrunt = self:GetCaster():FindAbilityByName("emiya_hrunting")
    hrunt:SetLevel(self:GetLevel())
end]]