muramasa_throw = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_throw_collision_fix","abilities/muramasa/muramasa_throw", LUA_MODIFIER_MOTION_NONE)

function muramasa_throw:OnUpgrade()
    local caster = self:GetCaster() 
	if(caster:FindAbilityByName("muramasa_throw_upgraded"):GetLevel()< self:GetLevel()) then
		caster:FindAbilityByName("muramasa_throw_upgraded"):SetLevel(self:GetLevel())
	end
	 
end

function muramasa_throw:GetAnimeVectorTargetingRange()
    return   self:GetSpecialValueFor("throw_range")
end
function muramasa_throw:GetAnimeVectorTargetingStartRadius()
    return 100
end
function muramasa_throw:GetAnimeVectorTargetingEndRadius()
    return 100
end
function muramasa_throw:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function muramasa_throw:GetAnimeVectorTargetingColor()
    return Vector(124, 252, 0)
end

function muramasa_throw:OnAbilityPhaseStart()
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

function muramasa_throw:OnAbilityPhaseInterrupted()
    ParticleManager:DestroyParticle(  self.fire_particle , true)
    ParticleManager:ReleaseParticleIndex(  self.fire_particle )

end

function muramasa_throw:OnSpellStart()

	local caster = self:GetCaster()
    caster:FindAbilityByName("muramasa_throw_upgraded"):StartCooldown(caster:FindAbilityByName("muramasa_throw_upgraded"):GetCooldown(caster:FindAbilityByName("muramasa_throw_upgraded"):GetLevel()))
    caster:EmitSound("muramasa_grab_sound")
    local damage = self:GetSpecialValueFor("damage")
     caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.40}) 
	local ability = self
    self.target = self:GetCursorTarget()
    if IsSpellBlocked(self.target ) then return end
	local direction = self:GetAnimeVectorTargetingMainDirection()
    local directionpoint = self:GetAnimeVectorTargetingRange()*self:GetAnimeVectorTargetingMainDirection() +self.target:GetAbsOrigin()
  
    local duration = self:GetSpecialValueFor("duration")
    local throw_range = self:GetSpecialValueFor("throw_range")
    local throw_speed = self:GetSpecialValueFor("throw_speed")
    local throw_duration = self:GetSpecialValueFor("throw_duration")
    giveUnitDataDrivenModifier(caster,  self.target, "stunned", 0.8)

    self.target:AddNewModifier(caster, self, "modifier_muramasa_throw_collision_fix", {Duration = 0.31}) 
    self.fire_particle_2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_burning_hand.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.fire_particle_2, 1, caster, PATTACH_POINT_FOLLOW, "leg", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fire_particle_2, 0, caster, PATTACH_POINT_FOLLOW, "leg", Vector(0,0,0), true)
    Timers:CreateTimer( 0.7, function()

        ParticleManager:DestroyParticle(  self.fire_particle , true)
		ParticleManager:ReleaseParticleIndex(  self.fire_particle )
        ParticleManager:DestroyParticle(  self.fire_particle_2 , true)
        ParticleManager:ReleaseParticleIndex(  self.fire_particle_2 ) 
    end)
    local counter = 1
    
    local turn = (directionpoint  -caster:GetAbsOrigin()):Normalized() 
    local casterstartvector = caster:GetForwardVector()
 
    Timers:CreateTimer( 0, function()
    if(counter  == 5 or   caster:IsAlive() == false  or caster:IsStunned() == true or  self.target:IsStunned() == false ) then 
        
       return end
    local vector =  casterstartvector + turn/( 2.5 ) * counter
    vector.z = 0
    caster:SetForwardVector( vector)
 
    caster:FaceTowards(self.target:GetAbsOrigin())
 
    self.target:SetAbsOrigin(caster:GetAbsOrigin()+caster:GetForwardVector()*150 )
   
    counter = counter +1
 
    return 0.03
    end)

    Timers:CreateTimer( 0.16, function()
        if( caster:IsAlive() == false  or caster:IsStunned() == true or  self.target:IsStunned() == false) then return end
        local throw_direction = (directionpoint-self.target:GetAbsOrigin()):Normalized()
        local sin = Physics:Unit( self.target)
        self.target:SetPhysicsFriction(0)
        self.target:SetPhysicsVelocity(throw_direction* throw_speed  )
        self.target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      
        local qdProjectile = 
	    {
		    Ability = ability,
            EffectName = "particles/muramasa/muramasa_throw_projectile.vpcf",
            iMoveSpeed = throw_speed,
            vSpawnOrigin =  self.target:GetOrigin(),
            fDistance = throw_range,
            fStartRadius = 100,
            fEndRadius = 100,
            Source = caster,
            bHasFrontalCone = true,
            bReplaceExisting = true,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            fExpireTime = GameRules:GetGameTime() + 2.0,
		    bDeleteOnHit = false,
		    vVelocity = throw_direction * throw_speed
	    }
        local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
         self.target:SetGroundBehavior (PHYSICS_GROUND_LOCK)
        Timers:CreateTimer("muramasa_throw", {
            endTime = throw_duration,
            callback = function()
                self.target:OnPreBounce(nil)
                self.target:SetBounceMultiplier(0)
                self.target:PreventDI(false)
                self.target:SetPhysicsVelocity(Vector(0,0,0))
                  self.target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
            FindClearSpaceForUnit(target,  self.target:GetAbsOrigin(), true)
         
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
    

   

    function muramasa_throw:OnProjectileHit_ExtraData(hTarget, vLocation, table)
        if hTarget == nil then return end
        if hTarget == self.target then return end
        if hTarget:GetTeam() ~= self.target:GetTeam() then return end
        local caster = self:GetCaster()
        local damage = self:GetSpecialValueFor("damage")
        
        hTarget:EmitSound("muramasa_throw_impact")
     
        Timers:RemoveTimer("muramasa_throw")
        local impact_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(impact_fx, 0, hTarget:GetAbsOrigin())
       
        local targets = FindUnitsInRadius(caster:GetTeam(), self.target:GetAbsOrigin(), nil, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = duration})     
        end 
        self.target:OnPreBounce(nil)
        self.target:SetBounceMultiplier(0)
        self.target:PreventDI(false)
        self.target:SetPhysicsVelocity(Vector(0,0,0))
        self.target:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
    end
end

modifier_muramasa_throw_collision_fix = class({})
 
 
function modifier_muramasa_throw_collision_fix:CheckState()
    return { [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true }
end

function modifier_muramasa_throw_collision_fix:IsHidden()	
    return true
end
function modifier_muramasa_throw_collision_fix:RemoveOnDeath()return true end 
function modifier_muramasa_throw_collision_fix:IsDebuff() 	return true end
 
