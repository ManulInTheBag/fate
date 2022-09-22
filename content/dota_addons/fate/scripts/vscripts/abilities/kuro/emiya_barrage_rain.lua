emiya_barrage_rain = class({})

function emiya_barrage_rain:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_projection_attribute") then
		return 100
	else
		return 0
	end
end

function emiya_barrage_rain:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_projection_attribute") then
		return 2
	else
		return 5
	end
end

function emiya_barrage_rain:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function emiya_barrage_rain:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetAOERadius()
	local damage = self:GetSpecialValueFor("damage")
	local forwardVec = ( targetPoint - caster:GetAbsOrigin() ):Normalized()
	local duration = 0

	Timers:CreateTimer(function()
		if caster:IsAlive() then
			if duration >= 4 then return
			else
				duration = duration + 0.055
				local swordVector = Vector(RandomFloat(-radius, radius), RandomFloat(-radius, radius), 0)
			
				-- Create sword particles
				-- Main variables
				local delay = 0.5				-- Delay before damage
				local speed = 3000				-- Movespeed of the sword
				
				-- Side variables
				local distance = delay * speed
				local height = distance * math.tan( 30 / 180 * math.pi )
				local spawn_location = ( targetPoint + swordVector ) - ( distance * forwardVec )
				spawn_location = spawn_location + Vector( 0, 0, height )
				local target_location = targetPoint + swordVector
				local newForwardVec = ( target_location - spawn_location ):Normalized()
				target_location = target_location + 100 * newForwardVec
				
				local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_model.vpcf", PATTACH_CUSTOMORIGIN, caster )
				ParticleManager:SetParticleControl( swordFxIndex, 0, spawn_location )
				ParticleManager:SetParticleControl( swordFxIndex, 1, newForwardVec * speed )
				
				-- Delay
				Timers:CreateTimer(delay, function()
					-- Destroy particles
					ParticleManager:DestroyParticle( swordFxIndex, false )
					ParticleManager:ReleaseParticleIndex( swordFxIndex )
					
					-- Delay damage
					local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint + swordVector, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
					for k,v in pairs(targets) do
						if v:HasModifier("modifier_sword_barrage_confine") then
							DoDamage(caster, v, damage * 1.25, DAMAGE_TYPE_MAGICAL, 0, self, false)
						else
							DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
						end
					end
					
					-- Particles on impact
					local explosionFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( explosionFxIndex, 0, targetPoint + swordVector )
					
					local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint + swordVector )
					ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(300, 300, 300))
					
					-- Destroy Particle
					Timers:CreateTimer( 0.5, function()
						ParticleManager:DestroyParticle( explosionFxIndex, false )
						ParticleManager:DestroyParticle( impactFxIndex, false )
						ParticleManager:ReleaseParticleIndex( explosionFxIndex )
						ParticleManager:ReleaseParticleIndex( impactFxIndex )
					end)
					
					return nil
				end)

				return 0.055
			end
		end 
	end)

	--caster:EmitSound("Archer.UBWAmbient")

	if math.random(1,2) == 1 then
		caster:EmitSound("Archer.Bladeoff")
	else
		caster:EmitSound("Archer.Yuke")
	end
end