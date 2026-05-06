ozy_boat_sunstrike = class({})


function ozy_boat_sunstrike:GetAnimeVectorTargetingRange()
    return 1900
end
function ozy_boat_sunstrike:GetAnimeVectorTargetingStartRadius()
	return 350
end
function ozy_boat_sunstrike:GetAnimeVectorTargetingEndRadius()
	return 350
end
function ozy_boat_sunstrike:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function ozy_boat_sunstrike:GetAnimeVectorTargetingColor()
    return Vector(255, 255, 0)
end
function ozy_boat_sunstrike:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local delay = self:GetSpecialValueFor("delay")
	local delay_between_strikes = self:GetSpecialValueFor("delay_between_strikes")
	local baseDamage = self:GetSpecialValueFor("base_damage") +self:GetCaster().ozy:GetLevel() * self:GetSpecialValueFor("damage_per_level")
	local debuff_duration = self:GetSpecialValueFor("stun_duration")
	local direction = self:GetAnimeVectorTargetingMainDirection()
	local targetPointOld = targetPoint
	if (targetPoint-caster:GetAbsOrigin()):Length2D() > 1300 then
		targetPoint = caster:GetAbsOrigin() + (targetPoint-caster:GetAbsOrigin()):Normalized() * 1300
		--direction = -(targetPoint - targetPointOld):Normalized()+ direction 
	end
	
	direction.z = 0
	direction = direction:Normalized()
	local vectorRange = self:GetAnimeVectorTargetingRange()
	local maxCount = 3
	local count = 0
	local distanceBetweenStrikes = vectorRange/maxCount
	Timers:CreateTimer(0, function()
		if count >= maxCount then return end
		if caster:IsAlive() ~= true then return end
		self:ShootLightPillar(caster.ozy, caster, delay, baseDamage, debuff_duration, targetPoint + direction * count *distanceBetweenStrikes, radius)
		count = count + 1
		return delay_between_strikes
	
	
	end)

	


end


function ozy_boat_sunstrike:ShootLightPillar(ozymandias,boat, delay, damage, debuff_duration, point, radius)
	local markFx = ParticleManager:CreateParticle("particles/ozy/ozy_light_pillar_runes.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( markFx, 0, point)
	ParticleManager:SetParticleShouldCheckFoW(markFx, false)
	EmitSoundOnLocationWithCaster(point, "Hero_Chen.PenitenceImpact", boat)	






	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle(markFx, true)
		ParticleManager:ReleaseParticleIndex(markFx)

		local targets = FindUnitsInRadius(ozymandias:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		EmitSoundOnLocationWithCaster(point, "ozy_light_pillar", boat)	
		for k,v in pairs(targets) do
			if not v:IsMagicImmune() then
				if not v.IsHitByBoatSunstrike then				
					DoDamage(ozymandias, v, damage, self:GetAbilityDamageType(), 0, self, false)
					giveUnitDataDrivenModifier(ozymandias, v, "stunned", debuff_duration)
					v.IsHitByBoatSunstrike = true
					Timers:CreateTimer(1.5, function()
						v.IsHitByBoatSunstrike = false
					
					
					end)
				end
			end


	    end
	    EmitSoundOnLocationWithCaster(point, "Hero_Chen.TestOfFaith.Target", boat)		
		local explosionFx = ParticleManager:CreateParticle("particles/ozy/ozy_light_pillar_endcap.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl( explosionFx, 0, point)
		ParticleManager:SetParticleControl( explosionFx, 1, Vector(350, 0, 0))
		ParticleManager:SetParticleShouldCheckFoW(explosionFx, false)
		ParticleManager:ReleaseParticleIndex(explosionFx)
	end)


end


