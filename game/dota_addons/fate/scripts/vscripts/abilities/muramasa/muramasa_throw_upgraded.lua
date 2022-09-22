muramasa_throw_upgraded = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_throw_collision_fix","abilities/muramasa/muramasa_throw", LUA_MODIFIER_MOTION_NONE)


function muramasa_throw_upgraded:OnUpgrade()
    local caster = self:GetCaster() 
	if(caster:FindAbilityByName("muramasa_throw"):GetLevel()< self:GetLevel()) then
		caster:FindAbilityByName("muramasa_throw"):SetLevel(self:GetLevel())
	end
	 
end

function muramasa_throw_upgraded:GetAnimeVectorTargetingRange()
    return   self:GetSpecialValueFor("throw_range")
end
function muramasa_throw_upgraded:GetAnimeVectorTargetingStartRadius()
    return 100
end
function muramasa_throw_upgraded:GetAnimeVectorTargetingEndRadius()
    return 100
end
function muramasa_throw_upgraded:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function muramasa_throw_upgraded:GetAnimeVectorTargetingColor()
    return Vector(124, 252, 0)
end

function muramasa_throw_upgraded:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local fire_location = caster:GetAttachmentOrigin(1) 
    if(self.fire_particle ~= nil ) then
        ParticleManager:DestroyParticle(  self.fire_particle , true)
		ParticleManager:ReleaseParticleIndex(  self.fire_particle )
    end
    if(self.fire_particle_2 ~= nil ) then
        ParticleManager:DestroyParticle(  self.fire_particle_2 , true)
		ParticleManager:ReleaseParticleIndex(  self.fire_particle_2 )
    end
    self.fire_particle = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_burning_hand.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.fire_particle, 1, caster, PATTACH_POINT_FOLLOW, "hand", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fire_particle, 0, caster, PATTACH_POINT_FOLLOW, "hand", Vector(0,0,0), true)
    Timers:CreateTimer( 0.5, function()
        ParticleManager:DestroyParticle(  self.fire_particle , true)
        ParticleManager:ReleaseParticleIndex(  self.fire_particle )
    end)
    return true
end

function muramasa_throw_upgraded:OnAbilityPhaseInterrupted()
    ParticleManager:DestroyParticle(  self.fire_particle , true)
    ParticleManager:ReleaseParticleIndex(  self.fire_particle )

end

function muramasa_throw_upgraded:OnSpellStart()

	local caster = self:GetCaster()
    caster:EmitSound("muramasa_grab_sound")
    caster:FindAbilityByName("muramasa_throw"):StartCooldown(caster:FindAbilityByName("muramasa_throw"):GetCooldown(caster:FindAbilityByName("muramasa_throw"):GetLevel()))

    if( caster:GetAbilityByIndex(0):GetName() ~="muramasa_dance") then
        caster:SwapAbilities("muramasa_dance", "muramasa_dance_upgraded", true, false)
    end
    if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
        caster:SwapAbilities("muramasa_throw", "muramasa_throw_upgraded", true, false)
    end
   

    if( caster:GetAbilityByIndex(2):GetName() ~="muramasa_rush") then
        caster:SwapAbilities("muramasa_rush", "muramasa_rush_upgraded", true, false)
    end
    local damage = self:GetSpecialValueFor("damage")
	local ability = self
    self.target = self:GetCursorTarget()
    if IsSpellBlocked(self.target ) then return end
	local direction = self:GetAnimeVectorTargetingMainDirection()
    local directionpoint = self:GetAnimeVectorTargetingRange()*self:GetAnimeVectorTargetingMainDirection() +self.target:GetAbsOrigin()
    local throw_direction
    local duration = self:GetSpecialValueFor("duration")
    local throw_range = self:GetSpecialValueFor("throw_range")
    local throw_speed = self:GetSpecialValueFor("throw_speed")
    local throw_duration = self:GetSpecialValueFor("throw_duration")
    caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.40}) 
    giveUnitDataDrivenModifier(caster,  self.target, "stunned", 0.8)
    self.target:AddNewModifier(caster, self, "modifier_muramasa_throw_collision_fix", {Duration = 0.31}) 
    self.fire_particle_2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_burning_hand.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.fire_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "leg", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fire_particle_2, 0, caster, PATTACH_POINT_FOLLOW, "leg", Vector(0,0,0), true)
    Timers:CreateTimer( 0.5, function()
        ParticleManager:DestroyParticle(  self.fire_particle_2 , true)
        ParticleManager:ReleaseParticleIndex(  self.fire_particle_2 )
    end)
    Timers:CreateTimer( 0.7, function()

        ParticleManager:DestroyParticle(  self.fire_particle , true)
		ParticleManager:ReleaseParticleIndex(  self.fire_particle )
        ParticleManager:DestroyParticle(  self.fire_particle_2 , true)
        ParticleManager:ReleaseParticleIndex(  self.fire_particle_2 )
    end)
    local throwTime 
    local counter = 1
    
    local turn = (directionpoint  -caster:GetAbsOrigin()):Normalized() 
    local casterstartvector = caster:GetForwardVector()
    local sin1 = Physics:Unit( caster)
    Timers:CreateTimer( 0, function()
    if(counter  == 7 or caster:IsAlive() == false or caster:IsStunned() == true or  self.target:IsStunned() == false) then 
        
       return end
    
       local vector =    casterstartvector + turn/( 2 ) * counter 
       vector.z = 0
    caster:SetForwardVector( vector)
 
    caster:FaceTowards(self.target:GetAbsOrigin())
 
    self.target:SetAbsOrigin(caster:GetAbsOrigin()+caster:GetForwardVector()*150 )
   
    counter = counter +1
 
    return 0.03
    end)
    if( caster:IsAlive() == false) then return end
    Timers:CreateTimer( 0.12, function()
        if( caster:IsAlive() == false or caster:IsStunned() == true or  self.target:IsStunned() == false) then return end
        caster:StopAnimation()
        StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_TORNADO, rate=1.0})
        self.target:SetPhysicsVelocity(Vector(0,0,2000))
        caster:SetPhysicsVelocity(Vector(0,0,2500))
    end)

    Timers:CreateTimer( 0.25, function()
        if( caster:IsAlive() == false or caster:IsStunned() == true or  self.target:IsStunned() == false) then 
            caster:SetBounceMultiplier(0)
            caster:PreventDI(false)
            caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
            self.target:SetBounceMultiplier(0)
            self.target:PreventDI(false)
            self.target:SetPhysicsVelocity(Vector(0,0,0))
              self.target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
                FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
                FindClearSpaceForUnit(  self.target,   self.target:GetAbsOrigin(), true)
                caster:SetPhysicsVelocity(Vector(0,0,0))
            return
        end
        throwTime = GameRules:GetGameTime()
        throw_direction = (directionpoint-self.target:GetAbsOrigin()):Normalized()
        local sin = Physics:Unit( self.target)
        --self.target:SetPhysicsFriction(0)
        --caster:OnPreBounce(nil)
        caster:SetBounceMultiplier(0)
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,-1000))
        caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        self.target:SetPhysicsVelocity(throw_direction* throw_speed  )
        self.target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
       
        Timers:CreateTimer( 0.4, function()
       
            FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
            caster:SetPhysicsVelocity(Vector(0,0,0))
        end)

        local qdProjectile = 
	    {
		    Ability = ability,
            EffectName = "particles/muramasa/muramasa_throw_projectile_lvl2_1.vpcf",
            iMoveSpeed = throw_speed*1.2,
            vSpawnOrigin =  self.target:GetOrigin(),
            fDistance = throw_range,
            fStartRadius = 100,
            fEndRadius = 50,
            Source = caster,
            bHasFrontalCone = false,
            bReplaceExisting = true,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 2.0,
		    bDeleteOnHit = false,
       
		    vVelocity = throw_direction * throw_speed*1.2
	    }
        local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
        giveUnitDataDrivenModifier(caster,  self.target, "no_collision", throw_duration)
        self.fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_projectile_lvl2.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.target)
        self.target:FaceTowards(directionpoint)
        self.target:SetForwardVector( caster:GetForwardVector())
        Timers:CreateTimer( 0.3, function()
            if(self.fx == nil) then return end
            ParticleManager:DestroyParticle(  self.fx , true)
            ParticleManager:ReleaseParticleIndex(  self.fx )
            self.fx = nil
        end)
        Timers:CreateTimer("muramasa_throw", {
            endTime = throw_duration,
            callback = function()
                --self.target:OnPreBounce(nil)
                self.target:SetBounceMultiplier(0)
                self.target:PreventDI(false)
                self.target:SetPhysicsVelocity(Vector(0,0,0))
                self.target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
            FindClearSpaceForUnit(self.target,  self.target:GetAbsOrigin(), true)
         
        return end
        })
        self.target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
            Timers:RemoveTimer("muramasa_throw")
            unit:EmitSound("muramasa_throw_impact")
            unit:OnPreBounce(nil)
            unit:SetBounceMultiplier(0)
            unit:PreventDI(false)
            unit:SetPhysicsVelocity(Vector(0,0,0))
            ProjectileManager:DestroyLinearProjectile(projectile)
            if(self.fx ~= nil) then
                ParticleManager:DestroyParticle(  self.fx , true)
                ParticleManager:ReleaseParticleIndex(  self.fx )
                self.fx = nil
            end
             FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
            local impact_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
            ParticleManager:SetParticleControl(impact_fx, 0, self.target:GetAbsOrigin())
            local targets = FindUnitsInRadius(caster:GetTeam(), self.target:GetAbsOrigin(), nil, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do            
            DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
            v:AddNewModifier(caster, self, "modifier_stunned", {Duration = duration})     
            end 

          
        end)
	end)
    

   

    function muramasa_throw_upgraded:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    
        if hTarget == nil then return end
        if hTarget == self.target then return end
        if hTarget:GetTeam() ~= self.target:GetTeam() then return end
        local duration = self:GetSpecialValueFor("duration")
        local caster = self:GetCaster()
        local damage = self:GetSpecialValueFor("damage")
        local sin2 = Physics:Unit( hTarget)
        hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
     
        --Timers:RemoveTimer("muramasa_throw")
        local impact_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(impact_fx, 0, hTarget:GetAbsOrigin())
        local throw_duration_last = throw_duration - (GameRules:GetGameTime()-throwTime)
        DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        hTarget:SetPhysicsVelocity(Vector(throw_direction.x,throw_direction.y,0)* throw_speed*1.3 )
        hTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        hTarget:AddNewModifier(caster, self, "modifier_stunned", {Duration = throw_duration_last})  
        Timers:CreateTimer( throw_duration_last, function()
            hTarget:SetBounceMultiplier(0)
            hTarget:PreventDI(false)
            hTarget:SetPhysicsVelocity(Vector(0,0,0))
            FindClearSpaceForUnit(hTarget, hTarget:GetAbsOrigin(), true)
            local targets = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do            
            v:AddNewModifier(caster, self, "modifier_stunned", {Duration = duration})     
            end     
        end)


        hTarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
               
            unit:OnPreBounce(nil)
            unit:SetBounceMultiplier(0)
            unit:PreventDI(false)
            unit:SetPhysicsVelocity(Vector(0,0,0))
            FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
            local impact_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
            ParticleManager:SetParticleControl(impact_fx, 0, self.target:GetAbsOrigin())
            unit:AddNewModifier(caster, self, "modifier_stunned", {Duration = duration})   
          
        end)
    end

 
end