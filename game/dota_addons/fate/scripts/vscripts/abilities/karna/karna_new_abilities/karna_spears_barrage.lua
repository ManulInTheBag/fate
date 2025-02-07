karna_spears_barrage = class({})

 

function karna_spears_barrage:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function karna_spears_barrage:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_new_karna_spears_voice")

	return true 
end

function karna_spears_barrage:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()

	caster:StopSound("karna_new_karna_spears_voice")

	return true 
end
function karna_spears_barrage:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetAOERadius() 
	local damage = self:GetSpecialValueFor("damage")  
	if caster.IndraAttribute then
		damage = damage + (caster.IndraAttribute and 0.375 * caster:GetIntellect() or 0)
	end
	EmitSoundOnLocationWithCaster(targetPoint, "emiya_big_swords_spawn", caster)
	local forwardVec = ( targetPoint - caster:GetAbsOrigin() ):Normalized()
	local duration = 0
	self.spears = {}
	self.vectors = {}
	self.vectors_point = {}
	self.counter = 1
	local delay = 0.2
	local scale_vector_1 = 0.35
	local spawn_delay = 0.05
	local count = 8
	self.counter2 = 1
	--[[
	local fx_jopa  = ParticleManager:CreateParticle("particles/karna/karna_spears_spawn_area.vpcf", PATTACH_CUSTOMORIGIN , nil )
	ParticleManager:SetParticleControl(fx_jopa, 0, targetPoint + Vector(0,0,700) )
	ParticleManager:ReleaseParticleIndex(fx_jopa)
	]]
	local fx_jopa_2  = ParticleManager:CreateParticle("particles/karna/karna_spears_radiusvpcf.vpcf", PATTACH_CUSTOMORIGIN , nil )
	ParticleManager:SetParticleControl(fx_jopa_2, 0, targetPoint )
	ParticleManager:SetParticleControl(fx_jopa_2, 1, Vector(radius,0,0) )
	ParticleManager:ReleaseParticleIndex(fx_jopa_2)
	Timers:CreateTimer(function()
		if caster:IsAlive() then
				if self.counter >= (count+1) then
					Timers:CreateTimer(delay * 0.3, function()
						if self.counter2 >= (count+1) then	 
							return  
						else

							ParticleManager:SetParticleControl( self.spears[self.counter2], 1, Vector(self.vectors[self.counter2][1],self.vectors[self.counter2][2],self.vectors[self.counter2][3]) *2)
							--Timers:CreateTimer(delay* 0.25, function()

								ParticleManager:DestroyParticle( self.spears[self.counter2], false )
								ParticleManager:ReleaseParticleIndex( self.spears[self.counter2] )
								local vector_point = Vector(self.vectors_point[self.counter2][1],self.vectors_point[self.counter2][2],self.vectors_point[self.counter2][3]) * scale_vector_1
								local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint  , nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
								for k,v in pairs(targets) do
									DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
									giveUnitDataDrivenModifier(caster, v, "rooted", self:GetSpecialValueFor("duration"))
									giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("duration"))
								end
								EmitSoundOnLocationWithCaster(targetPoint, "karna_new_fire_thunder", caster)
								local explosionFxIndex = ParticleManager:CreateParticle( "particles/karna/karna_barrage_spear_explosion_1.vpcf", PATTACH_CUSTOMORIGIN, caster )
								ParticleManager:SetParticleControl( explosionFxIndex, 0, targetPoint+ vector_point )
								ParticleManager:SetParticleShouldCheckFoW(explosionFxIndex, false)
								local impactFxIndex = ParticleManager:CreateParticle( "particles/karna/karna_barrage_spear_explosion_2.vpcf", PATTACH_CUSTOMORIGIN, caster )
								ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint+ vector_point )
								ParticleManager:SetParticleShouldCheckFoW(impactFxIndex, false)
								
								-- Destroy Particle
								Timers:CreateTimer( 0.5, function()
									ParticleManager:DestroyParticle( explosionFxIndex, false )
									ParticleManager:DestroyParticle( impactFxIndex, false )
									ParticleManager:ReleaseParticleIndex( explosionFxIndex )
									ParticleManager:ReleaseParticleIndex( impactFxIndex )
								end)
							--end)
							self.counter2 = self.counter2 + 1
							return spawn_delay
						end
					end)
					return		
				end

				duration = duration + spawn_delay
				local swordVector = Vector(RandomFloat(-radius, radius), RandomFloat(-radius, radius), 0)
				local height = RandomFloat(700, 700)
				local speed = height * 2	
				local spawn_location = ( targetPoint + swordVector*0.9 )-- - ( distance * forwardVec )
				spawn_location = spawn_location + Vector( 0, 0, height )
				local target_location = targetPoint + swordVector * scale_vector_1
				local newForwardVec = ( target_location - spawn_location ):Normalized()
				table.insert(self.vectors_point, self.counter, {swordVector.x, swordVector.y,swordVector.z})
				local swordFxIndex = ParticleManager:CreateParticle( "particles/karna/karna_barrage_spear.vpcf", PATTACH_CUSTOMORIGIN, caster )
				ParticleManager:SetParticleControl( swordFxIndex, 0, spawn_location )
				ParticleManager:SetParticleControl( swordFxIndex, 1, newForwardVec *1 )
				ParticleManager:SetParticleShouldCheckFoW(swordFxIndex, false)
				newForwardVec = newForwardVec * speed
				table.insert(self.vectors, self.counter, {newForwardVec.x, newForwardVec.y,newForwardVec.z})
				table.insert(self.spears, self.counter, swordFxIndex)
				self.counter = self.counter  + 1

				return spawn_delay
			

		end 
	
	end)



	 


end