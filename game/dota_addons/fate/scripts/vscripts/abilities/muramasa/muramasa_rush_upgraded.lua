muramasa_rush_upgraded = class({})
LinkLuaModifier("modifier_muramasa_rush_burn","abilities/muramasa/muramasa_rush", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_rush_mr","abilities/muramasa/muramasa_rush", LUA_MODIFIER_MOTION_NONE)

function muramasa_rush_upgraded:OnUpgrade()
    local caster = self:GetCaster() 
   if(caster:FindAbilityByName("muramasa_rush"):GetLevel()< self:GetLevel()) then
      caster:FindAbilityByName("muramasa_rush"):SetLevel(self:GetLevel())
   end
    
end

 
function muramasa_rush_upgraded:OnSpellStart()
    self.ChannelTime = 0
    local caster = self:GetCaster()
    caster.firstenemy = nil
    self.RushPoint = self:GetCursorPosition()
    caster:FindAbilityByName("muramasa_rush"):StartCooldown(caster:FindAbilityByName("muramasa_rush"):GetCooldown(caster:FindAbilityByName("muramasa_rush"):GetLevel()))

    
    if( caster:GetAbilityByIndex(0):GetName() ~="muramasa_dance") then
        caster:SwapAbilities("muramasa_dance", "muramasa_dance_upgraded", true, false)
    end
    if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
        caster:SwapAbilities("muramasa_throw", "muramasa_throw_upgraded", true, false)
    end
   

    if( caster:GetAbilityByIndex(2):GetName() ~="muramasa_rush") then
        caster:SwapAbilities("muramasa_rush", "muramasa_rush_upgraded", true, false)
    end

    local ability = self
   
    --caster:RemoveModifierByName("modifier_muramasa_rush_mr" )
    local speed = self:GetSpecialValueFor("speed")  
    local max_range = self:GetSpecialValueFor("range")  
    local range = (self.RushPoint - caster:GetAbsOrigin()):Length2D()
    if(range > max_range) then
        range = max_range

    end
    local rush_time = range/speed
    caster:AddNewModifier(caster, ability, "modifier_muramasa_rush_mr",{duration = rush_time })
    StartAnimation(caster, {duration=rush_time, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})

    local qdProjectile = 
    {
        Ability = ability,
        EffectName = "particles/muramasa/muramasa_throw_projectile.vpcf",
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = range,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 2.0,
        bDeleteOnHit = false,
        vVelocity = caster:GetForwardVector() * speed
    }
     
    
    local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", rush_time)
    local sin = Physics:Unit(caster)
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(caster:GetForwardVector() * speed)
    caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)

     
        self.rushfx = ParticleManager:CreateParticle("particles/muramasa/muramasa_rush_self.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
      
     
    Timers:CreateTimer("muramasa_rush", {
        endTime = rush_time,
        callback = function()
        caster:OnPreBounce(nil)
        caster:SetBounceMultiplier(0)
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,0))
        caster:RemoveModifierByName("pause_sealenabled")
     
        caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
        ParticleManager:DestroyParticle(  self.rushfx , true)
        ParticleManager:ReleaseParticleIndex(  self.rushfx )
    return end
    })

    caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
        Timers:RemoveTimer("muramasa_rush")
        unit:OnPreBounce(nil)
        unit:SetBounceMultiplier(0)
        unit:PreventDI(false)
        unit:SetPhysicsVelocity(Vector(0,0,0))
        unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        caster:RemoveModifierByName("pause_sealenabled")
   
        ParticleManager:DestroyParticle(  self.rushfx , true)
        ParticleManager:ReleaseParticleIndex(  self.rushfx )
        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
        ProjectileManager:DestroyLinearProjectile(projectile)
    end)

 
end
 

function muramasa_rush_upgraded:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil then return end
    local caster = self:GetCaster()
    if caster.firstenemy == nil then
        if hTarget:IsHero() and self:GetAutoCastState() == true  then
            caster.firstenemy = hTarget
            self.swordfx = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_in_enemy.vpcf", PATTACH_OVERHEAD_FOLLOW  , hTarget )
             
            Timers:CreateTimer( 1.2, function()
                caster.firstenemy = nil
                ParticleManager:DestroyParticle(  self.swordfx, true)
                ParticleManager:ReleaseParticleIndex(  self.swordfx)
            end)
        end
    end
    
    
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")
 

    hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
    DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    hTarget:AddNewModifier(caster, self , "modifier_muramasa_rush_burn",{duration = duration })
    giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration/2)
    caster:PerformAttack( hTarget, true, true, true, true, false, false, false )
    caster:PerformAttack( hTarget, true, true, true, true, false, false, false )
end
 
 

 