ozy_piramid_beam = class({})

IsNotNull = function(hScript)
    local sType = type(hScript)
    if sType ~= "nil" then
        if sType == "table" 
            and type(hScript.IsNull) == "function" then
            return not hScript:IsNull()
        end
        return true
    end
    return false
end


function ozy_piramid_beam:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ozy_piramid_beam:OnSpellStart()
	local piramid = self:GetCaster()
	local ozy  = piramid.Ozy
	local point = self:GetCursorPosition()
	local aoe = self:GetAOERadius()
	local delay = self:GetSpecialValueFor("delay")

	local damage = self:GetSpecialValueFor("damage")
	local damage_duration = self:GetSpecialValueFor("duration")
	local damage_ticks = damage_duration*10
	local damage_per_tick = damage/damage_ticks

	local ParticleOrigin = piramid:GetAttachmentOrigin(2)  

	self:CreateDelayEffects(piramid, delay, damage_duration, ParticleOrigin)
	Timers:CreateTimer(delay, function()
		if piramid:IsAlive() then
			self:CreateBeamEnd(piramid, ozy, damage_per_tick, damage_ticks, point, damage_duration, aoe, ParticleOrigin)
		end
	end)
end

function ozy_piramid_beam:CreateDelayEffects(piramid, delay, damage_duration, origin)
	local enemy = PickRandomEnemy(piramid)
    if enemy then
        piramid:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = delay })
    end

	local particle = ParticleManager:CreateParticle("particles/ozy/piramid/ozy_piramid_beam_precast.vpcf", PATTACH_OVERHEAD_FOLLOW, piramid)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, Vector(delay + damage_duration, delay - 0.5, damage_duration))
	ParticleManager:SetParticleShouldCheckFoW(particle, false)
	Timers:CreateTimer(delay + damage_duration, function()
		ParticleManager:DestroyParticle(particle, true)
		ParticleManager:ReleaseParticleIndex(particle)
		
	end)



end


function ozy_piramid_beam:CreateBeamEnd(piramid, ozy, damage_per_tick, damage_ticks, location, duration, aoe, ParticleOrigin)
	local particleBeam = ParticleManager:CreateParticle("particles/ozy/piramid/piramid_laser_beam_1.vpcf", PATTACH_WORLDORIGIN, piramid)
	ParticleManager:SetParticleControl(particleBeam, 1, ParticleOrigin)
	ParticleManager:SetParticleControl(particleBeam, 2, location)
	ParticleManager:SetParticleShouldCheckFoW(particleBeam, false)
	local particle = ParticleManager:CreateParticle("particles/ozy/piramid/piramid_laser_dmg.vpcf", PATTACH_WORLDORIGIN, piramid)
	ParticleManager:SetParticleControl(particle, 0, location)
	ParticleManager:SetParticleControl(particle, 1, Vector(aoe,0,0))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration, 0, 0))
	ParticleManager:SetParticleShouldCheckFoW(particle, false)
	Timers:CreateTimer(duration, function()
		if IsNotNull(particle) then
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			
			particle = nil
		end

		if IsNotNull(particleBeam) then
			ParticleManager:DestroyParticle(particleBeam, false)
			ParticleManager:ReleaseParticleIndex(particleBeam)
			
			particleBeam = nil
		end
	
	end)

	local damageTicksCounter = 0
	Timers:CreateTimer(0, function()
		if not piramid:IsAlive() then 
			if IsNotNull(particle) then
				ParticleManager:DestroyParticle(particle, false)
				ParticleManager:ReleaseParticleIndex(particle)
				particle = nil
			end
			if IsNotNull(particleBeam) then
				ParticleManager:DestroyParticle(particleBeam, false)
				ParticleManager:ReleaseParticleIndex(particleBeam)
			
			particleBeam = nil
		end
			return 
		end
		if damageTicksCounter < damage_ticks then
			damageTicksCounter = damageTicksCounter + 1
			local targets = FindUnitsInRadius(ozy:GetTeam(), location, nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for i = 1, #targets do
				DoDamage(ozy, targets[i], damage_per_tick, self:GetAbilityDamageType(), 0, self, false)
			end
			return duration / damage_ticks
		else
			return
		end
	
	
	end)



end