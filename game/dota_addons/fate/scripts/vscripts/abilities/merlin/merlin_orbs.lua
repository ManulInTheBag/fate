LinkLuaModifier("modifier_merlin_orb_silence","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
merlin_orbs = class({})

function merlin_orbs:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	if IsSpellBlocked(target) then return end
	caster:EmitSound("merlin_orbs_sent")
	caster:FindAbilityByName("merlin_charisma"):AttStack() 
	if(caster.RapidChantingAcquired) then
		local cd1 = caster:GetAbilityByIndex(0):GetCooldownTimeRemaining()
		
		local cd3 = caster:GetAbilityByIndex(5):GetCooldownTimeRemaining()
		caster:GetAbilityByIndex(0):EndCooldown()
	
		caster:GetAbilityByIndex(5):EndCooldown()
		if(cd1 > 0 ) then
			caster:GetAbilityByIndex(0):StartCooldown(cd1 -1)
		end
		if(caster:GetAbilityByIndex(2):GetName() ~= "merlin_garden_of_avalon") then
			local cd2 = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()
			caster:GetAbilityByIndex(2):EndCooldown()
			if(cd2 > 0 ) then
				caster:GetAbilityByIndex(2):StartCooldown(cd2 -1)
			end
		end
		if(cd3 > 0 ) then
			caster:GetAbilityByIndex(5):StartCooldown(cd3 -1)
		end
	end
 
    self.start_location = caster:GetAbsOrigin()
    caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.40}) 
    Timers:CreateTimer(0.5, function() 
		if   target:IsAlive() then
			self.target = target 
			local projectile1 = {
		        Target = target,
		  
		        Ability = ability,
		        EffectName = "particles/merlin/merlin_tracking_orb.vpcf",
		        iMoveSpeed = self:GetSpecialValueFor("speed") + math.random(-300,0),
		        vSpawnOrigin = caster:GetAbsOrigin()+ Vector(math.random(-200,200),math.random(-200,200),math.random(-100,100)),
		        bDodgeable = true,
				Source = caster,  
				bDeleteOnHit = false,
				bReplaceExisting = false,
		        flExpireTime = GameRules:GetGameTime() + self:GetSpecialValueFor("projectile_fade_time"),
              
		    }
            local projectile2 = {
		        Target = target,
		        
		        Ability = ability,
				EffectName = "particles/merlin/merlin_tracking_orb.vpcf",
		        iMoveSpeed = self:GetSpecialValueFor("speed") + math.random(-300,0),
		        vSpawnOrigin = caster:GetAbsOrigin() + Vector(math.random(-200,200),math.random(-200,200),math.random(-100,100)),
		        bDodgeable = true,
				Source = caster,
				bReplaceExisting = false,
				bDeleteOnHit = false,
		        flExpireTime = GameRules:GetGameTime() +  self:GetSpecialValueFor("projectile_fade_time"),
                 
		    }
            local projectile3 = {
		        Target = target,
		
		        Ability = ability,
				EffectName = "particles/merlin/merlin_tracking_orb.vpcf",
		        iMoveSpeed = self:GetSpecialValueFor("speed") + math.random(-300,0),
		        vSpawnOrigin = caster:GetAbsOrigin()+ Vector(math.random(-200,200),math.random(-200,200),math.random(-100,100)),
		        bDodgeable = true,
				Source = caster,  
				bDeleteOnHit = false,
				bReplaceExisting = false,
		        flExpireTime = GameRules:GetGameTime() +  self:GetSpecialValueFor("projectile_fade_time"),
		       
		    }
         
               

      
        
		    self.proj1 = ProjectileManager:CreateTrackingProjectile(projectile1)
            self.proj2 =  ProjectileManager:CreateTrackingProjectile(projectile2)
            self.proj3 = ProjectileManager:CreateTrackingProjectile(projectile3)
           
		    
		end
	end)   
  
 
end
--[[
function merlin_orbs:OnProjectileThink_ExtraData(location, table)
    if(self.start_location - location):Length2D() > self:GetSpecialValueFor("search_radius") then
        ProjectileManager:DestroyTrackingProjectile( self.proj1)
        ProjectileManager:DestroyTrackingProjectile( self.proj2)
        ProjectileManager:DestroyTrackingProjectile( self.proj3)
    end
end
--]]
function merlin_orbs:OnProjectileHit_ExtraData(target, location, table)
	if target == nil then return end

	--if IsSpellBlocked(target) then return end
		target:EmitSound("merlin_orbs_explosion")
		local caster = self:GetCaster()
		local damage = self:GetSpecialValueFor("damage")
   	 	local radius = self:GetSpecialValueFor("radius")

		local explosionFx = ParticleManager:CreateParticle("particles/merlin/orb_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
   		ParticleManager:SetParticleControl(explosionFx, 0, location)
 

   		 local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
  	 		  for k,v in pairs(targets) do            
      	 	  DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
      	 	  v:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})   
     	   	  v:AddNewModifier(caster, self, "modifier_merlin_orb_silence", {Duration = self:GetSpecialValueFor("silence_duration")})      
   	 	      end 
 
 
end

modifier_merlin_orb_silence = class({})

function modifier_merlin_orb_silence:CheckState()
    local state =   { 
    				[MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end
 
function modifier_merlin_orb_silence:IsHidden() return false end
function modifier_merlin_orb_silence:RemoveOnDeath() return true end

modifier_merlin_self_pause = class({})


function modifier_merlin_self_pause:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_merlin_self_pause:GetModifierDisableTurning() 
	return 1
end
 


function modifier_merlin_self_pause:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_MUTED] = true,
		
                    }
    return state
end
 
function modifier_merlin_self_pause:IsHidden() return true end
function modifier_merlin_self_pause:RemoveOnDeath() return true end
