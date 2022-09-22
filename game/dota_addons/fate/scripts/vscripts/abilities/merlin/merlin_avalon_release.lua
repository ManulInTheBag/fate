LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
merlin_avalon_release = class({})
 

function merlin_avalon_release:OnSpellStart()
    local caster = self:GetCaster()
	local ability = self
	local point = self:GetCursorPosition()
	local dist = self:GetSpecialValueFor("range")
	local radius = self:GetSpecialValueFor("att_search_radius")
	local attack_range =  self:GetSpecialValueFor("att_attack_range")
	local damage = self:GetSpecialValueFor("att_damage")
	local flag_found_unit = true
	caster:FindAbilityByName("merlin_charisma"):AttStack() 
	 caster:RemoveModifierByName("modifier_merlin_avalon")
 
	 if (point - caster:GetAbsOrigin()):Length2D() > dist then
		point = caster:GetAbsOrigin() + (((point - caster:GetAbsOrigin()):Normalized()) * dist)
	end

 
	
	local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		flag_found_unit = false
	end
 

	if( not flag_found_unit and caster.IndependentManifestationAcquired) then
		local target = targets[1] 
		local target_pos = target:GetAbsOrigin()
		local point = target_pos + RandomVector(170)
		FindClearSpaceForUnit( caster, point, true )
		local vector = ( target_pos-caster:GetAbsOrigin()):Normalized()
		vector.z = 0
		caster:SetForwardVector(vector )
		self.flowers_fx = ParticleManager:CreateParticle("particles/merlin/avalon_flower_petals.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	
 
		 local targets = FindUnitsInLine(  caster:GetTeamNumber(),
                                       		 caster:GetAbsOrigin(),
                                      	 	 caster:GetAbsOrigin()+attack_range*caster:GetForwardVector(),
                                       		 nil,
                                       		 100,
                                      		 DOTA_UNIT_TARGET_TEAM_ENEMY,
                                       		 DOTA_UNIT_TARGET_ALL,
                                     		 DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
                                    	    )
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_RAZE_1, rate=1.5})
		caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.40}) 
		Timers:CreateTimer(0.2, function() 
			self.pierce_fx = ParticleManager:CreateParticle("particles/merlin/merlin_avalon_release_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(self.pierce_fx, 1,  caster:GetAbsOrigin() + Vector(0,0,150)) 
			ParticleManager:SetParticleControl(self.pierce_fx, 2,  target_pos+ Vector(0,0,150))
			caster:EmitSound("merlin_staff")
		end)

		
		Timers:CreateTimer(0.3, function() 
			for k,v in pairs(targets) do            
				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("duration"))    
				
				 end 

		end)

								
	else
		FindClearSpaceForUnit( caster, point, true )
	    caster:EmitSound("merlin_illusion")
		self.flowers_fx = ParticleManager:CreateParticle("particles/merlin/merlin_avalon_flowers_end.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(self.flowers_fx, 0, point   ) 
	end

end
 