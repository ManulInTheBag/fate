karna_brahmastra = class({})

LinkLuaModifier("modifier_brahmastra_stun", "abilities/karna/modifiers/modifier_brahmastra_stun", LUA_MODIFIER_MOTION_NONE)

--[[function karna_brahmastra:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end]]

function karna_brahmastra:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

 

function karna_brahmastra:OnChannelFinish(bInterrupted)
	local aoe = self:GetSpecialValueFor("beam_aoe")
	local range = self:GetSpecialValueFor("range")	
	self.damage = self:GetSpecialValueFor("damage")
	local caster = self:GetCaster()
	local burn_damage = self:GetSpecialValueFor("burn_dmg_per_second")
	
 
	if(bInterrupted == true) then
		self.interupted = true
	
		self.Laser = ParticleManager:CreateParticle("particles/custom/karna/brahmastra_laser/brahmastra_laser.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlEnt(self.Laser, 1, caster, PATTACH_POINT_FOLLOW, "attach_head", caster:GetOrigin(), true)
		ParticleManager:SetParticleControl(self.Laser, 9, caster:GetOrigin())
	
	
	else
		self.interupted = false
		range = range *(1+self:GetSpecialValueFor("range_increase_percent")/100)
		self.damage = self.damage *(1+self:GetSpecialValueFor("damage_increase_percent")/100)
		self.Laser = ParticleManager:CreateParticle("particles/karna/brahmastra_laser/brahmastra_laser_powered.vpcf", PATTACH_CUSTOMORIGIN, nil)
		self.Burn = ParticleManager:CreateParticle("particles/karna/brahmastra_laser/ground_burn.vpcf", PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(self.Burn, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(self.Burn, 1, caster:GetOrigin())
	 
		ParticleManager:SetParticleControlEnt(self.Laser, 1, caster, PATTACH_POINT_FOLLOW, "attach_head", caster:GetOrigin(), true)
		ParticleManager:SetParticleControl(self.Laser, 9, caster:GetOrigin())
		local burnstartpoint = caster:GetOrigin()
		local burnendpoint = caster:GetAbsOrigin()+ caster:GetForwardVector()*range 
		local counter = 0
		Timers:CreateTimer(0.3, function() 
			counter = counter +1
			if(counter > 15) then
				ParticleManager:DestroyParticle(self.Burn, true)
				ParticleManager:ReleaseParticleIndex(self.Burn)
				return 
			end
			local targets = FindUnitsInLine(  caster:GetTeamNumber(),
											 burnstartpoint,
											 burnendpoint,
                                       		 nil,
                                       		 120,
                                      		 DOTA_UNIT_TARGET_TEAM_ENEMY,
                                       		 DOTA_UNIT_TARGET_ALL,
                                     		 DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
                                    	    )
											
			for k,v in pairs(targets) do       
				DoDamage(caster, v,burn_damage/10 , DAMAGE_TYPE_MAGICAL, 0, self, false)
			end								
			return 0.1
		end)
		
	end
	local projectileTable = {
		Ability = self,
		EffectName = "",
		iMoveSpeed = 2000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = range,
		Source = self:GetCaster(),
		fStartRadius = aoe,
		fEndRadius = aoe,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 3,
		bDeleteOnHit = false,
		vVelocity =   (self:GetCursorPosition()-caster:GetAbsOrigin()):Normalized() * 3000,
	}
	local projectile = ProjectileManager:CreateLinearProjectile(projectileTable)
	caster:EmitSound("karna_brahmastra_laser")
end

function karna_brahmastra:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_brahmastra_" .. math.random(1,4))

	return true
end

function karna_brahmastra:OnSpellStart()
	
end

function karna_brahmastra:OnProjectileThink(vLocation)
	
	vLocation = vLocation + Vector(0, 0, 32)
 
	ParticleManager:SetParticleControlEnt(self.Laser, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetOrigin(), true)
	ParticleManager:SetParticleControl(self.Laser, 9, vLocation)
	if(self.interupted == false) then
		ParticleManager:SetParticleControl(self.Burn, 1, vLocation)
	end
end

function karna_brahmastra:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	local caster = self:GetCaster()

	if hTarget == nil then
		ParticleManager:DestroyParticle(self.Laser, true)
		ParticleManager:ReleaseParticleIndex(self.Laser)
		
		return 
	else
		DoDamage(caster, hTarget, self.damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		hTarget:AddNewModifier(caster, hTarget, "modifier_stunned", { Duration = 0.01 })
	end
end