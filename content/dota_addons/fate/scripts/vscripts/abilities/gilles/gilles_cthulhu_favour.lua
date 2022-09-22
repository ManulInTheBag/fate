gilles_cthulhu_favour = class({})
modifier_cthulhu_favour_thinker = class({})

LinkLuaModifier("modifier_cthulhu_favour_thinker", "abilities/gilles/gilles_cthulhu_favour", LUA_MODIFIER_MOTION_NONE)

function gilles_cthulhu_favour:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_cthulhu_favour:GetCastRange()
	if self:GetCaster():HasModifier("modifier_sunken_city_attribute") then
		return self:GetSpecialValueFor("range") + 200
	end
	return self:GetSpecialValueFor("range")
end

function gilles_cthulhu_favour:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_cthulhu_favour:IsHiddenAbilityCastable()
	return true
end

function gilles_cthulhu_favour:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetLocation = self:GetCursorPosition()
	local tModifierArgs = { AOE = self:GetAOERadius(),
			  				Duration = self:GetSpecialValueFor("duration") }
	
	EmitSoundOnLocationWithCaster(vTargetLocation, "Gilles_Cthulhu_Cast", hCaster)

	local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/cthulhu_favour_cast.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
 	ParticleManager:SetParticleControl(particleIndex, 0, vTargetLocation) 

 	if self:GetCaster():HasModifier("modifier_sunken_city_attribute") then
	 	EmitSoundOnLocationWithCaster(hCaster:GetAbsOrigin(), "Gilles_Cthulhu_Root", self:GetCaster())
	 	local tEnemies = FindUnitsInRadius(self:GetCaster():GetTeam(), vTargetLocation, nil, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
		for _,v in pairs(tEnemies) do
			if not v:IsMagicImmune() then
				giveUnitDataDrivenModifier(self:GetCaster(), v, "rooted", 4)
				giveUnitDataDrivenModifier(self:GetCaster(), v, "locked", 4)
			end
		end
	 end

	Timers:CreateTimer(1.0, function()
		local thinker = CreateModifierThinker(hCaster, self, "modifier_cthulhu_favour_thinker", tModifierArgs, vTargetLocation, hCaster:GetTeamNumber(), false)
		ParticleManager:DestroyParticle(particleIndex, false)
		ParticleManager:ReleaseParticleIndex(particleIndex)
		
		return
	end)
	
end

if IsServer() then 
	function modifier_cthulhu_favour_thinker:OnCreated(args)
		self.ParticleIndex = ParticleManager:CreateParticle("particles/custom/gilles/cthulhu_favour_circle.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	 	ParticleManager:SetParticleControl(self.ParticleIndex, 0, self:GetParent():GetAbsOrigin()) 
	 	ParticleManager:SetParticleControl(self.ParticleIndex, 1, Vector(args.AOE, args.AOE, args.AOE))
	 	ParticleManager:SetParticleControl(self.ParticleIndex, 2, Vector(args.AOE, 0, 0))
	 	ParticleManager:SetParticleControl(self.ParticleIndex, 16, Vector(args.AOE, 0, 0))
	 	self.pepega = 0.2

	 	self:StartIntervalThink(0.2)
	end

	function modifier_cthulhu_favour_thinker:OnIntervalThink()
		self.pepega = self.pepega + 0.2
		if self.pepega >= 3 then
			self.pepega = 0
			local fAOE = self:GetAbility():GetAOERadius()
			local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/cthulhu_favour_splash.vpcf", PATTACH_CUSTOMORIGIN, nil)
		 	ParticleManager:SetParticleControl(particleIndex, 0, self:GetParent():GetAbsOrigin())
		 	ParticleManager:SetParticleControl(particleIndex, 1, Vector(fAOE * 0.2, 0, 0))
			ParticleManager:SetParticleControl(particleIndex, 2, Vector(fAOE * 0.4, 0, 0))
			ParticleManager:SetParticleControl(particleIndex, 3, Vector(fAOE * 0.6, 0, 0))
			ParticleManager:SetParticleControl(particleIndex, 4, Vector(fAOE * 0.8, 0, 0))
			ParticleManager:SetParticleControl(particleIndex, 5, Vector(fAOE, 0, 0)) 

			if self:GetCaster():HasModifier("modifier_sunken_city_attribute") then
		 		local tEnemies = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetParent():GetAbsOrigin(), nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			
				for _,v in pairs(tEnemies) do
					if not v:IsMagicImmune() then
						DoDamage(self:GetCaster(), v, 400, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
						v:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", { Duration = 1.5})
					end
				end
		 	end

			Timers:CreateTimer( 1.5, function()
				ParticleManager:DestroyParticle( particleIndex, true )
				ParticleManager:ReleaseParticleIndex( particleIndex )
				return nil
			end)
		end
		local spawn_loc = RandomPointInCircle(self:GetParent():GetAbsOrigin(), self:GetAbility():GetAOERadius() - 75)
		local targets = FindUnitsInRadius(self:GetCaster():GetTeam(), spawn_loc, nil, 150, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
		for _,v in pairs(targets) do			
			v:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", { Duration = 0.01 })
			DoDamage(self:GetCaster(), v, self:GetAbility():GetSpecialValueFor("spawn_damage"), DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
		end

		EmitSoundOnLocationWithCaster(spawn_loc, "Gilles_Cthulhu_Explode", self:GetCaster())

		local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/cthulhu_favour_splash.vpcf", PATTACH_CUSTOMORIGIN, nil)
	 	ParticleManager:SetParticleControl(particleIndex, 3, spawn_loc) 

		Timers:CreateTimer( 1.5, function()
			ParticleManager:DestroyParticle( particleIndex, true )
			ParticleManager:ReleaseParticleIndex( particleIndex )
			return nil
		end)

		local tentacle = CreateUnitByName("gilles_cthulhu_tentacle", spawn_loc, true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
		local tentacle_damage = self:GetAbility():GetSpecialValueFor("spawn_damage")-- + (self:GetCaster():HasModifier("modifier_sunken_city_attribute") and self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) or 0)
		tentacle:SetControllableByPlayer(self:GetCaster():GetPlayerID(), true)
		tentacle:SetOwner(self:GetCaster())
		tentacle:SetBaseDamageMax(tentacle_damage) 
		tentacle:SetBaseDamageMin(tentacle_damage) 
		tentacle:AddNewModifier(self:GetCaster(), nil, "modifier_kill", {duration = self:GetRemainingTime() })		
	end

	function modifier_cthulhu_favour_thinker:OnDestroy()
		local fAOE = self:GetAbility():GetAOERadius()
		local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/cthulhu_favour_splash.vpcf", PATTACH_CUSTOMORIGIN, nil)
	 	ParticleManager:SetParticleControl(particleIndex, 0, self:GetParent():GetAbsOrigin())
	 	ParticleManager:SetParticleControl(particleIndex, 1, Vector(fAOE * 0.2, 0, 0))
		ParticleManager:SetParticleControl(particleIndex, 2, Vector(fAOE * 0.4, 0, 0))
		ParticleManager:SetParticleControl(particleIndex, 3, Vector(fAOE * 0.6, 0, 0))
		ParticleManager:SetParticleControl(particleIndex, 4, Vector(fAOE * 0.8, 0, 0))
		ParticleManager:SetParticleControl(particleIndex, 5, Vector(fAOE, 0, 0)) 

		Timers:CreateTimer( 1.5, function()
			ParticleManager:DestroyParticle( particleIndex, true )
			ParticleManager:ReleaseParticleIndex( particleIndex )
			return nil
		end)

		ParticleManager:DestroyParticle(self.ParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(self.ParticleIndex)
	end
end